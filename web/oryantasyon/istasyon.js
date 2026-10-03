/* =====================================================================
   SORULAR — buradan düzenleyin.
   Her sorunun ilk seçeneği DOĞRU cevaptır; ekranda karıştırılarak gösterilir.
   "ceza": { h: hareket, n: sayı }  — hareketler: squat, ziplama, mekik, sinav, plank
   (plank için n = saniye, ekranda geri sayım çıkar).
   Havuzdan her grup için SORU_SAYISI kadar soru rastgele seçilir.
   Hep aynı ilk 4 soru sırayla gelsin isterseniz RASTGELE = false yapın.
   ===================================================================== */
var SORU_SAYISI = 4;
var RASTGELE = true;
var SES_EFEKTI = true;     // doğru/yanlış/bitiş sesleri ve geri sayım tıkı
var SORU_JINGLE = true;    // soru ekrana gelince kısa bir jingle çalsın

var HAREKETLER = {
  squat:   { ad: "SQUAT (çömelme)",      birim: "tekrar" },
  ziplama: { ad: "ZIPLAMA (jumping jack)", birim: "tekrar" },
  mekik:   { ad: "MEKİK",                birim: "tekrar" },
  sinav:   { ad: "ŞINAV",                birim: "tekrar" },
  plank:   { ad: "PLANK",                birim: "saniye" }
};

var ISTASYONLAR = [
  {
    ad: "1. İstasyon: Spor Bilgisi",
    sorular: [
      { s: "Bir futbol takımında sahada aynı anda kaç oyuncu bulunur?",
        c: ["11", "7", "9", "13"], ceza: { h: "squat", n: 10 } },
      { s: "Basketbolda top hangi organımızla oynanır?",
        c: ["El", "Ayak", "Baş", "Diz"], ceza: { h: "ziplama", n: 10 } },
      { s: "Voleybolda top karşı sahaya en fazla kaç vuruşta gönderilir?",
        c: ["3", "2", "5", "1"], ceza: { h: "mekik", n: 10 } },
      { s: "Olimpiyat bayrağındaki halkalar kaç tanedir?",
        c: ["5", "4", "6", "3"], ceza: { h: "sinav", n: 5 } },
      { s: "Aşağıdakilerden hangisi bir atletizm dalıdır?",
        c: ["Uzun atlama", "Satranç", "Bowling", "Dart"], ceza: { h: "plank", n: 15 } },
      { s: "Basketbolda her takımdan sahada aynı anda kaç oyuncu olur?",
        c: ["5", "6", "7", "4"], ceza: { h: "squat", n: 10 } }
    ],
    bitis: "Şimdi 2. istasyona geçin!"
  },
  {
    ad: "2. İstasyon: Sağlık ve Beden Eğitimi",
    sorular: [
      { s: "Spor yapmaya başlamadan önce ne yapmalıyız?",
        c: ["Isınma hareketleri", "Hemen koşmaya başlama", "Uyuma", "Bol yemek yeme"], ceza: { h: "squat", n: 10 } },
      { s: "Spor yaparken kalbimiz nasıl atar?",
        c: ["Daha hızlı", "Daha yavaş", "Aynı hızda", "Atmayı bırakır"], ceza: { h: "ziplama", n: 10 } },
      { s: "\"Fair play\" ne demektir?",
        c: ["Dürüst ve centilmence oyun", "Hızlı oyun", "Sert oyun", "Uzun oyun"], ceza: { h: "mekik", n: 10 } },
      { s: "Spor yaparken terleriz. Kaybettiğimiz sıvıyı en iyi ne karşılar?",
        c: ["Su", "Kola", "Çay", "Enerji içeceği"], ceza: { h: "sinav", n: 5 } },
      { s: "Spor bittikten sonra kasları rahatlatmak için ne yapılır?",
        c: ["Soğuma ve esneme", "Hemen yere oturma", "Daha hızlı koşma", "Ağır bir şey kaldırma"], ceza: { h: "plank", n: 15 } },
      { s: "Beden eğitimi dersine hangi kıyafetle gelinmelidir?",
        c: ["Okul spor kıyafeti ve spor ayakkabısı", "Kot pantolon ve bot", "Terlik", "Okul forması"], ceza: { h: "squat", n: 10 } }
    ],
    bitis: "Şimdi 1. istasyona geçin!"
  },
  {
    ad: "4. Sınıflar: Beden Eğitimi Bilgi Yarışması",
    sorular: [
      { s: "Egzersize başlamadan önce ısınma hareketleri yapmak neden önemlidir?",
        c: ["Sakatlanmamızı önler", "Bizi daha çok yorar"], ceza: { h: "ziplama", n: 5 } },
      { s: "Oyun sırasında bir arkadaşımız düşerse ne yapmalıyız?",
        c: ["Durup yardım ederiz", "Oyuna devam ederiz"], ceza: { h: "ziplama", n: 5 } }
    ],
    bitis: "Bilgi yarışmasını tamamladınız, aferin!"
  }
];
/* ===================== SORULARIN SONU ===================== */

var aktifIstasyon = -1;
var grupSorulari = [];
var indeks = 0;
var yanlisSayisi = 0;
var sayacZamanlayici = null;

function $(id) { return document.getElementById(id); }

/* ---------- SES ---------- */
var sesBaglami = null;
var sesAcildi = false;
function sesAc() {  // iOS sesi ancak bir dokunuş içinde açar: bağlam + sessiz tampon + resume
  if (!SES_EFEKTI) return;
  var AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  try {
    if (!sesBaglami) sesBaglami = new AC();
    if (sesBaglami.state === "suspended" && sesBaglami.resume) sesBaglami.resume();
    if (!sesAcildi) {
      var tampon = sesBaglami.createBuffer(1, 1, 22050);
      var kaynak = sesBaglami.createBufferSource();
      kaynak.buffer = tampon;
      kaynak.connect(sesBaglami.destination);
      if (kaynak.start) kaynak.start(0); else kaynak.noteOn(0);
      sesAcildi = true;
    }
  } catch (e) {}
}
function nota(frekans, gecikme, sure, tip, siddet) {
  if (!SES_EFEKTI || !sesBaglami) return;
  try {
    var osc = sesBaglami.createOscillator();
    var kazanc = sesBaglami.createGain();
    osc.type = tip || "sine";
    osc.frequency.value = frekans;
    var t0 = sesBaglami.currentTime + gecikme;
    kazanc.gain.setValueAtTime(0.0001, t0);
    kazanc.gain.linearRampToValueAtTime(siddet || 0.3, t0 + 0.02);
    kazanc.gain.exponentialRampToValueAtTime(0.0001, t0 + sure);
    osc.connect(kazanc); kazanc.connect(sesBaglami.destination);
    osc.start(t0); osc.stop(t0 + sure + 0.05);
  } catch (e) {}
}
function sesCal(fn) {  // Safari: bağlam askıdaysa önce uyandır, sonra çal
  if (!SES_EFEKTI || !sesBaglami) return;
  if (sesBaglami.state === "running" || !sesBaglami.resume) { fn(); return; }
  var p = sesBaglami.resume();
  if (p && p.then) p.then(fn, fn); else fn();
}
function sesDogru()  { sesCal(function () { nota(523, 0, 0.18); nota(659, 0.15, 0.18); nota(784, 0.3, 0.35); }); }
function sesYanlis() { sesCal(function () { nota(392, 0, 0.3, "square", 0.3); nota(311, 0.3, 0.3, "square", 0.3); nota(247, 0.6, 0.55, "square", 0.3); }); }
function sesBitis()  { sesCal(function () { nota(523, 0, 0.15); nota(659, 0.15, 0.15); nota(784, 0.3, 0.15); nota(1047, 0.45, 0.6); }); }
function sesTik()    { sesCal(function () { nota(900, 0, 0.06, "square", 0.12); }); }
function sesBip()    { sesCal(function () { nota(1200, 0, 0.5, "square", 0.25); }); }

function sesSoru()   { sesCal(function () { nota(587, 0, 0.12, "triangle", 0.3); nota(740, 0.12, 0.12, "triangle", 0.3); nota(880, 0.24, 0.12, "triangle", 0.3); nota(1175, 0.36, 0.4, "triangle", 0.3); }); }

function sesDurumYaz() {
  var el = $("sesDurum");
  if (!el) return;
  var AC = window.AudioContext || window.webkitAudioContext;
  el.innerHTML = "Ses motoru: " + (AC ? (sesBaglami ? sesBaglami.state : "dokunuş bekliyor") : "bu tarayıcıda YOK");
}
function sesTesti() {
  sesAc();
  sesSoru();
  setTimeout(sesDogru, 900);
  setTimeout(sesYanlis, 1800);
  setTimeout(sesDurumYaz, 100);
  sesDurumYaz();
}
/* ---------- /SES ---------- */

function goster(id) {
  var ekranlar = document.getElementsByTagName("div");
  for (var i = 0; i < ekranlar.length; i++) {
    if (ekranlar[i].className.indexOf("ekran") === 0) {
      ekranlar[i].className = "ekran";
    }
  }
  $(id).className = "ekran acik";
  window.scrollTo(0, 0);
}

function karistir(dizi) {
  var kopya = dizi.slice(0);
  for (var i = kopya.length - 1; i > 0; i--) {
    var j = Math.floor(Math.random() * (i + 1));
    var t = kopya[i]; kopya[i] = kopya[j]; kopya[j] = t;
  }
  return kopya;
}

function istasyonBaslat(no) {
  aktifIstasyon = no;
  yeniGrup();
}

function yeniGrup() {
  var havuz = ISTASYONLAR[aktifIstasyon].sorular;
  grupSorulari = RASTGELE ? karistir(havuz).slice(0, SORU_SAYISI) : havuz.slice(0, SORU_SAYISI);
  indeks = 0;
  yanlisSayisi = 0;
  soruGoster();
}

function soruGoster() {
  var soru = grupSorulari[indeks];
  $("istasyonAdi").innerHTML = ISTASYONLAR[aktifIstasyon].ad;
  $("soruNo").innerHTML = indeks + 1;
  $("soruToplam").innerHTML = grupSorulari.length;
  $("soruMetni").innerHTML = soru.s;

  var noktalar = "";
  for (var n = 0; n < grupSorulari.length; n++) {
    noktalar += '<span class="nokta' + (n < indeks ? " tamam" : (n === indeks ? " simdi" : "")) + '"></span>';
  }
  $("ilerleme").innerHTML = noktalar;

  var dogru = soru.c[0];
  var secenekler = karistir(soru.c);
  var html = "";
  for (var i = 0; i < secenekler.length; i++) {
    var d = (secenekler[i] === dogru) ? "1" : "0";
    var harf = "abcd".charAt(i) || "e";
    html += '<button class="secenek ' + harf + '" data-dogru="' + d + '">' +
            '<span class="harf">' + harf.toUpperCase() + '</span>' +
            '<span class="yazi">' + secenekler[i] + '</span></button>';
  }
  $("secenekler").innerHTML = html;
  goster("soruEkran");
  if (SORU_JINGLE) sesSoru();
}

function cezaGoster(ceza) {
  var h = HAREKETLER[ceza.h] || { ad: ceza.h, birim: "tekrar" };
  $("cezaMetni").innerHTML = ceza.n + " " + (h.birim === "saniye" ? "SANİYE " : "") + h.ad;

  var animler = ["squat", "ziplama", "mekik", "sinav", "plank"];
  for (var i = 0; i < animler.length; i++) {
    var el = $("anim-" + animler[i]);
    if (el) el.className = (animler[i] === ceza.h) ? "anim acik" : "anim";
  }

  sayacDurdur();
  if (h.birim === "saniye") {
    $("sayac").style.display = "block";
    $("sayac").innerHTML = ceza.n;
    $("sayacBtn").style.display = "block";
    $("sayacBtn").onclick = function () { sayacBaslat(ceza.n); };
  } else {
    $("sayac").style.display = "none";
    $("sayacBtn").style.display = "none";
  }
  goster("cezaEkran");
}

function sayacBaslat(saniye) {
  sayacDurdur();
  var kalan = saniye;
  $("sayacBtn").style.display = "none";
  $("sayac").innerHTML = kalan;
  sayacZamanlayici = setInterval(function () {
    kalan--;
    if (kalan <= 0) {
      sayacDurdur();
      sesBip();
      $("sayac").innerHTML = "Süre doldu!";
      $("sayac").style.fontSize = "48px";
    } else {
      sesTik();
      $("sayac").innerHTML = kalan;
    }
  }, 1000);
}

function sayacDurdur() {
  if (sayacZamanlayici) { clearInterval(sayacZamanlayici); sayacZamanlayici = null; }
  $("sayac").style.fontSize = "";
}

function cevapla(dogruMu) {
  if (dogruMu === 1) {
    if (indeks === grupSorulari.length - 1) {
      bitir();
    } else {
      sesDogru();
      $("dogruMesaj").innerHTML = "Harika! " + (grupSorulari.length - indeks - 1) + " soru kaldı.";
      goster("dogruEkran");
    }
  } else {
    yanlisSayisi++;
    sesYanlis();
    cezaGoster(grupSorulari[indeks].ceza);
  }
}

function cezaBitti() {
  sayacDurdur();
  soruGoster(); // aynı soru, seçenekler yeniden karışık
}

function sonrakiSoru() {
  indeks++;
  soruGoster();
}

function bitir() {
  sesBitis();
  $("bitisMesaj").innerHTML = ISTASYONLAR[aktifIstasyon].bitis || "Şimdi diğer istasyona geçin!";
  $("bitisOzet").innerHTML = yanlisSayisi === 0
    ? "Hiç yanlış yapmadan bitirdiniz, süper!"
    : "Toplam " + yanlisSayisi + " yanlış cevap verdiniz ve cezaları yaptınız.";
  goster("bitisEkran");
}

function istasyonDegistir() {
  aktifIstasyon = -1;
  goster("secimEkran");
}

function secimListesiKur() {
  var html = "";
  for (var i = 0; i < ISTASYONLAR.length; i++) {
    html += '<button class="buyuk istasyon-btn" data-no="' + i + '">' + ISTASYONLAR[i].ad + '</button>';
  }
  $("istasyonListesi").innerHTML = html;
}

function parametre(ad) {
  var q = window.location.search.replace("?", "").split("&");
  for (var i = 0; i < q.length; i++) {
    var p = q[i].split("=");
    if (p[0] === ad) return p[1];
  }
  return null;
}

function hedefButon(e) {
  var t = (e || window.event).target || (e || window.event).srcElement;
  while (t && t.tagName !== "BUTTON") t = t.parentNode;
  return t;
}
document.body.onclick = function () { sesAc(); };
$("btnSesTesti").onclick = sesTesti;
sesDurumYaz();
$("secenekler").onclick = function (e) {
  sesAc();
  var b = hedefButon(e);
  if (b) cevapla(parseInt(b.getAttribute("data-dogru"), 10));
};
$("istasyonListesi").onclick = function (e) {
  var b = hedefButon(e);
  if (b) istasyonBaslat(parseInt(b.getAttribute("data-no"), 10));
};
$("btnCeza").onclick = cezaBitti;
$("btnSonraki").onclick = sonrakiSoru;
$("btnYeniGrup").onclick = yeniGrup;
$("lnkDegistir").onclick = function () { istasyonDegistir(); return false; };

secimListesiKur();
// İstasyon numarası: /oryantasyon/1 gibi yoldan ya da ?istasyon=1 parametresinden
var yolNo = window.location.pathname.match(/\/(\d+)\/?$/);
var pIst = parseInt(yolNo ? yolNo[1] : parametre("istasyon"), 10);
if (pIst >= 1 && pIst <= ISTASYONLAR.length) {
  istasyonBaslat(pIst - 1);
}
