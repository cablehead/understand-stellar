# build.nu - render the page to a static index.html for GitHub Pages.
#
# The page is deterministic from stellar.config.json (no per-request state),
# so http-nu is only a generator here: this renders the handler once and the
# result is plain static HTML + CSS + JS. Assets already live in assets/.
#
# Run: http-nu eval build.nu

let handler = (source serve.nu)
let html = (do $handler { method: "GET", path: "/", headers: {} } | get __html)
$html | save -f index.html
# tell Pages not to run Jekyll over the output
"" | save -f .nojekyll
print $"built index.html \(($html | str length) bytes\) - serves with assets/stellar.css + assets/page.css"
