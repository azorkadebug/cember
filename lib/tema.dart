import 'package:flutter/material.dart';

/// Gizlilik politikası ve KVKK aydınlatma metni (web'de yayında).
const String gizlilikPolitikasiUrl = 'https://cemberapp-2a101.web.app/privacy.html';

class AppTema {
  static const Color ana = Color(0xFF37474F);        // Charcoal
  static const Color anaKoyu = Color(0xFF263238);    // Koyu ton
  static const Color anaAcik = Color(0xFF546E7A);    // Açık ton
  static final Color ana50 = Colors.blueGrey.shade50;

  // ---------------------------------------------------------------
  // Marka vurgu rengi (Sabri seçti, 2026-09-05): turkuaz. Yalnız ANA
  // EYLEMLERDE kullanılır — birincil düğmeler, FAB'lar, odak çerçevesi,
  // seçili durum, ilerleme göstergesi. AppBar ve koyu paneller charcoal
  // kalır; yeşil/sarı/kırmızı başarı/uyarı/tehlike için ayrılmıştır.
  // Beyaz üzerinde 4,6:1 (AA).
  // ---------------------------------------------------------------
  static const Color vurgu = Color(0xFF00897B);
  static const Color vurguKoyu = Color(0xFF00695C);
  static const Color vurguZemin = Color(0xFFE0F2F1);

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


  // ---------------------------------------------------------------
  // Forma / takım renkleri. Önceden ogrenci_listesi_ekrani (11 kayıt) ve
  // siniflar_ekrani (8 kayıt) ayrı ayrı kopyalıyordu; "turuncu" ikisinde de
  // charcoal dönüyordu (2026-09-04 denetimi O7). Tek kaynak burası.
  // ---------------------------------------------------------------
  static const List<String> formaRenkAdlari = [
    'Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Turuncu', 'Mor', 'Lacivert',
  ];

  static Color formaRengi(String renkAdi) {
    switch (renkAdi.toLowerCase().trim()) {
      case 'kırmızı': return const Color(0xFFE53935);
      case 'mavi': return const Color(0xFF1E88E5);
      case 'sarı': return const Color(0xFFFFB300);
      case 'yeşil': return const Color(0xFF43A047);
      case 'siyah': return const Color(0xFF212121);
      case 'beyaz': return const Color(0xFFE0E0E0);
      case 'turuncu': return const Color(0xFFF57C00);
      case 'mor': return const Color(0xFF8E24AA);
      case 'pembe': return const Color(0xFFEC407A);
      case 'lacivert': return const Color(0xFF283593);
      case 'gri': return const Color(0xFF757575);
      default: return ana;
    }
  }

  /// [zemin] üzerine yazılacak metin için beyaz mı koyu mu daha okunur?
  /// Sarı/beyaz/gri formalarda beyaz metin 1,5–1,9:1'e düşüyordu (denetim Y4).
  static Color ustMetin(Color zemin) {
    final l = zemin.computeLuminance();
    final beyazKontrast = 1.05 / (l + 0.05);
    final koyuKontrast = (l + 0.05) / (panelKoyu1.computeLuminance() + 0.05);
    return beyazKontrast >= koyuKontrast ? Colors.white : panelKoyu1;
  }

  /// Renkli zeminde düğme/vurgu dolgusu: metin rengine göre saydam beyaz
  /// ya da saydam siyah.
  static Color ustDolgu(Color zemin) =>
      ustMetin(zemin) == Colors.white ? Colors.white.withAlpha(40) : Colors.black.withAlpha(28);

  /// Geniş ekranda (iPad, masaüstü web) içeriğin yayılabileceği azami genişlik.
  /// Sarmalarken `Center` DEĞİL `Align(topCenter)` kullan — bkz.
  /// profil_ekrani.dart'taki iPad kaydırma notu.
  static const double icerikMaxGenislik = 720;
}
