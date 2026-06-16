#!/usr/bin/env bash
# Token coverage audit: what fraction of stellar.css tokens are click-to-copy
# in the rendered UI? Run with -v for the missing-by-family breakdown.
set -euo pipefail
cd "$(dirname "$0")/.."

http-nu eval build.nu >/dev/null

grep -oE 'data-copy="[^"]+"' index.html | sed 's/data-copy="//;s/"//' \
  | grep '^--' | grep -v '{' | sort -u >/tmp/cov_copyable.txt
grep -oE '\-\-[a-zA-Z0-9-]+:' assets/stellar.css | sed 's/:$//' | sort -u >/tmp/cov_stellar.txt

stellar=$(wc -l </tmp/cov_stellar.txt)
covered=$(comm -12 /tmp/cov_copyable.txt /tmp/cov_stellar.txt | wc -l)
missing=$(comm -23 /tmp/cov_stellar.txt /tmp/cov_copyable.txt | wc -l)
dead=$(comm -13 /tmp/cov_stellar.txt /tmp/cov_copyable.txt | wc -l)

echo "stellar tokens:    $stellar"
echo "covered:           $covered ($((covered * 100 / stellar))%)"
echo "missing:           $missing"
echo "dead copy targets: $dead"

if [ "${1:-}" = "-v" ]; then
  echo "--- missing by family ---"
  comm -23 /tmp/cov_stellar.txt /tmp/cov_copyable.txt \
    | sed -E 's/^(--[a-z]+(-[a-z]+)?).*/\1*/' | sort | uniq -c | sort -rn
  if [ "$dead" -gt 0 ]; then
    echo "--- dead copy targets (offered but not in stellar.css) ---"
    comm -13 /tmp/cov_stellar.txt /tmp/cov_copyable.txt
  fi
fi
