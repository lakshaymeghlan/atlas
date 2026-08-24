# Canopy backend — edge functions

Supabase Edge Functions (Deno). Two are live:

| Function        | Does                                                              | Auth/keys           |
|-----------------|-------------------------------------------------------------------|---------------------|
| `parse-cv`      | CV (PDF/DOCX/link) → text → **structured `CVParseResult`**        | `ANTHROPIC_API_KEY`\* |
| `import-github` | GitHub username → public profile + repos (the app's `GitHubData`) | `GITHUB_TOKEN`†     |

\* Required for structuring. Without it `parse-cv` still extracts text and returns
`{source, chars, pages?, text, structured: false}` — the extraction stage works standalone.
† Optional — raises the rate limit and enables the real `contributionsLastYear` (GraphQL); it's `0` without a token.

> **LinkedIn:** there's no API that returns experience/connections for indie devs. The
> working path is exporting a LinkedIn profile as PDF and running it through `parse-cv`.

## Prerequisites

- **Deno** — `brew install deno` (the functions are plain Deno; `Deno.serve` runs directly), or
- **Supabase CLI** — `brew install supabase/tap/supabase` (matches the deploy target)

## Secrets

Put local secrets in `supabase/.env` (gitignored). `test.sh` loads it automatically:

```sh
ANTHROPIC_API_KEY=sk-ant-...
GITHUB_TOKEN=ghp_...        # optional
```

For deployment: `supabase secrets set ANTHROPIC_API_KEY=... GITHUB_TOKEN=...`

## Test

```sh
./supabase/functions/test.sh
```

Boots both functions on local ports and exercises every path: PDF, DOCX, link
(HTML + PDF), image-only PDF → 422, all rejection paths, CORS preflight, and the
live GitHub API. The structured-`CVParseResult` assertions run only when
`ANTHROPIC_API_KEY` is set (skipped otherwise, not silently passed).

## Run locally

```sh
supabase functions serve parse-cv      --no-verify-jwt --env-file supabase/.env
supabase functions serve import-github --no-verify-jwt --env-file supabase/.env
```

Or without the CLI, using the test shim:

```sh
cd supabase/functions
PORT=8791 deno run --allow-all _serve.ts ./parse-cv/index.ts
```

```bash
# CV from a file
B64=$(base64 -i ~/Downloads/resume.pdf | tr -d '\n')
curl -s localhost:8791 -H 'content-type: application/json' \
  -d "{\"kind\":\"file\",\"filename\":\"resume.pdf\",\"base64\":\"$B64\"}" | jq

# CV from a link
curl -s localhost:8791 -H 'content-type: application/json' \
  -d '{"kind":"link","url":"https://example.com/resume"}' | jq

# GitHub import
curl -s localhost:8792 -H 'content-type: application/json' \
  -d '{"username":"octocat"}' | jq
```

## Deploy

```sh
supabase link --project-ref <your-ref>
supabase secrets set ANTHROPIC_API_KEY=<key>
supabase secrets set GITHUB_TOKEN=<token>        # optional
supabase functions deploy parse-cv
supabase functions deploy import-github
```

## Contracts

**`parse-cv`** → `200` with the app's `CVParseResult` shape plus extraction metadata.
The iOS `CVParseResult` decoder (`.convertFromSnakeCase`) decodes this body as-is;
`source` / `chars` / `pages` / `structured` are ignored by it.

```json
{
  "full_name": "Jordan Rivera",
  "headline": "Senior Product Designer",
  "location": "Berlin, Germany",
  "experiences": [{ "role": "…", "company": "…", "start_date": "2022",
                    "end_date": null, "description": "…", "confidence": 0.95 }],
  "education":   [{ "institution": "…", "degree": "BA", "field": "…",
                    "start_year": "2014", "end_year": "2018", "confidence": 0.92 }],
  "skills":      [{ "name": "Figma", "confidence": 0.96 }],
  "languages":   [{ "name": "English", "level": "Native" }],
  "source": "pdf", "pages": 1, "chars": 1834, "structured": true
}
```

Errors: `422 {error:"no_text"}` (scanned image), `413` (over 20 MB), `415`
(not PDF/DOCX), `400` (bad body/url/kind), `502 {error:"structuring failed: …"}`
(extraction succeeded, the model step didn't — the app should treat this as retryable).

Extraction is `claude-opus-5` with structured outputs, so the response is schema-valid
by construction — no defensive reshaping needed on the client. `confidence` is the
model's own certainty per entry; the app blue-dots anything under 0.6.

**`import-github`** → `{ username, name, avatarUrl, repoCount, followers,
contributionsLastYear, projects: [{name, description, language, stars, forks, pinned}] }`.
Matches the app's `GitHubData`; top 3 by stars come back `pinned: true`.

## Not wired yet

The iOS app still calls `Core/Parsing/MockCVParser.swift` and `MockIntegrations.swift`.
Pointing it at these functions needs a deployed project URL + anon key in `Config.swift`
— that's the next step, not done here.
