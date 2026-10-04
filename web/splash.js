// Yükleme ekranını kaldırır. index.html'deki satır içi sürümü Firebase
// Hosting'in CSP'si (script-src 'self' + hash) engelliyordu; canlıda
// "Yükleniyor…" ekranında takılı kalıyordu (2026-09-05).
//
// Eskiden Flutter'ın ilk karesinde kalkıyordu; arkasından dönen halka ve
// asıl ekran geliyor, logo iki kez "sekiyordu" (2026-10-05). Artık uygulama
// giriş/profil kontrolünü bitirince window.cemberHazir() çağırıyor
// (lib/widgets/acilis_bekleme.dart). Emniyet: 20 sn zaman aşımı.
(function () {
  var kaldirildi = false;
  function kaldir() {
    if (kaldirildi) return;
    kaldirildi = true;
    var s = document.getElementById('cember-splash');
    if (!s) return;
    s.classList.add('cikis');      // logo küçülüp kaybolur (.18 sn)
    s.style.opacity = '0';         // zemin .18 sn gecikmeyle söner
    s.style.pointerEvents = 'none';
    setTimeout(function () { if (s.parentNode) s.parentNode.removeChild(s); }, 500);
  }
  window.cemberHazir = kaldir;
  // Uygulama temasına göre sayfa zemini ve tema rengi (lib/utils/acilis_sinyali_web.dart).
  window.cemberZemin = function (renk) {
    document.documentElement.style.background = renk;
    document.body.style.background = renk;
    // Profil'de tema elle seçildiyse iki renk de onu göstersin.
    document.querySelectorAll('meta[name="theme-color"]').forEach(function (m) { m.setAttribute('content', renk); });
  };
  setTimeout(kaldir, 20000);
})();
