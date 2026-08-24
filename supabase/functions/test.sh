#!/usr/bin/env bash
# End-to-end check of both edge functions against a locally running Deno.
#
#   ./supabase/functions/test.sh
#
# Needs: deno. Uses the network for import-github (public API) and skips the
# CV-structuring assertions unless ANTHROPIC_API_KEY is set.

set -uo pipefail
cd "$(dirname "$0")"

# Load secrets if present (gitignored): ANTHROPIC_API_KEY, optional GITHUB_TOKEN.
if [ -f ../.env ]; then set -a; . ../.env; set +a; fi

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); printf '  \033[32mok\033[0m   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n     %s\n' "$1" "${2-}"; }
skip() { SKIP=$((SKIP+1)); printf '  \033[33mskip\033[0m %s — %s\n' "$1" "$2"; }

# assert <name> <expected-status> <actual-status> <jq-filter> <expected-json> <body>
assert() {
  local name=$1 want=$2 got=$3 filter=$4 wantval=$5 body=$6
  if [ "$got" != "$want" ]; then bad "$name" "status $got, want $want: $body"; return; fi
  if [ -n "$filter" ]; then
    local actual; actual=$(printf '%s' "$body" | jq -c "$filter" 2>/dev/null)
    if [ "$actual" != "$wantval" ]; then bad "$name" "$filter = $actual, want $wantval"; return; fi
  fi
  ok "$name"
}

# post <port> <json> → sets $STATUS and $BODY
post() {
  local port=$1 data=$2 out
  out=$(curl -s -m 180 -w '\n%{http_code}' "http://localhost:$port" \
        -H 'content-type: application/json' -d "$data")
  STATUS=${out##*$'\n'}; BODY=${out%$'\n'*}
}

TMP=$(mktemp -d); trap 'rm -rf "$TMP"; kill $(jobs -p) 2>/dev/null' EXIT

# ---------------------------------------------------------------- fixtures
CV_TEXT='Jordan Rivera
Berlin, Germany
Senior Product Designer

EXPERIENCE
Senior Product Designer, Riverbank. 2022 - Present
Led design for onboarding and activation surfaces.
Product Designer, Northwind Labs. 2019 - 2022
Shipped the mobile redesign and the design system.

EDUCATION
BA Communication Design, University of the Arts, 2014 - 2018

SKILLS
Figma, Design systems, Prototyping, SwiftUI, Accessibility

LANGUAGES
English (Native), German (Professional)'

printf '%s' "$CV_TEXT" > "$TMP/cv.txt"
# Real PDF and DOCX via macOS textutil / cupsfilter.
textutil -convert docx -output "$TMP/cv.docx" "$TMP/cv.txt" 2>/dev/null
textutil -convert html -output "$TMP/cv.html" "$TMP/cv.txt" 2>/dev/null
cupsfilter "$TMP/cv.txt" > "$TMP/cv.pdf" 2>/dev/null
# A PDF with no extractable text stands in for a scan.
printf '%%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 99 99]>>endobj\ntrailer<</Root 1 0 R>>\n' > "$TMP/scan.pdf"

b64() { base64 -i "$1" | tr -d '\n'; }
[ -s "$TMP/cv.pdf" ]  || { echo "could not build the PDF fixture"; exit 1; }
[ -s "$TMP/cv.docx" ] || { echo "could not build the DOCX fixture"; exit 1; }

# ------------------------------------------------------------------ serve
PORT=8791 deno run --allow-all --no-lock --quiet _serve.ts ./parse-cv/index.ts \
  > "$TMP/parse.log" 2>&1 &
PORT=8792 deno run --allow-all --no-lock --quiet _serve.ts ./import-github/index.ts \
  > "$TMP/github.log" 2>&1 &

printf 'waiting for both functions to boot'
for _ in $(seq 1 90); do
  a=$(curl -so /dev/null -w '%{http_code}' -m 2 -X OPTIONS http://localhost:8791 || true)
  b=$(curl -so /dev/null -w '%{http_code}' -m 2 -X OPTIONS http://localhost:8792 || true)
  [ "$a" = "200" ] && [ "$b" = "200" ] && break
  printf '.'; sleep 1
done
echo
if [ "${a-}" != "200" ] || [ "${b-}" != "200" ]; then
  echo "functions did not boot:"; tail -20 "$TMP"/parse.log "$TMP"/github.log; exit 1
fi

STRUCTURED=false
[ -n "${ANTHROPIC_API_KEY-}" ] && STRUCTURED=true

echo
echo "parse-cv — extraction"
post 8791 "$(jq -nc --arg b "$(b64 "$TMP/cv.pdf")" '{kind:"file",filename:"cv.pdf",base64:$b}')"
assert "PDF: extracts text"        200 "$STATUS" '.source' '"pdf"' "$BODY"
assert "PDF: reports page count"   200 "$STATUS" '.pages'  '1'     "$BODY"
PDF_BODY=$BODY

post 8791 "$(jq -nc --arg b "$(b64 "$TMP/cv.docx")" '{kind:"file",filename:"cv.docx",base64:$b}')"
assert "DOCX: extracts text" 200 "$STATUS" '.source' '"docx"' "$BODY"
DOCX_BODY=$BODY

post 8791 "$(jq -nc --arg b "$(b64 "$TMP/scan.pdf")" '{kind:"file",filename:"scan.pdf",base64:$b}')"
assert "image-only PDF → 422 no_text" 422 "$STATUS" '.error' '"no_text"' "$BODY"

python3 -m http.server 8799 --directory "$TMP" >/dev/null 2>&1 &
sleep 1
post 8791 '{"kind":"link","url":"http://localhost:8799/cv.html"}'
assert "link (HTML): strips markup" 200 "$STATUS" '.source' '"link-html"' "$BODY"
post 8791 '{"kind":"link","url":"http://localhost:8799/cv.pdf"}'
assert "link (PDF): extracts text"  200 "$STATUS" '.source' '"link-pdf"'  "$BODY"

echo
echo "parse-cv — rejections"
post 8791 '{"kind":"file","filename":"cv.pages","base64":"QUJD"}'
assert "unsupported file type → 415" 415 "$STATUS" '' '' "$BODY"
post 8791 '{"kind":"file","filename":"cv.pdf"}'
assert "missing base64 → 400"        400 "$STATUS" '.error' '"missing base64"' "$BODY"
post 8791 '{"kind":"link","url":"ftp://nope"}'
assert "non-http url → 400"          400 "$STATUS" '.error' '"invalid url"'    "$BODY"
post 8791 '{"kind":"wat"}'
assert "unknown kind → 400"          400 "$STATUS" '' '' "$BODY"
post 8791 'not json'
assert "malformed body → 400"        400 "$STATUS" '.error' '"invalid JSON body"' "$BODY"
GET_STATUS=$(curl -so /dev/null -w '%{http_code}' -m 10 http://localhost:8791)
assert "GET → 405"                   405 "$GET_STATUS" '' '' ''
CORS_HDR=$(curl -si -m 10 -X OPTIONS http://localhost:8791 | grep -ci 'access-control-allow-origin' || true)
[ "$CORS_HDR" -ge 1 ] && ok "OPTIONS preflight returns CORS headers" \
                      || bad "OPTIONS preflight returns CORS headers" "no ACAO header"

echo
echo "parse-cv — structuring (CVParseResult contract)"
if [ "$STRUCTURED" = true ]; then
  assert "PDF: structured:true"     200 200 '.structured' 'true' "$PDF_BODY"
  assert "PDF: full_name extracted" 200 200 '.full_name'   '"Jordan Rivera"' "$PDF_BODY"
  assert "PDF: 2 experiences"       200 200 '(.experiences|length)' '2' "$PDF_BODY"
  assert "PDF: current role has null end_date" 200 200 \
         '[.experiences[]|select(.end_date==null)]|length' '1' "$PDF_BODY"
  assert "PDF: education present"   200 200 '(.education|length)>0' 'true' "$PDF_BODY"
  assert "PDF: skills present"      200 200 '(.skills|length)>0'    'true' "$PDF_BODY"
  assert "PDF: languages present"   200 200 '(.languages|length)>0' 'true' "$PDF_BODY"
  assert "PDF: every experience has confidence 0-1" 200 200 \
         '[.experiences[]|select(.confidence>=0 and .confidence<=1)]|length == (.experiences|length)' \
         'true' "$PDF_BODY"
  assert "DOCX: structured too"     200 200 '.structured' 'true' "$DOCX_BODY"
else
  assert "no API key → structured:false, text returned" 200 200 \
         '[.structured, (.text|length>0)]' '[false,true]' "$PDF_BODY"
  skip "structured CVParseResult assertions" "ANTHROPIC_API_KEY not set"
fi

echo
echo "import-github"
post 8792 '{"username":"octocat"}'
assert "octocat: username"      200 "$STATUS" '.username' '"octocat"' "$BODY"
assert "octocat: repoCount int" 200 "$STATUS" '(.repoCount|type)' '"number"' "$BODY"
assert "octocat: projects[]"    200 "$STATUS" '(.projects|type)'  '"array"'  "$BODY"
assert "octocat: <=3 pinned"    200 "$STATUS" '[.projects[]|select(.pinned)]|length <= 3' 'true' "$BODY"
assert "octocat: project shape" 200 "$STATUS" \
  '.projects[0]|[has("name"),has("description"),has("language"),has("stars"),has("forks"),has("pinned")]' \
  '[true,true,true,true,true,true]' "$BODY"
post 8792 '{"username":"@octocat"}'
assert "strips a leading @"      200 "$STATUS" '.username' '"octocat"' "$BODY"
post 8792 '{"username":"this-user-should-not-exist-9f3a2b"}'
assert "unknown user → 404"      404 "$STATUS" '.error' '"user not found"' "$BODY"
post 8792 '{}'
assert "no username → 400"       400 "$STATUS" '.error' '"username required"' "$BODY"
GH_GET=$(curl -so /dev/null -w '%{http_code}' -m 10 http://localhost:8792)
assert "GET → 405"               405 "$GH_GET" '' '' ''

echo
printf '%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
