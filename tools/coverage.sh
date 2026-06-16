#!/usr/bin/env bash
# Token coverage audit: what fraction of stellar.css tokens are click-to-copy
# in the rendered UI? Run with -v for the missing-by-family breakdown, or
# --gate to exit non-zero unless coverage is 100% (no missing, no dead).
set -euo pipefail
cd "$(dirname "$0")/.."

gate=""
verbose=""
for a in "$@"; do
  case "$a" in
  --gate) gate=1 ;;
  -v) verbose=1 ;;
  esac
done

http-nu eval build.nu >/dev/null

grep -oE 'data-copy="[^"]+"' index.html | sed 's/data-copy="//;s/"//' \
  | grep '^--' | grep -v '{' | sort -u >/tmp/cov_copyable.txt
grep -oE '\-\-[a-zA-Z0-9-]+:' assets/stellar.css | sed 's/:$//' | sort -u >/tmp/cov_stellar.txt

stellar=$(wc -l </tmp/cov_stellar.txt)
covered=$(comm -12 /tmp/cov_copyable.txt /tmp/cov_stellar.txt | wc -l)
missing=$(comm -23 /tmp/cov_stellar.txt /tmp/cov_copyable.txt | wc -l)
dead=$(comm -13 /tmp/cov_stellar.txt /tmp/cov_copyable.txt | wc -l)

# Prose lint: concrete --token names written into the visible text (notes,
# ledes, chip labels) must be real tokens. Catches typos like a made-up
# --aspect-ratio-video that the data-copy contract above can't see. Scripts,
# styles and tags are stripped first; placeholder/family forms ending in "-"
# (e.g. --font-, from --font-{name} or --anim-duration-*) are skipped.
python3 - <<'PY' >/tmp/cov_prose_bad.txt
import re
html = open("index.html").read()
html = re.sub(r"<script.*?</script>", " ", html, flags=re.S)
html = re.sub(r"<style.*?</style>", " ", html, flags=re.S)
text = re.sub(r"<[^>]+>", " ", html)
text = text.replace("&gt;", ">").replace("&lt;", "<").replace("&amp;", "&")
cands = set(re.findall(r"--[a-z][a-z0-9-]*", text))
real = set(l.strip() for l in open("/tmp/cov_stellar.txt"))
for t in sorted(c for c in cands if not c.endswith("-") and c not in real):
    print(t)
PY
prose=$(grep -c . /tmp/cov_prose_bad.txt || true)

echo "stellar tokens:    $stellar"
echo "covered:           $covered ($((covered * 100 / stellar))%)"
echo "missing:           $missing"
echo "dead copy targets: $dead"
echo "unknown prose refs: $prose"

if [ -n "$verbose" ] || { [ -n "$gate" ] && [ "$missing" -gt 0 ]; }; then
  echo "--- missing by family ---"
  comm -23 /tmp/cov_stellar.txt /tmp/cov_copyable.txt \
    | sed -E 's/^(--[a-z]+(-[a-z]+)?).*/\1*/' | sort | uniq -c | sort -rn
fi
if [ -n "$verbose" ] || { [ -n "$gate" ] && [ "$dead" -gt 0 ]; }; then
  if [ "$dead" -gt 0 ]; then
    echo "--- dead copy targets (offered but not in stellar.css) ---"
    comm -13 /tmp/cov_stellar.txt /tmp/cov_copyable.txt
  fi
fi
if [ -n "$verbose" ] || { [ -n "$gate" ] && [ "$prose" -gt 0 ]; }; then
  if [ "$prose" -gt 0 ]; then
    echo "--- unknown token names in prose (not in stellar.css) ---"
    cat /tmp/cov_prose_bad.txt
  fi
fi

if [ -n "$gate" ] && { [ "$missing" -gt 0 ] || [ "$dead" -gt 0 ] || [ "$prose" -gt 0 ]; }; then
  echo "coverage gate: FAIL ($missing missing, $dead dead, $prose unknown prose; expected 0/0/0)" >&2
  exit 1
fi
