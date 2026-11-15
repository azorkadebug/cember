/**
 * Web yayını ÖNCESİ kontrol (denetim #5 Y1, O1, Y3). Deploy ETMEZ, yalnız bakar.
 *
 *   flutter build web --release
 *   cd test-rules && npm run yayin-oncesi
 *
 * Çıkış 0 değilse `firebase deploy --only hosting` YAPMA. İki şeye bakar:
 *
 * (a) CSP hash'leri: FlutterFire her Firebase servisi için satır içi bir
 *     `window.ff_trigger_...` betiği enjekte eder; metninde Firebase JS SDK
 *     sürümü geçtiği için firebase_* paketleri yükselince hash'i değişir ve
 *     firebase.json'daki CSP onu engeller → uygulama açılmaz. Betik build/web'i
 *     CSP'siz yerel bir sunucudan açar, enjekte edilen betik metinlerini
 *     yakalayıp sha256'larını CSP'deki listeyle karşılaştırır. İki kez açar:
 *     TrustedTypes'lı (Chrome, güncel Safari/Firefox) ve TrustedTypes'sız
 *     (eski Safari; FlutterFire bu dalda farklı girintili metin üretir).
 *
 * (b) Alt siteler: Hosting deploy'u tam yansımadır, build/web'de olmayan
 *     dosya canlıdan SİLİNİR. Canlıda 200 dönen alt sitelerin build/web'de
 *     karşılığı yoksa durur. (Ekim 2026'da bir deploy /milestones'u sildi.)
 *
 * Ortam: CHROME_PATH (varsayılan Google Chrome), CANLI_URL (varsayılan
 * https://cember.org). Chrome ve ağ gerekir (Firebase SDK gstatic'ten iner).
 */
import { createHash } from 'node:crypto';
import { createServer } from 'node:http';
import { existsSync, readFileSync, statSync } from 'node:fs';
import { extname, join, normalize, resolve } from 'node:path';
import puppeteer from 'puppeteer-core';

const KOK = resolve(import.meta.dirname, '..');
const WEB = join(KOK, 'build', 'web');
const CHROME =
  process.env.CHROME_PATH ??
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const CANLI = (process.env.CANLI_URL ?? 'https://cember.org').replace(/\/$/, '');

// Canlıda yaşayan, build/web'e flutter build dışında giren alt siteler.
// cakabey depodaki web/cakabey'den gelir; milestones depoda YOK, ayrı
// kaynaktan (~/milestones-coffee) kopyalanır — bkz. README "Web yayını".
const ALT_SITELER = ['milestones', 'cakabey'];

let hataVar = false;
const hata = (m) => {
  hataVar = true;
  console.log(`  HATA: ${m}`);
};

if (!existsSync(join(WEB, 'index.html'))) {
  console.log('build/web/index.html yok. Önce: flutter build web --release');
  process.exit(2);
}

// ---------- (a) CSP hash'leri ----------
console.log('(a) FlutterFire satır içi betikleri ↔ firebase.json CSP');

const firebaseJson = JSON.parse(readFileSync(join(KOK, 'firebase.json'), 'utf8'));
const cspBaslik = firebaseJson.hosting.headers
  .flatMap((h) => h.headers)
  .find((h) => h.key === 'Content-Security-Policy');
const scriptSrc = cspBaslik.value
  .split(';')
  .map((s) => s.trim())
  .find((s) => s.startsWith('script-src '));
const izinli = new Set(scriptSrc.match(/sha256-[A-Za-z0-9+/=]+/g) ?? []);

// CSP'siz yerel sunucu: betikler çalışmalı ki FlutterFire sıradaki servisi
// de enjekte etsin (engellenirse ilk betikte durur, gerisini göremeyiz).
const TURLER = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css',
  '.png': 'image/png', '.svg': 'image/svg+xml', '.otf': 'font/otf',
  '.ttf': 'font/ttf', '.bin': 'application/octet-stream',
};
const sunucu = createServer((istek, yanit) => {
  let yol = normalize(decodeURIComponent(new URL(istek.url, 'http://x').pathname));
  let dosya = join(WEB, yol);
  if (!dosya.startsWith(WEB)) dosya = join(WEB, 'index.html');
  if (existsSync(dosya) && statSync(dosya).isDirectory()) dosya = join(dosya, 'index.html');
  if (!existsSync(dosya)) dosya = join(WEB, 'index.html');
  yanit.writeHead(200, { 'Content-Type': TURLER[extname(dosya)] ?? 'application/octet-stream' });
  yanit.end(readFileSync(dosya));
});
await new Promise((r) => sunucu.listen(0, '127.0.0.1', r));
const yerel = `http://127.0.0.1:${sunucu.address().port}/`;

const tarayici = await puppeteer.launch({
  executablePath: CHROME,
  headless: 'new',
  args: ['--no-sandbox', '--disable-dev-shm-usage'],
});

/** Sayfayı açar, src'siz eklenen <script>'lerin metnini toplar. */
async function satirIciBetikler(trustedTypesKapali) {
  const sayfa = await tarayici.newPage();
  await sayfa.evaluateOnNewDocument((ttKapali) => {
    if (ttKapali) {
      // Eski Safari/Firefox'u taklit et: FlutterFire `script.text` dalına düşer.
      Object.defineProperty(window, 'trustedTypes', { value: undefined, configurable: true });
    }
    window.__satirIci = [];
    const asil = Node.prototype.appendChild;
    Node.prototype.appendChild = function (dugum) {
      if (dugum instanceof HTMLScriptElement && !dugum.src) {
        window.__satirIci.push(dugum.text);
      }
      return asil.call(this, dugum);
    };
  }, trustedTypesKapali);
  await sayfa.goto(yerel, { waitUntil: 'networkidle2', timeout: 60000 });
  // Servisler sırayla yüklenir; sayı bir süre değişmeyince bitti say.
  let onceki = -1;
  let metinler = [];
  for (let i = 0; i < 30; i++) {
    await new Promise((r) => setTimeout(r, 1000));
    metinler = await sayfa.evaluate(() => window.__satirIci);
    if (metinler.length > 0 && metinler.length === onceki) break;
    onceki = metinler.length;
  }
  await sayfa.close();
  return metinler;
}

const sha = (metin) => 'sha256-' + createHash('sha256').update(metin, 'utf8').digest('base64');
const gerekli = new Set();
for (const [ad, ttKapali] of [['TrustedTypes açık', false], ['TrustedTypes kapalı', true]]) {
  const metinler = await satirIciBetikler(ttKapali);
  console.log(`  ${ad}: ${metinler.length} satır içi betik`);
  if (metinler.length === 0) {
    hata(`${ad}: hiç FlutterFire betiği yakalanamadı (ağ? Chrome yolu?) — doğrulanamadı.`);
  }
  for (const m of metinler) {
    const h = sha(m);
    gerekli.add(h);
    const servis = m.match(/ff_trigger_(\w+)/)?.[1] ?? '?';
    const surum = m.match(/firebasejs\/([\d.]+)\//)?.[1] ?? '?';
    if (izinli.has(h)) {
      console.log(`    tamam  ${servis} (SDK ${surum}) '${h}'`);
    } else {
      hata(`CSP'de YOK: ${servis} (SDK ${surum}) '${h}' → firebase.json script-src'ye ekle`);
    }
  }
}
await tarayici.close();
sunucu.close();

const fazla = [...izinli].filter((h) => !gerekli.has(h));
if (fazla.length) {
  console.log(`  bilgi: CSP'de bu derlemenin kullanmadığı ${fazla.length} hash var ` +
    '(önceki SDK sürümü için tutuluyor olabilir; firebase.json yorumuna bak).');
}

// ---------- (b) Alt siteler ----------
console.log(`\n(b) Canlıdaki alt siteler ↔ build/web (${CANLI})`);
for (const alt of ALT_SITELER) {
  let durum;
  try {
    const y = await fetch(`${CANLI}/${alt}/`, { redirect: 'manual' });
    durum = y.status;
    // `**` → index.html rewrite'ı yüzünden olmayan adres de 200 döner;
    // gelen sayfa Çember'in kendisiyse orada gerçek bir alt site yok.
    if (durum === 200 && (await y.text()).includes('flutter_bootstrap.js')) {
      durum = '200 (Çember index.html, alt site yok)';
    }
  } catch (e) {
    hata(`${alt}: canlıya ulaşılamadı (${e.message}) — doğrulanamadı.`);
    continue;
  }
  const yerelde = existsSync(join(WEB, alt, 'index.html'));
  if (durum === 200 && !yerelde) {
    hata(`/${alt}/ canlıda var (200) ama build/web/${alt}/ YOK → deploy onu SİLER.`);
  } else {
    console.log(`  tamam  /${alt}/ canlı=${durum} build/web=${yerelde ? 'var' : 'yok'}`);
  }
}

if (hataVar) {
  console.log('\nDURDUR: yukarıdaki HATA satırları düzelmeden deploy etme.');
  process.exit(1);
}
console.log('\nKontroller geçti. (Deploy bu betiğin işi değil.)');
