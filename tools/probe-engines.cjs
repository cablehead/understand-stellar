// Load the ACTUAL regenerated 0.0.2 stellar.css and test whether
// var(--anim-duration-slow) resolves + drives a real transition, in all three
// engines Playwright ships (Chromium, Firefox, WebKit = Safari's engine).
const fs = require('fs');
const pw = require('/root/xs/docs/node_modules/playwright');
const cssPath = process.argv[2] || '/tmp/regen/css/stellar.css';
const css = fs.readFileSync(cssPath, 'utf8');

(async () => {
  for (const name of ['chromium', 'firefox', 'webkit']) {
    let line = { engine: name };
    try {
      const b = await pw[name].launch();
      const p = await b.newPage();
      await p.setContent('<!doctype html><html><head><style>' + css + '</style></head><body></body></html>');
      const r = await p.evaluate(async () => {
        const supportsDiv = CSS.supports('z-index', 'calc(100px / 50px)');
        const raw = getComputedStyle(document.documentElement).getPropertyValue('--anim-duration-slow').trim().slice(0, 70);
        const el = document.createElement('div');
        el.style.cssText = 'position:absolute;width:0;height:4px;transition-property:width;transition-timing-function:linear;transition-duration:var(--anim-duration-slow);';
        document.body.appendChild(el);
        const computed = getComputedStyle(el).transitionDuration;
        const measured = await new Promise((res) => {
          void el.offsetWidth; const t0 = performance.now(); let done = false;
          el.addEventListener('transitionend', () => { if (!done) { done = true; res(Math.round(performance.now() - t0)); } });
          requestAnimationFrame(() => { el.style.width = '200px'; });
          setTimeout(() => { if (!done) { done = true; res(0); } }, 1500);
        });
        return { supportsDiv, computed, measuredMs: measured };
      });
      line = { ...line, ...r };
      await b.close();
    } catch (e) { line.error = String(e).slice(0, 80); }
    console.log(JSON.stringify(line));
  }
})();
