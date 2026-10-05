import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tema.dart';
import '../tema_renkleri.dart';
import 'cikartma.dart';

/// Güncellemeden sonra bir kez açılan "Yenilikler" penceresi.
///
/// Yalnız önceki sürümü kullanmış öğretmene çıkar: tanıtımı yeni bitiren
/// kullanıcı için [goruldueIsaretle] çağrılır (bkz. tanitim_ekrani.dart),
/// ilk günden "yenilik" listesi görmesin. Sınıflarım açılışında gösterilir;
/// yoklama ve skor ekranını hiç kesmez.
///
/// Yeni sürümde: [surum]'u ve [_maddeler]'i güncelle. En çok 3 madde —
/// öğretmen bunu teneffüste okuyor.
class YeniliklerPenceresi extends StatelessWidget {
  const YeniliklerPenceresi({super.key});

  /// Maddelerin anlattığı sürüm (pubspec'teki sürümden bağımsız: yamada
  /// pencere yeniden çıkmasın diye elle artırılır).
  static const surum = '1.2.0';
  static const _prefsAnahtari = 'yenilikler_gorulen_surum';

  static const _maddeler = [
    _Madde(Icons.palette_rounded, 0,
        "Yepyeni Teneffüs görünümü. Koyu temayı Profil'deki Görünüm ayarından seç."),
    _Madde(Icons.casino_rounded, 3,
        'Sınıf ekranındaki zar simgesiyle rastgele öğrenci seç; aynı gün kimse iki kez çıkmaz.'),
    _Madde(Icons.event_repeat_rounded, 2,
        "Geçen yılın sınıfları Geçmiş Yıllar'da; öğrencileri Geçen Yıldan Ekle ile taşı."),
  ];

  static Future<bool> goruldueMu() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsAnahtari) == surum;
  }

  static Future<void> goruldueIsaretle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsAnahtari, surum);
  }

  /// Bu sürümün yenilikleri görülmediyse pencereyi açar. Pencere açılır
  /// açılmaz görüldü sayılır: kapatmadan uygulamadan çıkan öğretmene
  /// her açılışta yeniden çıkmasın.
  static Future<void> gerekirseGoster(BuildContext context) async {
    try {
      if (await goruldueMu()) return;
      await goruldueIsaretle();
    } catch (_) {
      // localStorage kapalı (gizli sekme, engelli site verisi): pencereyi
      // her açılışta göstermektense hiç gösterme.
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => const YeniliklerPenceresi(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Temanın diyalog kenarı Cikartma'nın arkasında ikinci çerçeve
      // çiziyordu; kenarı ve sert gölgeyi Cikartma çizer.
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Cikartma(
          renk: r.kartUstu,
          yaricap: 24,
          kayma: 6,
          kenarKalinligi: 3,
          child: Stack(
            children: [
              // Küçük telefonda ve büyük yazı boyutunda taşmasın.
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: SvgPicture.asset('assets/images/logo_simge.svg', width: 64, height: 64),
                    ),
                    const SizedBox(height: 14),
                    Semantics(
                      header: true,
                      child: Text("Çember'deki yenilikler",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: AppTema.baslikFontu,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: r.metin,
                              height: 1.2)),
                    ),
                    const SizedBox(height: 22),
                    for (final m in _maddeler) _MaddeSatiri(madde: m),
                    const SizedBox(height: 10),
                    SertGolgeli(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Devam et', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  tooltip: 'Kapat',
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: Icon(Icons.close_rounded, color: r.metin, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Madde {
  final IconData ikon;

  /// [AppTema.sinifRenkleri] içindeki sıra.
  final int renkSirasi;
  final String metin;
  const _Madde(this.ikon, this.renkSirasi, this.metin);
}

class _MaddeSatiri extends StatelessWidget {
  const _MaddeSatiri({required this.madde});
  final _Madde madde;

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 44,
              height: 44,
              decoration: ShapeDecoration(
                color: AppTema.sinifRenkleri[madde.renkSirasi],
                // Renkli daire her iki temada da mürekkep kenarlı; ikon
                // mürekkep (sınıf renklerinin üstünde en az 4,5:1).
                shape: const CircleBorder(side: BorderSide(color: AppTema.ana, width: 2)),
              ),
              child: Icon(madde.ikon, color: AppTema.ana, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(madde.metin,
                style: TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w600, color: r.metinGovde)),
          ),
        ],
      ),
    );
  }
}
