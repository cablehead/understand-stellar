// Generate the Open Graph / social cards for understand-stellar.
//
// Boots a throwaway http-nu instance serving serve.nu, then drives Playwright
// to frame each page as a 1200x630 card (the OG safe default, 1.91:1): the
// sticky brand on the left, a focus heading and the content under it on the
// right. Nav, theme toggle and the section lede are hidden for the capture.
//
// One card per page is declared in PAGES below, so "every page gets a card" is
// a single command. Add a route here and rerun; keep it in sync with the
// per-page `image` in each page's head-block meta in serve.nu.
//
// Usage:
//   node tools/og.cjs                              # all pages, dark theme
//   node tools/og.cjs light                        # all pages, light theme
//   node tools/og.cjs dark /notes assets/x.png "Pairing tokens"  # one page
//
// Requires Playwright (shared with the repo's other tools) and http-nu on PATH.

const { chromium } = require("/root/xs/docs/node_modules/playwright");
const { spawn } = require("node:child_process");
const path = require("node:path");

const REPO_ROOT = path.resolve(__dirname, "..");
const SERVE_NU = path.join(REPO_ROOT, "serve.nu");
const PORT = Number(process.env.PORT) || 4788;
const BASE = `http://127.0.0.1:${PORT}`;

const theme = process.argv[2] || "dark";
// Optional single-page override: theme route out focus
const single = process.argv[3]
  ? [{
    route: process.argv[3],
    out: process.argv[4] || "assets/og.png",
    focus: process.argv[5] || "Color",
  }]
  : null;

const PAGES = single || [
  { route: "/", out: "assets/og.png", focus: "Color" },
  {
    route: "/notes",
    out: "assets/og-notes.png",
    focus: "Built on a neutral-1 surface",
  },
];

// Hide chrome that would clutter the card so the focus content sits up top.
const CLEAN = `
  .sidebar nav, .theme-toggle, .nav-toggle, .source-link { visibility: hidden !important; }
  .section-head .lede { display: none !important; }
`;

const srv = spawn("http-nu", ["--datastar", `127.0.0.1:${PORT}`, SERVE_NU], {
  cwd: REPO_ROOT,
  stdio: "ignore",
});
const cleanup = () => {
  try {
    srv.kill("SIGTERM");
  } catch {}
};
process.on("exit", cleanup);

async function waitReady() {
  for (let i = 0; i < 50; i++) {
    try {
      if ((await fetch(`${BASE}/`)).ok) return;
    } catch {}
    await new Promise((r) => setTimeout(r, 100));
  }
  throw new Error("server didn't come up");
}

(async () => {
  await waitReady();
  const browser = await chromium.launch();
  for (const p of PAGES) {
    const outPath = path.isAbsolute(p.out)
      ? p.out
      : path.join(REPO_ROOT, p.out);
    const ctx = await browser.newContext({
      viewport: { width: 1200, height: 630 },
      deviceScaleFactor: 2,
    });
    const page = await ctx.newPage();
    await page.addInitScript((t) => localStorage.setItem("theme", t), theme);
    await page.goto(`${BASE}${p.route}`, { waitUntil: "networkidle" });
    await page.addStyleTag({ content: CLEAN });
    // Frame from just above the focus heading; the sticky brand stays on the
    // left and the content fills the rest of the card.
    await page.evaluate((focus) => {
      const h = [...document.querySelectorAll("h2, h3")].find((e) =>
        e.textContent.trim() === focus
      );
      if (h) h.scrollIntoView({ block: "start" });
      window.scrollBy(0, -28);
    }, p.focus);
    await new Promise((r) => setTimeout(r, 400));
    await page.screenshot({ path: outPath });
    console.log(`saved ${theme} card for ${p.route}: ${outPath}`);
    await ctx.close();
  }
  await browser.close();
  cleanup();
  process.exit(0);
})();
