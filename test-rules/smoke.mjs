/**
 * Çember web duman testi: uygulama CSP altında açılıyor mu, giriş ekranı
 * render oluyor mu, konsola hata düşüyor mu.
 *
 *   flutter build web --release
 *   firebase emulators:start --only hosting --project cemberapp-2a101 &
 *   cd test-rules && npm run smoke
 */
import puppeteer from 'puppeteer-core';

const URL = process.env.CEMBER_URL ?? 'http://127.0.0.1:5002/';
const CHROME =
  process.env.CHROME_PATH ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const CIKTI = process.env.CEMBER_SHOT_DIR ?? '.';

const browser = await puppeteer.launch({
  executablePath: CHROME,
  headless: 'new',
  args: ['--no-sandbox', '--disable-dev-shm-usage'],
});

const page = await browser.newPage();
await page.setViewport({ width: 430, height: 900, deviceScaleFactor: 2 });

const konsol = [];
const cspIhlalleri = [];
page.on('console', (m) => {
  const t = m.text();
  konsol.push(`[${m.type()}] ${t}`);
  if (/Content Security Policy|Refused to/i.test(t)) cspIhlalleri.push(t);
});
page.on('pageerror', (e) => konsol.push(`[pageerror] ${e.message}`));

await page.goto(URL, { waitUntil: 'networkidle2', timeout: 60000 });
await new Promise((r) => setTimeout(r, 6000));

const bekle = (ms) => new Promise((r) => setTimeout(r, ms));

// Tanıtım carousel'ini geç ("Atla" sağ üstte)
await page.mouse.click(386, 24);
await bekle(2500);
await page.screenshot({ path: `${CIKTI}/01-giris.png` });

// Kayıt sekmesine geç — şifre kuralı ipucu görünmeli
await page.mouse.click(306, 380);
await bekle(1500);
await page.screenshot({ path: `${CIKTI}/02-kayit.png` });

const canvasVar = await page.evaluate(
  () => !!document.querySelector('flutter-view, flt-glass-pane, canvas'),
);

console.log('--- CSP İHLALLERİ ---');
console.log(cspIhlalleri.length ? cspIhlalleri.join('\n') : '(yok)');
console.log('--- FLUTTER GÖRÜNÜMÜ ---');
console.log('canvas var mı:', canvasVar);
console.log('--- HATALAR ---');
const hatalar = konsol.filter((l) => l.startsWith('[error]') || l.startsWith('[pageerror]'));
console.log(hatalar.length ? hatalar.join('\n') : '(yok)');

await browser.close();
process.exit(cspIhlalleri.length || !canvasVar ? 1 : 0);
