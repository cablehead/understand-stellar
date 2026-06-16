// understand-stellar diagnostic / screenshot helper.
//
// Usage:
//   node tools/check.cjs <url> [screenshot-path] [theme]
//
// Verifies the on-demand motion model: nothing animates at rest, each
// item's play button triggers its animation, and clicking the item body
// copies its token (shown via the toast). Optionally writes a screenshot.

const { chromium } = require("/root/xs/docs/node_modules/playwright");

const url = process.argv[2] || "http://localhost:3030/";
const shot = process.argv[3] || null;
const theme = process.argv[4] || "light";

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: { width: 1200, height: 1300 },
  });
  const errors = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.addInitScript((t) => localStorage.setItem("theme", t), theme);
  await page.goto(url, { waitUntil: "networkidle" });

  // 1. At rest: a transform tile should NOT be animating.
  const restStatic = await page.evaluate(async () => {
    const box = document.querySelector(".tf-rotate");
    if (!box) return null;
    const a = getComputedStyle(box).transform;
    await new Promise((r) => setTimeout(r, 350));
    return {
      animating: getComputedStyle(box).animationName !== "none",
      moved: a !== getComputedStyle(box).transform,
    };
  });

  // 2. Press a transform tile's play button -> it animates, then rests.
  const tfPlay = await page.evaluate(async () => {
    const item = [...document.querySelectorAll(".tf-item")].find((it) => {
      const b = it.querySelector(".tf-box");
      const v = b && getComputedStyle(b).getPropertyValue("--tf-to").trim();
      return v && !["1", "0", "0deg", "0rem"].includes(v);
    });
    if (!item) return null;
    const box = item.querySelector(".tf-box");
    const before = getComputedStyle(box).transform;
    item.querySelector(".play-btn").click();
    await new Promise((r) => setTimeout(r, 250));
    const playingClass = box.classList.contains("playing");
    const moved = before !== getComputedStyle(box).transform;
    return { playingClass, moved };
  });

  // 3. Press a duration play button -> bar pulses (width varies), then clears.
  const durPlay = await page.evaluate(async () => {
    const row = document.querySelectorAll(".dur-row")[4];
    if (!row) return null;
    const fill = row.querySelector(".dur-fill");
    const before = getComputedStyle(fill).width;
    row.querySelector(".play-btn").click();
    const samples = [];
    for (let i = 0; i < 12; i++) {
      await new Promise((r) => setTimeout(r, 60));
      samples.push(parseFloat(getComputedStyle(fill).width));
    }
    const max = Math.max(...samples);
    const min = Math.min(...samples);
    await new Promise((r) => setTimeout(r, 2200));
    const after = parseFloat(getComputedStyle(fill).width);
    return {
      before,
      pulsed: max - min > 10,
      peak: Math.round(max),
      clearedAfter: after < 3,
    };
  });

  // 3b. Press an easing card's play button -> the dot starts crossing.
  const easePlay = await page.evaluate(async () => {
    const card = document.querySelector(".motion-card");
    if (!card) return null;
    const dot = card.querySelector(".ease-dot");
    const restAnims = dot.getAnimations().length;
    card.querySelector(".play-btn").click();
    await new Promise((r) => setTimeout(r, 60));
    return { restAnims, playingAnims: dot.getAnimations().length };
  });

  // 4. Clicking the item body (not the button) copies -> toast shows it.
  const copy = await page.evaluate(async () => {
    const stage = document.querySelector(".tf-item .tf-stage");
    stage.click();
    await new Promise((r) => setTimeout(r, 60));
    const toast = document.getElementById("toast");
    return {
      toast: toast ? toast.textContent : "",
      shown: toast && toast.classList.contains("show"),
    };
  });

  if (shot) {
    await page.evaluate(() => {
      const h = [...document.querySelectorAll("h3")].find((e) =>
        /Duration/i.test(e.textContent)
      );
      if (h) h.scrollIntoView({ block: "start" });
    });
    await sleep(300);
    await page.screenshot({ path: shot });
  }

  console.log(
    JSON.stringify(
      {
        url,
        jsErrors: errors,
        restStatic,
        tfPlay,
        durPlay,
        easePlay,
        copy,
        shot,
      },
      null,
      1,
    ),
  );
  await browser.close();
})();
