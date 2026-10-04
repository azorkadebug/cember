import 'dart:js_interop';

@JS('cemberHazir')
external void _cemberHazir();

/// web/splash.js'teki HTML açılış ekranını kaldırır (yumuşak geçiş).
void acilisEkraniniKaldir() {
  try {
    _cemberHazir();
  } catch (_) {
    // splash.js yüklenmediyse fonksiyon yok; açılış ekranı zaten yok.
  }
}
