/**
 * FlutterFire'ın enjekte ettiği satır içi betiklerin CSP hash'lerini toplar.
 *
 * firebase_* paketleri yükseltildiğinde bu hash'ler DEĞİŞİR ve web sürümü
 * beyaz ekran verir. Kullanım:
 *
 *   flutter build web --release
 *   firebase emulators:start --only hosting --project cemberapp-2a101 &
 *   cd test-rules && npm run csp-hash
 *
 * Çıktıdaki hash'leri firebase.json → Content-Security-Policy → script-src
 * içine yapıştır, sonra gizli pencerede test et.
 */
import puppeteer from 'puppeteer-core';

const URL = process.env.CEMBER_URL ?? 'http://127.0.0.1:5002/';
const CHROME =
  process.env.CHROME_PATH ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: 'new',
  args: ['--no-sandbox'],
});
const page = await browser.newPage();

const hashler = new Set();
page.on('console', (m) => {
  const eslesme = m.text().match(/'(sha256-[A-Za-z0-9+/=]+)'/g);
  if (eslesme) eslesme.forEach((h) => hashler.add(h.replaceAll("'", '')));
});

// Satır içi betikleri bilerek engelleyen bir politika enjekte et ki
// tarayıcı her biri için beklenen hash'i konsola yazsın.
await page.setExtraHTTPHeaders({
  'Content-Security-Policy-Report-Only': "script-src 'self'",
});

await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
await new Promise((r) => setTimeout(r, 8000));
await browser.close();

if (hashler.size === 0) {
  console.log('Hash bulunamadı. Sunucu ayakta mı, sayfa yüklendi mi?');
  process.exit(1);
}

console.log(`${hashler.size} hash bulundu:\n`);
console.log([...hashler].map((h) => `'${h}'`).join(' '));
