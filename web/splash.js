// Yükleme ekranını kaldırır. index.html'deki satır içi sürümü Firebase
// Hosting'in CSP'si (script-src 'self' + hash) engelliyordu; canlıda
// "Yükleniyor…" ekranında takılı kalıyordu (2026-09-05). Üç emniyet:
// Flutter'ın ilk kare olayı, flutter-view'ın DOM'a gelmesi, 12 sn zaman aşımı.
(function () {
  var kaldirildi = false;
  function kaldir() {
    if (kaldirildi) return;
    kaldirildi = true;
    var s = document.getElementById('cember-splash');
    if (!s) return;
    s.style.opacity = '0';
    s.style.pointerEvents = 'none';
    setTimeout(function () { if (s.parentNode) s.parentNode.removeChild(s); }, 320);
  }
  window.addEventListener('flutter-first-frame', kaldir);
  if (document.querySelector('flutter-view')) { setTimeout(kaldir, 400); }
  else if (window.MutationObserver) {
    var mo = new MutationObserver(function () {
      if (document.querySelector('flutter-view')) { mo.disconnect(); setTimeout(kaldir, 400); }
    });
    mo.observe(document.documentElement, { childList: true, subtree: true });
  }
  setTimeout(kaldir, 12000);
})();
