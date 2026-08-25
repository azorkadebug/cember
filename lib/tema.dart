import 'package:flutter/material.dart';

class AppTema {
  static const Color ana = Color(0xFF37474F);        // Charcoal
  static const Color anaKoyu = Color(0xFF263238);    // Koyu ton
  static const Color anaAcik = Color(0xFF546E7A);    // Açık ton
  static final Color ana50 = Colors.blueGrey.shade50;

  static final gradient = [ana, anaKoyu];
  static final gradientAcik = [ana, anaAcik];

  // ---------------------------------------------------------------
  // Koyu panel (skor tablosu, admin, "etkinlik sürüyor" bandı).
  // Bu çift daha önce 5 dosyada 13 kez elle yazılıyordu.
  // ---------------------------------------------------------------
  static const Color panelKoyu1 = Color(0xFF1A1A2E);
  static const Color panelKoyu2 = Color(0xFF16213E);
  static const List<Color> panelGradient = [panelKoyu1, panelKoyu2];

  // ---------------------------------------------------------------
  // İkincil metin renkleri. Kullanılan gri tonları (shade300/400/500)
  // beyaz zeminde WCAG AA eşiğini (4.5:1) geçmiyordu — bunlar geçiyor.
  // ---------------------------------------------------------------
  static const Color metinIkincil = Color(0xFF5A6870);  // beyaz üzerinde 5.7:1
  static const Color metinUcuncul = Color(0xFF67757D);  // beyaz üzerinde 4.8:1

  // ---------------------------------------------------------------
  // Semantik renkler. "Koyu" varyantlar açık zemin üzerinde METİN için;
  // düz varyantlar dolgu/ikon için.
  // ---------------------------------------------------------------
  static const Color basari = Color(0xFF1B5E20);       // yeşil zemin üzerinde 5.9:1
  static const Color basariZemin = Color(0xFFC8E6C9);
  static const Color uyari = Color(0xFF8A5300);        // beyaz üzerinde 5.2:1
  static const Color uyariZemin = Color(0xFFFFF3E0);
  static const Color tehlike = Color(0xFFB3261E);
  static const Color tehlikeZemin = Color(0xFFFDECEA);

  // ---------------------------------------------------------------
  // Tipografi ölçeği. Önceden 18 farklı satır içi fontSize vardı
  // (9,10,11,12,13,14,15,16,17,18,20,22,24,26,28,30,38,48); yeni kod
  // buradan çeksin.
  // ---------------------------------------------------------------
  static const TextTheme textTheme = TextTheme(
    displaySmall:    TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
    headlineMedium:  TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
    headlineSmall:   TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
    titleLarge:      TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
    titleMedium:     TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    titleSmall:      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge:       TextStyle(fontSize: 16),
    bodyMedium:      TextStyle(fontSize: 14),
    bodySmall:       TextStyle(fontSize: 13, color: metinIkincil),
    labelLarge:      TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium:     TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall:      TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: metinUcuncul),
  );

  /// Geniş ekranda (iPad, masaüstü web) içeriğin yayılabileceği azami genişlik.
  /// Sarmalarken `Center` DEĞİL `Align(topCenter)` kullan — bkz.
  /// profil_ekrani.dart'taki iPad kaydırma notu.
  static const double icerikMaxGenislik = 720;
}
