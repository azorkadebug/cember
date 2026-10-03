import 'package:flutter/material.dart';
import '../widgets/cikartma.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema.dart';
import '../tema_renkleri.dart';

/// İlk açılışta gösterilen tanıtım carousel'i (v1.1).
/// Bir kez gösterilir; [goruldueMu] / [goruldueIsaretle] ile takip edilir.
class TanitimEkrani extends StatefulWidget {
  final VoidCallback onTamamlandi;
  const TanitimEkrani({super.key, required this.onTamamlandi});

  static const _prefsAnahtari = 'tanitim_goruldu_v1_1';

  static Future<bool> goruldueMu() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsAnahtari) ?? false;
  }

  static Future<void> goruldueIsaretle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsAnahtari, true);
  }

  @override
  State<TanitimEkrani> createState() => _TanitimEkraniState();
}

class _TanitimSayfasi {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final Color renk;
  const _TanitimSayfasi(this.ikon, this.baslik, this.aciklama, this.renk);
}

class _TanitimEkraniState extends State<TanitimEkrani> {
  final _controller = PageController();
  int _sayfa = 0;

  static const _sayfalar = [
    _TanitimSayfasi(
      Icons.school_rounded,
      'Sınıfını Kur',
      'Sınıflarını ekle, branşını seç. Derste ne takip ediyorsan '
          '— forma, kitap, boya, enstrüman — branşına göre hazır gelir.',
      Color(0xFF63C77A),
    ),
    _TanitimSayfasi(
      Icons.fact_check_rounded,
      'Yoklamanı Tek Dokunuşla Al',
      'Kim geldi, kim gelmedi? Dokun, işaretle. Kitabını ya da formasını '
          'unutanı da aynı ekranda not et. Hepsi tarihiyle kaydedilir.',
      Color(0xFF4FA3F7),
    ),
    _TanitimSayfasi(
      Icons.emoji_events_rounded,
      'Adil Takımlar Kur',
      'Bir dokunuşla dengeli takımlar oluştur. Uygulama, anlaşamayan '
          'öğrencileri ayrı takımlara koyar. Skor tablosu ve süre sayacı da hazır.',
      Color(0xFFFFD84D),
    ),
    _TanitimSayfasi(
      Icons.visibility_off_rounded,
      'Öğrenci Bilgileri Güvende',
      'Sunum yaparken ya da ekran görüntüsü paylaşırken demo modunu aç: '
          'gerçek isimler gizlenir, yerlerine rastgele isimler görünür.',
      Color(0xFFB794F6),
    ),
  ];

  bool get _sonSayfa => _sayfa == _sayfalar.length - 1;

  Future<void> _bitir() async {
    await TanitimEkrani.goruldueIsaretle();
    widget.onTamamlandi();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    return Scaffold(
      backgroundColor: r.sayfa,
      body: SafeArea(
        child: Column(
          children: [
            // Atla düğmesi
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextButton(
                  onPressed: _bitir,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(64, 44),
                  ),
                  // grey.shade500 beyaz üzerinde 2,8:1 veriyordu.
                  child: Text('Atla',
                      style: TextStyle(color: r.metin, fontWeight: FontWeight.w600, fontSize: 17)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _sayfalar.length,
                onPageChanged: (i) => setState(() => _sayfa = i),
                itemBuilder: (context, i) {
                  final s = _sayfalar[i];
                  // İçerik bloğu, Expanded'ın verdiği tüm alanın ortasına
                  // hizalanınca üstte yarım ekran ölü alan kalıyordu.
                  // Oranlı Spacer'larla denge yukarı çekildi (2 üst / 3 alt).
                  // Kaydırılabilir: yatay telefonda ve büyük yazıda açıklama
                  // kesiliyor, 4. sayfadaki mahremiyet notu kayboluyordu
                  // (denetim #3). Geniş ekranda 520 px'e sınırlı.
                  return LayoutBuilder(builder: (context, c) {
                    final kisa = c.maxHeight < 440;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: c.maxHeight),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                Container(
                                  padding: EdgeInsets.all(kisa ? 18 : 30),
                                  decoration: ShapeDecoration(
                                    color: s.renk,
                                    shape: const CircleBorder(side: BorderSide(color: AppTema.ana, width: 3)),
                                    shadows: const [BoxShadow(color: AppTema.ana, offset: Offset(6, 6))],
                                  ),
                                  child: Icon(s.ikon, size: kisa ? 44 : 76, color: AppTema.ana),
                                ),
                                SizedBox(height: kisa ? 16 : 32),
                                Text(s.baslik,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: AppTema.baslikFontu, fontSize: 30, fontWeight: FontWeight.w700, color: r.metin, height: 1.15)),
                                const SizedBox(height: 12),
                                Text(s.aciklama,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w600, color: r.metinIkincil)),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
            // Sayfa noktaları
            Semantics(
              label: 'Sayfa ${_sayfa + 1} / ${_sayfalar.length}',
              excludeSemantics: true,
              child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_sayfalar.length, (i) {
                final aktif = i == _sayfa;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: aktif ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: aktif ? r.metin : r.cizgi,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
              ),
            ),
            // İleri / Başla düğmesi
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: SertGolgeli(
                child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    if (_sonSayfa) {
                      _bitir();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  child: Text(_sonSayfa ? 'Hadi Başlayalım!' : 'İleri',
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
