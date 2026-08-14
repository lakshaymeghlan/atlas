# Canopy backend — edge functions

Supabase Edge Functions (Deno). Two are live so far:

| Function        | Does                                                             | Auth/keys        |
|-----------------| -----------------------------------------------------------------|------------------|
| `parse-cv`      | CV (PDF/DOCX/link) → **raw extracted text**                     | none             |
| `import-github` | GitHub username → public profile + repos (app's `GitHubData`)   | `GITHUB_TOKEN`\* |

\* optional — raises the rate limit and enables the real `contributionsLastYear` (GraphQL); it's `0` without a token. 

> **AI structuring is deliberately not wired yet.** `parse-cv` returns text; turning that
> text into a structured `CVParseResult`  is the next step (add the model call).
> **LinkedIn:** there's no API that returns experience/connections for indie devs. The
> working path is exporting your LinkedIn profile as PDF and running it through `parse-cv`.

## Prerequisites (not installed in this repo's shell)

Install one of:
- **Supabase CLI** — `brew install supabase/tap/supabase` (recommended; matches deploy target)
- or **Deno** — `brew install deno` (functions are plain Deno; `Deno.serve` runs directly)

## Run locally

```bash
# from repo root
supabase functions serve parse-cv     --no-verify-jwt   # http://localhost:54321/functions/v1/parse-cv
supabase functions serve import-github --no-verify-jwt
# GitHub token (optional): put GITHUB_TOKEN=... in supabase/.env, add --env-file supabase/.env
```

## Test

```bash
# GitHub import
curl -s localhost:54321/functions/v1/import-github \
  -H 'content-type: application/json' \
  -d '{"username":"octocat"}' | jq

# CV from a link
curl -s localhost:54321/functions/v1/parse-cv \
  -H 'content-type: application/json' \
  -d '{"kind":"link","url":"https://example.com/resume"}' | jq

# CV from a file (base64 a local PDF)
B64=$(base64 -i ~/Downloads/resume.pdf)
curl -s localhost:54321/functions/v1/parse-cv \
  -H 'content-type: application/json' \
  -d "{\"kind\":\"file\",\"filename\":\"resume.pdf\",\"base64\":\"$B64\"}" | jq '.source, .pages, .chars'
```

## Deploy

```bash
supabase link --project-ref <your-ref>
supabase secrets set GITHUB_TOKEN=<token>        # optional
supabase functions deploy parse-cv
supabase functions deploy import-github
```

## Contracts

**parse-cv** → `{ source, chars, pages?, text }` · `422 {error:"no_text"}` for scanned images.
**import-github** → `{ username, name, avatarUrl, repoCount, followers, contributionsLastYear, projects:[{name,description,language,stars,forks,pinned}] }`.
