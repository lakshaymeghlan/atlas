# Canopy backend — edge functions

Supabase Edge Functions (Deno). Two are live:

| Function        | Does                                                                        | Auth/keys              |
|-----------------|-----------------------------------------------------------------------------|------------------------|
| `parse-cv`      | CV / LinkedIn PDF (PDF, DOCX, link) → **structured `CVParseResult`**        | none\*                 |
| `import-github` | GitHub username → profile, repos, and languages-as-skills                   | `GITHUB_TOKEN`†        |

\* Structuring is deterministic — see [Two structuring paths](#two-structuring-paths). Set
`ANTHROPIC_API_KEY` to use the model path instead.
† Optional — raises the rate limit and enables the real `contributionsLastYear` (GraphQL); it's `0` without a token.

## Two structuring paths

`parse-cv` turns extracted text into the app's shape one of two ways, and reports which
in the `method` field:

| `method`  | How                                       | Cost    | When |
|-----------|-------------------------------------------|---------|------|
| `"rules"` | [`rules.ts`](parse-cv/rules.ts) — sections, dates, entry boundaries | free | default |
| `"model"` | [`structure.ts`](parse-cv/structure.ts) — Claude + structured outputs | per CV | when `ANTHROPIC_API_KEY` is set |

The rules parser handles the common shapes: a header block then
EXPERIENCE / EDUCATION / SKILLS / LANGUAGES (and their synonyms — `WORK HISTORY`,
`ACADEMIC BACKGROUND`, `TECHNICAL SKILLS`), date ranges in the document's own
vocabulary, and `Present` → `end_date: null`.

It is brittle by nature — a CV is a free-form document — so it never claims certainty.
Confidence is banded against the app's 0.6 review threshold: a clean entry lands at
**0.70**, one missing its dates at **0.55**, one salvaged from an ambiguous line at
**0.40**. Anything under 0.6 gets a blue dot and sorts to the top of Confirm Profile, so
the weakest parses are exactly what the user is asked to check. A field it can't read is
`null`, never a guess.

If the model path is enabled and errors, the rules parse is returned instead and `note`
explains what happened — a failed model call degrades, it doesn't 502.

## LinkedIn import

**There is no LinkedIn API that returns experience or connections** — their OIDC scopes
give name, email, and picture only, and scraping breaks and violates their terms. So the
import is the path that actually works: the user does **Profile → Resources → Save to
PDF** on LinkedIn and sends that PDF to `parse-cv`.

That export needs its own handling, and gets it. Its layout is inverted from a normal CV:

- the sidebar (Contact / Top Skills / Languages) linearises **above** the name, so the
  first name-shaped line in the document is a skill — the parser takes the last one
  before the Summary/Experience heading instead
- each role lists the **company above the title**, so parsing it as a normal CV swaps
  every role and company
- durations (`January 2022 - Present (2 years 4 months)`) and `Page 1 of 3` footers have
  to be stripped

Detection is on `linkedin.com/in/` or a Contact + Top Skills pair; the tests cover the
swap, the sidebar, and the footers.

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

Boots both functions on local ports and exercises every path against real generated
files: PDF, DOCX, link (HTML + PDF), a LinkedIn-style export, image-only PDF → 422, all
rejection paths, CORS preflight, and the live GitHub API. 40 assertions.

Unit tests for the parser itself (pure, no network):

```sh
deno test supabase/functions/parse-cv/rules_test.ts
```

The model path is asserted only when `ANTHROPIC_API_KEY` is set — skipped otherwise,
never silently passed.

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
(not PDF/DOCX), `400` (bad body/url/kind). Text that extracted fine but isn't
CV-shaped comes back `200` with `structured: false` and the raw `text`.

On the `model` path this is `claude-opus-5` with structured outputs, so the response is
schema-valid by construction. On the `rules` path the same shape is built directly. Either
way `confidence` drives the app's review UI — no defensive reshaping needed on the client.

**`import-github`** → `{ username, name, avatarUrl, repoCount, followers,
contributionsLastYear, projects: [{name, description, language, stars, forks, pinned}],
skills: [{name, confidence, repos}] }`. Matches the app's `GitHubData`; top 3 by stars
come back `pinned: true`.

`skills` is the languages they actually ship in, ready to merge onto the profile as
`source: .github` — confidence is the language's share of their own repos (forks
excluded), so a language in most repos lands high and a one-off lands under 0.6 for the
user to confirm. Adding it to the app means one new field on `GitHubData`.

## The app talks to these

`Config.backend` in the app points at them. It defaults to `.localDev`, which is
`http://localhost:8791` / `:8792` — the simulator reaches your Mac over localhost, so
start the two functions above and the app parses CVs and imports GitHub for real with
nothing deployed. (`NSAllowsLocalNetworking` in project.yml permits the http.)

Deployed instead:

```swift
static let backend: Backend? = .supabase(ref: "<your-ref>", anonKey: "<anon-key>")
```

Set `backend` to `nil` to go back to the canned `MockCVParser`.

`AtlasTests/BackendClientTests.swift` exercises the app's own networking against these
functions — real PDFs in, `CVParseResult` out, plus a live `octocat` import. Those tests
*skip* when the functions aren't running, so `⌘U` stays green offline.
