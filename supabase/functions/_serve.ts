// Test-only shim: runs one function module on $PORT.
//
// The functions call `Deno.serve(handler)` with no options (Supabase supplies
// the port in production), so for local testing we intercept that one call
// rather than editing the deployable code. Not deployed — the leading `_`
// keeps the Supabase CLI from treating it as a function.
//
//   PORT=8791 deno run --allow-all _serve.ts ./parse-cv/index.ts

const port = Number(Deno.env.get("PORT") ?? 8000);
const original = Deno.serve;

// deno-lint-ignore no-explicit-any
(Deno as any).serve = (handler: any) => original({ port }, handler);

const target = Deno.args[0];
if (!target) {
  console.error("usage: PORT=<n> deno run --allow-all _serve.ts <function/index.ts>");
  Deno.exit(2);
}
await import(new URL(target, `file://${Deno.cwd()}/`).href);
