// Run after flutter build web. Requires Playwright + its WebKit runtime.
// PLAYWRIGHT_MODULE may point to an existing Playwright installation.
// No sign-in or Firestore writes are performed.
const { webkit } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../build/web');
const prefix = '/QuanLyCongViecApp/';
const types = {'.html':'text/html', '.js':'text/javascript', '.wasm':'application/wasm', '.json':'application/json'};
const server = http.createServer((req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  if (!pathname.startsWith(prefix)) { res.writeHead(404).end(); return; }
  const file = path.resolve(root, decodeURIComponent(pathname.slice(prefix.length)) || 'index.html');
  if (!file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
  fs.readFile(file, (error, data) => {
    if (error) { res.writeHead(404).end(); return; }
    res.writeHead(200, {'Content-Type': types[path.extname(file)] || 'application/octet-stream'});
    res.end(data);
  });
});
(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  let browser;
  try {
    browser = await webkit.launch({headless: true});
    for (const delay of [0, 10000]) {
      const context = await browser.newContext();
      const page = await context.newPage();
      const requests = [];
      page.on('request', request => {
        if (request.url().includes('/firebasejs/')) requests.push(request.url());
      });
      if (delay) {
        // Hold all Firebase module requests until after the UI wait budget.
        let releaseAt;
        await page.route('**/firebasejs/**', async route => {
          releaseAt ??= Date.now() + delay;
          await new Promise(resolve => setTimeout(resolve, Math.max(0, releaseAt - Date.now())));
          await route.continue();
        });
      }
      await page.goto(`http://127.0.0.1:${server.address().port}${prefix}`);
      await page.waitForSelector('flt-semantics-placeholder', {state: 'attached'});
      await page.locator('flt-semantics-placeholder').dispatchEvent('click');
      if (delay) {
        await page.getByText('Kết nối đang chậm hoặc bị chặn.', {exact: false}).waitFor();
      }
      await page.waitForFunction(() => window.firebase_core?.getApps().length === 1);
      await page.evaluate(() => window.firebase_auth.getAuth().authStateReady());
      if (await page.getByRole('button', {name: 'Thử lại', exact: true}).count()) {
        await page.getByRole('button', {name: 'Thử lại', exact: true}).click();
      }
      await page.getByRole('button', {name: 'Đăng nhập bằng Google', exact: true}).waitFor();
      await page.waitForFunction(() => !document.body.innerText.includes('Firebase vẫn đang khởi tạo'));
      const text = await page.locator('body').innerText();
      assert(!text.includes('Không thể khởi tạo Firebase'), text);
      assert(!text.includes('Firebase vẫn đang khởi tạo'), text);
      assert.equal(await page.evaluate(() => window.firebase_core.getApps().length), 1);
      assert(requests.length > 0);
      console.log(JSON.stringify({engine: 'WebKit', delayMs: delay, appCount: 1, sdkRequests: requests.length, result: 'PASS'}));
      await context.close();
    }
  } finally {
    await browser?.close();
    server.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
