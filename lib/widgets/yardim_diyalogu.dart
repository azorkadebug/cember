import 'package:flutter/material.dart';
import '../tema.dart';
import '../tema_renkleri.dart';
import 'cikartma.dart';

/// Her ekranın app bar'ına eklenebilen yardım dialogu.
///
/// Kullanım:
/// ```dart
/// AppBar(
///   actions: [
///     IconButton(
///       icon: const Icon(Icons.help_outline_rounded),
///       onPressed: () => YardimDiyalogu.goster(
///         context,
///         baslik: 'Sınıflarım',
///         bolumler: [
///           YardimBolumu(
///             ikon: Icons.add_circle_outline,
///             baslik: 'Yeni sınıf oluştur',
///             aciklama: '...',
///           ),
///         ],
///       ),
///     ),
///   ],
/// )
/// ```
class YardimDiyalogu extends StatelessWidget {
  final String baslik;
  final List<YardimBolumu> bolumler;

  const YardimDiyalogu({
    super.key,
    required this.baslik,
    required this.bolumler,
  });

  /// Sınıflarım yardımı; ana ekrandaki yardım simgesi Profil'e taşındı.
  static Future<void> siniflarim(BuildContext context) => goster(
        context,
        baslik: 'Sınıflarım — Yardım',
        bolumler: const [
          YardimBolumu(
            ikon: Icons.add_circle_outline_rounded,
            baslik: 'Yeni sınıf oluştur',
            aciklama: 'Sağ alttaki "Sınıf Ekle" düğmesi → sınıf adı yaz (örn. 7-A) ve branşını seç. Kontrol kalemleri (forma, kitap, boya…) branşa göre hazır gelir; takım renkleri de otomatik atanır.',
            renk: Color(0xFF63C77A),
          ),
          YardimBolumu(
            ikon: Icons.touch_app_rounded,
            baslik: 'Sınıfa giriş',
            aciklama: 'Sınıf kartına dokun → o sınıfın öğrenci listesi açılır. Yoklama alabilir, öğrenci ekleyebilir, takım kurup oyun başlatabilirsin. Karttaki yüzde, son yoklamada gelenlerin oranı; "?" bugün yoklama alınmadığını gösterir.',
            renk: Color(0xFF4FA3F7),
          ),
          YardimBolumu(
            ikon: Icons.sports_kabaddi_rounded,
            baslik: 'Sınıflar Arası Yarışma',
            aciklama: 'Sınıf kartlarının sonundaki "Sınıflar Arası Yarışma" kartı: iki sınıfı karşı karşıya getir (örn. 7-A ile 7-B) — maç, bilgi yarışması, münazara… Her sınıf bir takım olur, skor tablosu açılır.',
            renk: Color(0xFFFFA63D),
          ),
          YardimBolumu(
            ikon: Icons.edit_rounded,
            baslik: 'Sınıf adı değiştir / taşı / sil',
            aciklama: 'Kartın sağ altındaki ⋯ düğmesine dokun ya da karta basılı tut → "İsmi Düzenle", "Geçmiş Yıla Taşı" ya da "Sınıfı Sil". Silme geri alınamaz.',
            renk: Color(0xFFFF6B57),
          ),
          YardimBolumu(
            ikon: Icons.visibility_off_rounded,
            baslik: 'Demo modu',
            aciklama: 'Profil → "Demo modu": öğrenci adları sahte isimlerle gösterilir (sunum ve ekran görüntüsü için). Açıkken her ekranın üstünde turuncu şerit görünür.',
            renk: Color(0xFFB794F6),
          ),
          YardimBolumu(
            ikon: Icons.palette_rounded,
            baslik: 'Takım renkleri',
            aciklama: 'Takım kurarken formalar sırayla renk alır: kırmızı, mavi, sarı, yeşil, siyah, turuncu, mor, lacivert. Sınıfın forma listesini öğrenci ekranındaki ⋮ menüsünden "Takım Renkleri" ile değiştirebilirsin.',
            renk: Color(0xFF8E24AA),
          ),
        ],
      );

  static Future<void> goster(
    BuildContext context, {
    required String baslik,
    required List<YardimBolumu> bolumler,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => YardimDiyalogu(baslik: baslik, bolumler: bolumler),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      // "Teneffüs": krem zemin, mürekkep kenar, bölümler çıkartma kartlar.
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: r.sayfa,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: r.kenar, width: 2.5),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: r.cizgi, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFD84D),
                      shape: CircleBorder(side: BorderSide(color: r.kenar, width: 2.5)),
                    ),
                    child: const Icon(Icons.question_mark_rounded, color: AppTema.ana, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      baslik,
                      style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 24, fontWeight: FontWeight.w600, color: r.metin, height: 1.15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Kapat',
                    color: r.metin,
                    style: IconButton.styleFrom(
                      backgroundColor: r.kart,
                      side: BorderSide(color: r.kenar, width: 2),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: bolumler.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _BolumKart(bolum: bolumler[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YardimBolumu {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final Color? renk;

  const YardimBolumu({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    this.renk,
  });
}

/// Yardım bölümlerine eski Material renkleri verilmiş (yeşil 43A047, mavi
/// 1976D2…); her birini tonuna en yakın Teneffüs rengine çevirir.
Color _teneffusRengi(Color c) {
  const palet = [
    Color(0xFFFF6B57), // domates
    Color(0xFFFFA63D), // portakal
    Color(0xFFFFD84D), // limon
    Color(0xFF63C77A), // çimen
    Color(0xFF4DD9C6), // turkuaz
    Color(0xFF4FA3F7), // gök
    Color(0xFFB794F6), // mürdüm
    Color(0xFFFF8FB1), // pembe
  ];
  final h = HSVColor.fromColor(c).hue;
  double fark(Color p) {
    final d = (HSVColor.fromColor(p).hue - h).abs();
    return d > 180 ? 360 - d : d;
  }
  return palet.reduce((a, b) => fark(a) <= fark(b) ? a : b);
}

class _BolumKart extends StatelessWidget {
  final YardimBolumu bolum;
  const _BolumKart({required this.bolum});

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    final renk = _teneffusRengi(bolum.renk ?? AppTema.vurgu);
    return Cikartma(
      kayma: 3,
      yaricap: 20,
      dolgu: const EdgeInsets.fromLTRB(12, 12, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: renk,
              shape: CircleBorder(side: BorderSide(color: r.kenar, width: 2)),
            ),
            child: Icon(bolum.ikon, color: AppTema.ana, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bolum.baslik,
                  style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 18, fontWeight: FontWeight.w600, color: r.metin, height: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  bolum.aciklama,
                  style: TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w600, color: r.metinGovde),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
