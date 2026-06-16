// Generate the Open Graph / social card (assets/og.png) for understand-stellar.
//
// Adapted from http-nu's examples/2048/test/shot-splash.mjs. It boots a
// throwaway http-nu instance serving serve.nu, then drives Playwright to
// frame the page as a 1200x630 card (the OG safe default, 1.91:1): the brand
// title on the left, the "Color" header and the first vivid token ramps on
// the right. The nav, theme toggle and the long intro paragraph are hidden
// for the capture so the ramps sit right under the title.
//
// Usage:
//   node tools/og.cjs                 # dark theme -> assets/og.png
//   node tools/og.cjs light           # light theme
//   node tools/og.cjs dark /tmp/x.png # explicit theme + output path
//
// Requires Playwright (shared with the repo's other tools) and http-nu on PATH.

const { chromium } = require("/root/xs/docs/node_modules/playwright");
const { spawn } = require("node:child_process");
const path = require("node:path");

const REPO_ROOT = path.resolve(__dirname, "..");
const SERVE_NU = path.join(REPO_ROOT, "serve.nu");

const theme = process.argv[2] || "dark";
const outPath = process.argv[3] || path.join(REPO_ROOT, "assets", "og.png");
const PORT = Number(process.env.PORT) || 4788;
const BASE = `http://127.0.0.1:${PORT}`;

// Hide chrome that would clutter the card, and the long intro paragraph so the
// ramps rise to just under the title.
const CLEAN = `
  .sidebar nav, .theme-toggle, .nav-toggle { visibility: hidden !important; }
  .section-head .lede { display: none !important; }
`;

const srv = spawn(
  "http-nu",
  ["--datastar", `127.0.0.1:${PORT}`, SERVE_NU],
  { cwd: REPO_ROOT, stdio: "ignore" },
);
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
  const ctx = await browser.newContext({
    viewport: { width: 1200, height: 630 },
    deviceScaleFactor: 2,
  });
  const page = await ctx.newPage();
  await page.addInitScript((t) => localStorage.setItem("theme", t), theme);
  await page.goto(`${BASE}/`, { waitUntil: "networkidle" });
  await page.addStyleTag({ content: CLEAN });
  // Frame from just above the "Color" header so the brand (sticky, left) and
  // the header line up at the top, with the first ramps filling the card.
  await page.evaluate(() => {
    const h = [...document.querySelectorAll("h2")].find((e) =>
      e.textContent.trim() === "Color"
    );
    if (h) h.scrollIntoView({ block: "start" });
    window.scrollBy(0, -28); // a little headroom above the header
  });
  await new Promise((r) => setTimeout(r, 400));
  await page.screenshot({ path: outPath });
  console.log(`saved ${theme} card: ${outPath}`);
  await browser.close();
  cleanup();
  process.exit(0);
})();
