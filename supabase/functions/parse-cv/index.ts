// Supabase Edge Function: parse-cv
//
// Takes a CV (PDF / DOCX / link or LinkedIn PDF export), extracts its text, and
// structures it into the app's `CVParseResult` shape. The response body decodes
// directly as `CVParseResult` — extraction metadata rides alongside it under
// keys the app's decoder ignores.
//
// Structuring is deterministic (see rules.ts) — no API key, no per-CV cost. If
// ANTHROPIC_API_KEY is set, the model path (structure.ts) is used instead and
// handles layouts the rules miss; the rules parse remains the fallback when it
// errors. `method` says which one produced the response.
//
//   POST { kind: "file", filename, base64 }   — a picked CV / LinkedIn PDF export
//   POST { kind: "link", url }                 — a portfolio / profile URL
//   → 200 { full_name, headline, location, experiences, education, skills,
//           languages, source, chars, pages?, structured: true, method }
//   → 200 { source, chars, pages?, text, structured: false }  — text wasn't CV-shaped
//   → 422 { error: "no_text" }                  — nothing extractable (e.g. scanned image)
//   → 4xx/5xx { error }
//
// Run locally:  supabase functions serve parse-cv --no-verify-jwt
// Deploy:       supabase functions deploy parse-cv

import { extractText, getDocumentProxy } from "npm:unpdf@0.12.1";
import mammoth from "npm:mammoth@1.8.0";
import { Buffer } from "node:buffer";
import { isUsable, parseCV } from "./rules.ts";
import { structureCV } from "./structure.ts";

const MAX_BYTES = 20 * 1024 * 1024; // 20 MB

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...CORS },
  });
}

function b64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function stripHtml(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

/**
 * PDF → text, with the line breaks preserved.
 *
 * `extractText(..., {mergePages: true})` returns the whole document as a single
 * space-joined string, which throws away exactly the structure a CV carries in
 * its layout — headings, one role per line, dates beside them. So walk the text
 * layer instead and rebuild lines from the glyph geometry: group items by their
 * baseline (PDF y grows upward, so descending y is top-to-bottom), then order
 * each line left to right.
 *
 * ponytail: y-bucketing merges side-by-side columns into one line, so a
 * two-column CV still interleaves. Fix by splitting on large x-gaps if real
 * multi-column CVs turn out to matter.
 */
async function pdfText(bytes: Uint8Array): Promise<{ text: string; pages: number }> {
  const pdf = await getDocumentProxy(bytes);
  const out: string[] = [];

  for (let n = 1; n <= pdf.numPages; n++) {
    const content = await (await pdf.getPage(n)).getTextContent();
    const rows = new Map<number, { x: number; s: string }[]>();

    for (const item of content.items as { str?: string; transform?: number[] }[]) {
      if (!item.str?.trim() || !item.transform) continue;
      // Bucket the baseline so sub-pixel drift on one visual line stays together.
      const row = Math.round(item.transform[5] / 3);
      if (!rows.has(row)) rows.set(row, []);
      rows.get(row)!.push({ x: item.transform[4], s: item.str });
    }

    for (const row of [...rows.keys()].sort((a, b) => b - a)) {
      const line = rows.get(row)!
        .sort((a, b) => a.x - b.x)
        .map((i) => i.s)
        .join(" ")
        .replace(/\s{2,}/g, " ")
        .trim();
      if (line) out.push(line);
    }
  }

  const text = out.join("\n").trim();
  // Some PDFs carry a text layer the geometry walk can't read. Fall back to the
  // library's flat extraction so we still return the text we can see.
  if (text) return { text, pages: pdf.numPages };
  const flat = await extractText(pdf, { mergePages: true });
  return { text: String(flat.text).trim(), pages: flat.totalPages };
}

async function extract(payload: Record<string, unknown>): Promise<
  { source: string; text: string; pages?: number } | { error: string; status: number }
> {
  const kind = payload.kind;

  if (kind === "file") {
    const filename = String(payload.filename ?? "cv");
    const base64 = String(payload.base64 ?? "");
    if (!base64) return { error: "missing base64", status: 400 };
    // Reject on the encoded length before decoding — base64 carries 3 bytes per
    // 4 chars, so this bounds the allocation instead of doubling it first.
    if (base64.length / 4 * 3 > MAX_BYTES) return { error: "file too large", status: 413 };
    const bytes = b64ToBytes(base64);

    if (/\.pdf$/i.test(filename)) {
      const { text, pages } = await pdfText(bytes);
      if (text.length < 30) return { error: "no_text", status: 422 }; // likely a scanned image
      return { source: "pdf", text, pages };
    }
    if (/\.docx$/i.test(filename)) {
      // mammoth's documented input is a Node Buffer, not a bare Uint8Array.
      const { value } = await mammoth.extractRawText({ buffer: Buffer.from(bytes) });
      const text = (value ?? "").trim();
      if (text.length < 30) return { error: "no_text", status: 422 };
      return { source: "docx", text };
    }
    return { error: "unsupported file type (use PDF or DOCX)", status: 415 };
  }

  if (kind === "link") {
    const url = String(payload.url ?? "");
    if (!/^https?:\/\//i.test(url)) return { error: "invalid url", status: 400 };
    let res: Response;
    try {
      res = await fetch(url, { headers: { "user-agent": "CanopyBot/1.0" } });
    } catch {
      return { error: "could not fetch link", status: 400 };
    }
    if (!res.ok) return { error: `link returned ${res.status}`, status: 400 };
    // Refuse an oversized body on its advertised length, before reading it.
    const declared = Number(res.headers.get("content-length") ?? 0);
    if (declared > MAX_BYTES) return { error: "file too large", status: 413 };
    const ctype = res.headers.get("content-type") ?? "";
    if (ctype.includes("application/pdf")) {
      const buf = new Uint8Array(await res.arrayBuffer());
      if (buf.byteLength > MAX_BYTES) return { error: "file too large", status: 413 };
      const { text, pages } = await pdfText(buf);
      if (text.length < 30) return { error: "no_text", status: 422 };
      return { source: "link-pdf", text, pages };
    }
    const text = stripHtml(await res.text()).slice(0, 60_000);
    if (text.length < 40) return { error: "no_text", status: 422 };
    return { source: "link-html", text };
  }

  return { error: "kind must be 'file' or 'link'", status: 400 };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "POST only" }, 405);

  let payload: Record<string, unknown>;
  try {
    payload = await req.json();
  } catch {
    return json({ error: "invalid JSON body" }, 400);
  }

  let result;
  try {
    result = await extract(payload);
  } catch (e) {
    return json({ error: `extraction failed: ${e}` }, 500);
  }
  if ("error" in result) return json({ error: result.error }, result.status);

  const meta = { source: result.source, pages: result.pages, chars: result.text.length };

  // Rules first — deterministic, free, and testable. The model path is an
  // opt-in upgrade: it only runs when ANTHROPIC_API_KEY is set, and if it
  // fails we still have a parse to return rather than nothing.
  const parsed = parseCV(result.text);
  let profile: object = parsed;
  let method = "rules";
  let note: string | undefined;

  try {
    const structured = await structureCV(result.text);
    if (structured) {
      profile = structured;
      method = "model";
    }
  } catch (e) {
    note = `model structuring failed, fell back to rules: ${e instanceof Error ? e.message : e}`;
  }

  // Nothing recognisable in the text — the extraction worked but this document
  // isn't shaped like a CV. Hand back the text so the client can show something.
  if (method === "rules" && !isUsable(parsed)) {
    return json({ ...meta, text: result.text, structured: false, method }, 200);
  }

  // `text` is dropped: the profile supersedes it and would double the payload.
  return json({ ...profile, ...meta, structured: true, method, note }, 200);
});
