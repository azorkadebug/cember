import 'package:flutter/material.dart';

/// Gizlilik politikası ve KVKK aydınlatma metni (web'de yayında).
const String gizlilikPolitikasiUrl = 'https://cemberapp-2a101.web.app/privacy.html';

class AppTema {
  // "Teneffüs" görünümü (Sabri'nin seçimi, 2026-10-04): charcoal yerine
  // mürekkep laciverti; kenar çizgileri ve sert gölgeler de bu renkte.
  static const Color ana = Color(0xFF1F2430);        // Mürekkep
  static const Color anaKoyu = Color(0xFF151923);    // Koyu ton
  static const Color anaAcik = Color(0xFF2E3446);    // Açık ton
  static const Color ana50 = Color(0xFFF1E8DA);

  /// Başlık yazı tipi (yuvarlak, tok). Gövde: tema `fontFamily` = Nunito.
  static const String baslikFontu = 'Fredoka';
  static const String govdeFontu = 'Nunito';

  /// Sınıflara sırayla verilen renkler — logodaki halkaların renkleri.
  /// Hepsinin üstünde mürekkep yazı en az 4,5:1.
  static const List<Color> sinifRenkleri = [
    Color(0xFFFF6B57), // domates
    Color(0xFF4FA3F7), // gök
    Color(0xFF63C77A), // çimen
    Color(0xFFFFD84D), // limon
    Color(0xFFB794F6), // mürdüm
    Color(0xFFFFA63D), // portakal
  ];

  // ---------------------------------------------------------------
  // Marka vurgu rengi (Sabri seçti, 2026-09-05): turkuaz. Yalnız ANA
  // EYLEMLERDE kullanılır — birincil düğmeler, FAB'lar, odak çerçevesi,
  // seçili durum, ilerleme göstergesi. AppBar ve koyu paneller charcoal
  // kalır; yeşil/sarı/kırmızı başarı/uyarı/tehlike için ayrılmıştır.
  // Beyaz yazıyla 5,3:1. Eski #00897B 4,32:1'di; yorumdaki "4,6" yanlıştı
  // (denetim #3, piksel ölçümü).
  // ---------------------------------------------------------------
  static const Color vurgu = Color(0xFF00796B);
  static const Color vurguKoyu = Color(0xFF00695C);
  static const Color vurguZemin = Color(0xFFDDF2EE);

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
  static const Color metinIkincil = Color(0xFF4A5060);  // krem zeminde 7,4:1
  static const Color metinUcuncul = Color(0xFF5F6575);  // krem zeminde 5,6:1

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
  // Büyük başlıklar Fredoka (en kalını 700), gerisi Nunito.
  static const TextTheme textTheme = TextTheme(
    displaySmall:    TextStyle(fontFamily: baslikFontu, fontSize: 32, fontWeight: FontWeight.w700),
    headlineMedium:  TextStyle(fontFamily: baslikFontu, fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall:   TextStyle(fontFamily: baslikFontu, fontSize: 24, fontWeight: FontWeight.w600),
    titleLarge:      TextStyle(fontFamily: baslikFontu, fontSize: 21, fontWeight: FontWeight.w600),
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
