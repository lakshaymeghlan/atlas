// Supabase Edge Function: parse-cv  (text-extraction stage)
//
// Takes a CV (PDF / DOCX / link) and returns its raw text. The AI step that
// turns this text into a structured profile (CVParseResult) is added later —
// this stage is just reliable extraction so the rest can be built and tested.
//
//   POST { kind: "file", filename, base64 }   — a picked CV file
//   POST { kind: "link", url }                 — a portfolio / profile URL
//   → 200 { source, chars, pages?, text }
//   → 422 { error: "no_text" }                  — nothing extractable (e.g. scanned image)
//   → 4xx/5xx { error }
//
// Run locally:  supabase functions serve parse-cv --no-verify-jwt
// Deploy:       supabase functions deploy parse-cv
//
// TODO(ai): add the structuring call (text → CVParseResult) once wired up.

import { extractText, getDocumentProxy } from "npm:unpdf@0.12.1";
import mammoth from "npm:mammoth@1.8.0";

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

async function pdfText(bytes: Uint8Array): Promise<{ text: string; pages: number }> {
  const pdf = await getDocumentProxy(bytes);
  const { text, totalPages } = await extractText(pdf, { mergePages: true });
  return { text: (text as string).trim(), pages: totalPages };
}

async function extract(payload: Record<string, unknown>): Promise<
  { source: string; text: string; pages?: number } | { error: string; status: number }
> {
  const kind = payload.kind;

  if (kind === "file") {
    const filename = String(payload.filename ?? "cv");
    const base64 = String(payload.base64 ?? "");
    if (!base64) return { error: "missing base64", status: 400 };
    const bytes = b64ToBytes(base64);
    if (bytes.byteLength > MAX_BYTES) return { error: "file too large", status: 413 };

    if (/\.pdf$/i.test(filename)) {
      const { text, pages } = await pdfText(bytes);
      if (text.length < 30) return { error: "no_text", status: 422 }; // likely a scanned image
      return { source: "pdf", text, pages };
    }
    if (/\.docx$/i.test(filename)) {
      const { value } = await mammoth.extractRawText({ buffer: bytes });
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

  return json({ ...result, chars: result.text.length }, 200);
});
