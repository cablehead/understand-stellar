# tools

Helper scripts for understand-stellar. They are not part of the page; they
build, audit, or capture it. All Playwright-based scripts share the repo's
existing Playwright install and need `http-nu` on `PATH`.

## og.cjs - generate the social card

Renders the Open Graph / Twitter card to `assets/og.png`. It boots a throwaway
`http-nu` instance serving `serve.nu`, then drives Playwright to frame the page
as a 1200x630 card (the OG safe default, 1.91:1): the brand title on the left,
the **Color** header and the first vivid token ramps on the right. The nav,
theme toggle, and the long intro paragraph are hidden for the capture so the
ramps sit right under the title.

```
node tools/og.cjs                 # dark theme  -> assets/og.png
node tools/og.cjs light           # light theme -> assets/og.png
node tools/og.cjs dark /tmp/x.png # explicit theme + output path
```

The output is 2400x1260 (1200x630 at `deviceScaleFactor: 2`) so it stays crisp
when platforms downscale. The card is referenced as an absolute URL from the
`og:image` / `twitter:image` meta tags in `serve.nu`, pointing at the GitHub
Pages copy under `assets/og.png`. Regenerate it whenever the Color section's
look changes, then commit the new PNG.

Override the throwaway server port with `PORT=4789 node tools/og.cjs` if 4788 is
busy.

## Other tools

- `coverage.sh` - audits how many `stellar.css` tokens are click-to-copy in the
  rendered page. `-v` for the missing-by-family breakdown, `--gate` to exit
  non-zero unless coverage is 100% (used by `check.sh`).
- `check.cjs` - cross-engine smoke test of the on-demand motion model and the
  copy-to-clipboard behaviour; optionally writes a screenshot.
- `probe-clamp.cjs` / `probe-engines.cjs` - probe how browsers resolve the fluid
  `clamp()` duration tokens (the v0.0.1 vs v0.0.2 Stellar behaviour).
- `migrate-config.py` - one-off migration of `stellar.config.json` from the v1
  schema to Stellar 0.0.2.
