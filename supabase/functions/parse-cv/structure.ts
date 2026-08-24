// CV text → structured profile, via Claude.
//
// The JSON schema below IS the app's `CVParseResult` contract (snake_case on the
// wire; the Swift decoder uses .convertFromSnakeCase). Structured outputs
// guarantee the response validates against it, so the app can decode the
// function's body directly — no reshaping in between.

import Anthropic from "@anthropic-ai/sdk";

/** Optional string field — the app models these as `String?` and wants null, never a guess. */
const nullableString = { anyOf: [{ type: "string" }, { type: "null" }] };

/** 0–1. Non-optional in the app (`Double`), so it is always required and never null. */
const confidence = {
  type: "number",
  description:
    "How certain you are this entry is correct, 0–1. Below 0.6 flags it for review in the app, so use it honestly: lower it for anything inferred, ambiguous, or partially legible rather than rounding up.",
};

function object(properties: Record<string, unknown>) {
  return {
    type: "object",
    properties,
    required: Object.keys(properties),
    additionalProperties: false,
  };
}

export const CV_SCHEMA = object({
  full_name: nullableString,
  headline: {
    anyOf: [{ type: "string" }, { type: "null" }],
    description: "One line on who they are professionally, as the CV puts it.",
  },
  location: nullableString,
  experiences: {
    type: "array",
    description: "Roles, most recent first.",
    items: object({
      role: { type: "string" },
      company: { type: "string" },
      start_date: nullableString,
      end_date: {
        anyOf: [{ type: "string" }, { type: "null" }],
        description: "null when this is their current role.",
      },
      description: nullableString,
      confidence,
    }),
  },
  education: {
    type: "array",
    items: object({
      institution: { type: "string" },
      degree: nullableString,
      field: nullableString,
      start_year: nullableString,
      end_year: nullableString,
      confidence,
    }),
  },
  skills: {
    type: "array",
    items: object({ name: { type: "string" }, confidence }),
  },
  languages: {
    type: "array",
    items: object({ name: { type: "string" }, level: nullableString }),
  },
});

const SYSTEM = `You turn the raw text of a CV into structured data for a job-matching app.

Extract only what the document says. Every field is either something you read in the text or null — never fill a gap with a plausible guess, and never invent a role, school, skill, or date. Text extracted from a PDF often arrives with columns interleaved and headings adrift; read it as a whole before deciding what belongs together, and lower confidence on anything you had to piece together.

Dates stay in the document's own vocabulary ("2021", "Mar 2019", "2019-03") rather than being normalised. A role with no end date is current: set end_date to null. Order experiences most recent first. Skills are the specific, nameable ones — tools, languages, methods, domains — not soft-skill filler; leave the list empty if the CV lists none.`;

/** A CV parsed into the app's shape, or null when no API key is configured. */
export async function structureCV(text: string): Promise<Record<string, unknown> | null> {
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return null;

  const client = new Anthropic({ apiKey });

  // @ts-ignore SDK typings for output_config / fallbacks lag the API.
  const message = await client.beta.messages.create({
    model: "claude-opus-5",
    max_tokens: 16000,
    // A policy decline is re-served by Anthropic's recommended fallback in the
    // same call, so one odd CV can't fail the request outright.
    betas: ["server-side-fallback-2026-07-01"],
    fallbacks: "default",
    output_config: {
      effort: "medium",
      format: { type: "json_schema", schema: CV_SCHEMA },
    },
    system: SYSTEM,
    messages: [{ role: "user", content: `<cv_text>\n${text}\n</cv_text>` }],
  });

  // Check the stop reason before touching content: a refusal returns 200 with
  // empty (or partial) content, and max_tokens means truncated JSON.
  if (message.stop_reason === "refusal") {
    throw new Error(`model declined to parse this CV (${message.stop_details?.category ?? "unknown"})`);
  }
  if (message.stop_reason === "max_tokens") {
    throw new Error("model output hit max_tokens; the structured profile is incomplete");
  }

  const block = message.content.find((b: { type: string }) => b.type === "text");
  if (!block) throw new Error("model returned no text block");

  // Structured outputs guarantee this parses and matches CV_SCHEMA.
  return JSON.parse((block as { text: string }).text);
}
