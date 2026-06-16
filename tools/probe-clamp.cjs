// Does stellar 0.0.2's fixed duration formula actually resolve in the browser?
// 0.0.2 builds the progress factor as length/length division (-> unitless).
//
//   node tools/probe-clamp.cjs <url>

const { chromium } = require('/root/xs/docs/node_modules/playwright');
const url = process.argv[2] || 'http://localhost:3030/';

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1200, height: 900 } });
  await page.goto(url, { waitUntil: 'networkidle' });

  const out = await page.evaluate(() => {
    const test = (css, prop) => {
      const el = document.createElement('div');
      el.style.cssText = 'position:absolute;left:-9999px;width:200px;' + css;
      document.body.appendChild(el);
      const v = getComputedStyle(el)[prop];
      el.remove();
      return v;
    };
    return {
      // 0.0.2 progress factor: length / length -> number. expect ~0.786 at 1200px.
      v002_progress: test('opacity: clamp(0, calc((100vw - 320px) / (1440px - 320px)), 1);', 'opacity'),
      // 0.0.2 full slow token. expect ~0.343s.
      v002_slow_duration: test('transition-duration: calc(calc(0.28 + 0.08 * clamp(0, calc((100vw - 320px) / (1440px - 320px)), 1)) * 1s);', 'transitionDuration'),
      // 0.0.1 broken token for contrast. expect 0s.
      v001_slow_duration: test('transition-duration: calc(calc(0.28 + 0.08 * clamp(0, calc((100vw - 320px) * 0.000893), 1)) * 1s);', 'transitionDuration'),
    };
  });

  console.log(JSON.stringify(out, null, 1));
  await browser.close();
})();
