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

@JS('cemberZemin')
external void _cemberZemin(JSString renk);

/// Tarayıcının sayfa zemini ve tema rengi (iPhone Safari'de alt çubuğun
/// arkası, adres çubuğu) uygulamanın zeminiyle aynı olsun; yoksa beyaz
/// kalıyordu (Sabri, 2026-10-05).
void sayfaZemininiAyarla(int argb) {
  final hex = '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  try {
    _cemberZemin(hex.toJS);
  } catch (_) {}
}
