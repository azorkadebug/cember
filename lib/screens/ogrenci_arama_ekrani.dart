import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ogrenci.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../tema.dart';
import '../tema_renkleri.dart';
import 'ogrenci_listesi_ekrani.dart';
import '../utils/metin.dart';
import '../utils/egitim_yili.dart';
import '../widgets/simgeler.dart';

/// Sınıflarım'daki büyüteçten açılan, tüm sınıflarda öğrenci arayan sayfa.
/// Sabri'nin isteği (2026-09-05): öğretmen öğrenciyi biliyor ama o an
/// sınıfını düşünmek istemiyor (koridor, nöbet, veli araması).
///
/// Firestore'da "içerir" araması olmadığı için sınıfların öğrencileri bir
/// kez çekilip bellekte filtreleniyor; 300 öğrenci için önemsiz.
/// Sonuca dokununca sınıf ekranı, öğrencinin kartı açık hâlde geliyor.
/// Arama boşken son bakılan öğrenciler listeleniyor.
class OgrenciAramaEkrani extends StatefulWidget {
  const OgrenciAramaEkrani({super.key});
  @override
  State<OgrenciAramaEkrani> createState() => _OgrenciAramaEkraniState();
}

class _AramaKaydi {
  final String sinifId, sinifAd;
  final Ogrenci ogrenci;
  const _AramaKaydi(this.sinifId, this.sinifAd, this.ogrenci);
  String get anahtar => '$sinifId|${ogrenci.id}';
}


class _OgrenciAramaEkraniState extends State<OgrenciAramaEkrani> {
  static const _sonBakilanAnahtari = 'son_bakilan_ogrenciler';
  static const _sonBakilanMaks = 5;

  late final FirestoreService _db;
  final _ctrl = TextEditingController();
  List<_AramaKaydi> _tumu = const [];
  List<String> _sonBakilan = const [];
  bool _yukleniyor = true;
  bool _hata = false;
  String _metin = '';

  @override
  void initState() {
    super.initState();
    _db = FirestoreService(uid: AuthService().uid);
    _yukle();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    if (_hata) setState(() { _hata = false; _yukleniyor = true; });
    final prefs = await SharedPreferences.getInstance();
    final son = prefs.getStringList(_sonBakilanAnahtari) ?? const [];
    final kayitlar = <_AramaKaydi>[];
    try {
      final siniflar = await _db.siniflarGetir();
      // Sınıflar paralel çekiliyor (denetim #3 D11).
      // Yalnız bu yılın sınıfları: geçen yıldan aktarılan öğrenci arşivde
      // de durduğu için aramada iki kez çıkıyordu.
      final simdiki = EgitimYili.simdiki;
      final buYil = siniflar.docs.where((d) =>
          EgitimYili.sinifin(d.data() as Map<String, dynamic>?).compareTo(simdiki) >= 0);
      final sonuclar = await Future.wait(buYil.map((d) async {
        final data = d.data() as Map<String, dynamic>?;
        final ad = (data?['ad'] ?? d.id).toString();
        final ogrenciler = await _db.ogrencileriGetir(d.id);
        return [for (final o in ogrenciler) _AramaKaydi(d.id, ad, o)];
      }));
      for (final l in sonuclar) {
        kayitlar.addAll(l);
      }
    } catch (_) {
      // Okuma hatasında sonsuz spinner kalıyordu (denetim #3 D9).
      if (mounted) setState(() { _hata = true; _yukleniyor = false; });
      return;
    }
    kayitlar.sort((a, b) => trKarsilastir(a.ogrenci.ad, b.ogrenci.ad));
    if (!mounted) return;
    setState(() {
      _tumu = kayitlar;
      _sonBakilan = son;
      _yukleniyor = false;
    });
  }

  Future<void> _ac(_AramaKaydi k) async {
    final prefs = await SharedPreferences.getInstance();
    final yeni = [k.anahtar, ..._sonBakilan.where((a) => a != k.anahtar)].take(_sonBakilanMaks).toList();
    await prefs.setStringList(_sonBakilanAnahtari, yeni);
    if (!mounted) return;
    setState(() => _sonBakilan = yeni);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OgrenciListesiEkrani(
          sinifId: k.sinifId,
          sinifAd: k.sinifAd,
          acilacakOgrenciId: k.ogrenci.id,
        ),
      ),
    );
  }

  List<_AramaKaydi> get _sonuclar {
    if (_metin.isEmpty) {
      // Arama boşken: son bakılanlar, sırasıyla; silinmiş öğrenciler düşer.
      return _sonBakilan
          .map((a) => _tumu.where((k) => k.anahtar == a).firstOrNull)
          .whereType<_AramaKaydi>()
          .toList();
    }
    // Demo modunda kullanıcı ekranda gördüğü (maskeli) ada göre arar.
    return _tumu.where((k) => trKucult(k.ogrenci.gorunenAd).contains(_metin)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sonuclar = _sonuclar;
    final bosArama = _metin.isEmpty;
    final r = context.renk;
    return Scaffold(
      backgroundColor: r.sayfa,
      appBar: AppBar(
        backgroundColor: r.bar,
        foregroundColor: r.barMetin,
        elevation: 0,
        titleSpacing: 0,
        title: Semantics(
          label: 'Öğrenci ara',
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: r.barMetin, fontSize: 16),
            cursorColor: r.barMetin,
            onChanged: (v) => setState(() => _metin = trKucult(v.trim())),
            decoration: InputDecoration(
              hintText: 'Öğrenci ara…',
              hintStyle: TextStyle(color: r.barMetin.withAlpha(170)),
              border: InputBorder.none,
              suffixIcon: _metin.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close_rounded, color: r.barMetin),
                      tooltip: 'Aramayı temizle',
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _metin = '');
                      },
                    ),
            ),
          ),
        ),
      ),
      body: _yukleniyor
          ? Center(child: CircularProgressIndicator(color: r.vurgu))
          : _hata
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.cloud_off_rounded, size: 56, color: r.bosDurumIkonu),
                    const SizedBox(height: 12),
                    Text('Öğrenciler yüklenemedi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: r.metinIkincil)),
                    const SizedBox(height: 12),
                    FilledButton.icon(onPressed: _yukle, icon: const Icon(Icons.refresh_rounded), label: const Text('Tekrar dene')),
                  ]),
                )
              : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
                child: _tumu.isEmpty
                    ? _bilgi(Icons.school_outlined, 'Henüz öğrenci yok',
                        'Önce bir sınıf oluşturup öğrenci ekle.')
                    : sonuclar.isEmpty
                        ? (bosArama
                            ? _bilgi(Icons.search_rounded, 'İsim yazmaya başla',
                                '${_tumu.length} öğrenci arasında arar. Son baktıkların burada listelenir.')
                            : _bilgi(Icons.person_search_rounded, 'Sonuç yok',
                                '"${_ctrl.text.trim()}" ile eşleşen öğrenci bulunamadı.'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: sonuclar.length + (bosArama ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (bosArama && i == 0) {
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                                  child: Text('SON BAKILANLAR',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.1,
                                          color: r.metinUcuncul)),
                                );
                              }
                              return _satir(sonuclar[bosArama ? i - 1 : i]);
                            },
                          ),
              ),
            ),
    );
  }

  Widget _satir(_AramaKaydi k) {
    final o = k.ogrenci;
    final r = context.renk;
    final renk = o.isMale ? Colors.blue.shade500 : Colors.pink.shade500;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: r.kart,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black.withAlpha(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _ac(k),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Semantics(
                label: o.isMale ? 'Erkek öğrenci' : 'Kız öğrenci',
                excludeSemantics: true,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: renk.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: CinsiyetSimgesi(o.isMale, boyut: 22, renk: renk)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.gorunenAd,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.class_outlined, size: 14, color: r.metinUcuncul),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(k.sinifAd,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: r.metinIkincil)),
                    ),
                    // Not içeriği bilerek gösterilmiyor (mahremiyet, 2026-08-28).
                    if (o.rozetler.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.emoji_events_rounded, size: 14, color: r.uyari),
                      const SizedBox(width: 2),
                      Text('${o.rozetler.length}',
                          style: TextStyle(fontSize: 12, color: r.uyari, fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ]),
              ),
              Icon(Icons.chevron_right_rounded, color: r.metinUcuncul),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _bilgi(IconData ikon, String baslik, String aciklama) {
    final r = context.renk;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ikon, size: 64, color: r.bosDurumIkonu),
          const SizedBox(height: 14),
          Text(baslik,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: r.metinIkincil)),
          const SizedBox(height: 6),
          Text(aciklama,
              textAlign: TextAlign.center,
              style: TextStyle(color: r.metinUcuncul)),
        ]),
      ),
    );
  }
}
