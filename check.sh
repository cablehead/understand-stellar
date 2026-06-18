#!/usr/bin/env bash
# Formatting + render check for understand-stellar.
#
# Formatting is standardized with `deno fmt` (the same tool http-nu's check.sh
# uses), covering CSS, JS, HTML templates, and Markdown. Run `deno fmt` to
# auto-fix. Generated files (stellar.css, stellar.config.json) are excluded in
# deno.json.
set -euo pipefail

deno fmt --check
echo "deno fmt: ok"

# render smoke test: the handler produces a full page without erroring
http-nu eval -c '
  let handler = (source serve.nu)
  let html = (do $handler { method: "GET", path: "/", headers: {} } | get __html)
  if ($html | str length) < 5000 { error make { msg: "page render too small" } }
  print $"render: ok \(($html | str length) bytes\)"
'

# coverage gate: every stellar.css token must be click-to-copy in the UI
./tools/coverage.sh --gate
echo "coverage: 100%"
