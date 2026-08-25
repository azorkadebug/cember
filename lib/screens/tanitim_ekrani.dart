import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tema.dart';

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
      Color(0xFF43A047),
    ),
    _TanitimSayfasi(
      Icons.fact_check_rounded,
      'Yoklamanı Tek Dokunuşla Al',
      'Kim geldi, kim gelmedi? Dokun, işaretle. Kitabını ya da formasını '
          'unutanı da aynı ekranda not et. Hepsi tarihiyle kaydedilir.',
      Color(0xFF1976D2),
    ),
    _TanitimSayfasi(
      Icons.emoji_events_rounded,
      'Adil Takımlar Kur',
      'Bir dokunuşla dengeli takımlar oluştur. Uygulama, anlaşamayan '
          'öğrencileri ayrı takımlara koyar. Skor tablosu ve süre sayacı da hazır.',
      Color(0xFFC77B46),
    ),
    _TanitimSayfasi(
      Icons.visibility_off_rounded,
      'Öğrenci Bilgileri Güvende',
      'Sunum yaparken ya da ekran görüntüsü paylaşırken demo modunu aç: '
          'gerçek isimler gizlenir, yerlerine rastgele isimler görünür.',
      Color(0xFF8E24AA),
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
    return Scaffold(
      backgroundColor: Colors.white,
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
                  child: const Text('Atla',
                      style: TextStyle(color: AppTema.metinIkincil, fontWeight: FontWeight.w600)),
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(color: s.renk.withAlpha(20), shape: BoxShape.circle),
                          child: Icon(s.ikon, size: 80, color: s.renk),
                        ),
                        const SizedBox(height: 36),
                        Text(s.baslik,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTema.panelKoyu1)),
                        const SizedBox(height: 16),
                        Text(s.aciklama,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 15, height: 1.6, color: AppTema.metinIkincil)),
                        const Spacer(flex: 3),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Sayfa noktaları
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_sayfalar.length, (i) {
                final aktif = i == _sayfa;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: aktif ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: aktif ? AppTema.ana : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            // İleri / Başla düğmesi
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTema.ana,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (_sonSayfa) {
                      _bitir();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  child: Text(_sonSayfa ? 'Hadi Başlayalım!' : 'İleri',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
