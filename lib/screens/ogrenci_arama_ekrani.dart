import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ogrenci.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../tema.dart';
import 'ogrenci_listesi_ekrani.dart';

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

/// Türkçe'ye duyarlı küçük harf: Dart'ın toLowerCase'i "İ"yi "i̇" (i + nokta)
/// yapar, "I"yı "i" yapar; "İrem" araması "irem" ile eşleşmezdi.
String trKucult(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

class _OgrenciAramaEkraniState extends State<OgrenciAramaEkrani> {
  static const _sonBakilanAnahtari = 'son_bakilan_ogrenciler';
  static const _sonBakilanMaks = 5;

  late final FirestoreService _db;
  final _ctrl = TextEditingController();
  List<_AramaKaydi> _tumu = const [];
  List<String> _sonBakilan = const [];
  bool _yukleniyor = true;
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
    final prefs = await SharedPreferences.getInstance();
    final son = prefs.getStringList(_sonBakilanAnahtari) ?? const [];
    final siniflar = await _db.siniflarGetir();
    final kayitlar = <_AramaKaydi>[];
    for (final d in siniflar.docs) {
      final data = d.data() as Map<String, dynamic>?;
      final ad = (data?['ad'] ?? d.id).toString();
      final ogrenciler = await _db.ogrencileriGetir(d.id);
      for (final o in ogrenciler) {
        kayitlar.add(_AramaKaydi(d.id, ad, o));
      }
    }
    kayitlar.sort((a, b) => trKucult(a.ogrenci.ad).compareTo(trKucult(b.ogrenci.ad)));
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Semantics(
          label: 'Öğrenci ara',
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Colors.white, fontSize: 17),
            cursorColor: Colors.white,
            onChanged: (v) => setState(() => _metin = trKucult(v.trim())),
            decoration: InputDecoration(
              hintText: 'Öğrenci ara…',
              hintStyle: TextStyle(color: Colors.white.withAlpha(170)),
              border: InputBorder.none,
              suffixIcon: _metin.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
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
          ? const Center(child: CircularProgressIndicator(color: AppTema.ana))
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
                                return const Padding(
                                  padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                                  child: Text('SON BAKILANLAR',
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.1,
                                          color: AppTema.metinUcuncul)),
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
    final renk = o.isMale ? Colors.blue.shade500 : Colors.pink.shade500;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
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
                  child: Center(
                      child: Text(o.isMale ? '♂' : '♀',
                          style: TextStyle(color: renk, fontSize: 18, fontWeight: FontWeight.w800))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.gorunenAd,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.class_outlined, size: 14, color: AppTema.metinUcuncul),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(k.sinifAd,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, color: AppTema.metinIkincil)),
                    ),
                    // Not içeriği bilerek gösterilmiyor (mahremiyet, 2026-08-28).
                    if (o.rozetler.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.emoji_events_rounded, size: 14, color: AppTema.uyari),
                      const SizedBox(width: 2),
                      Text('${o.rozetler.length}',
                          style: const TextStyle(fontSize: 12, color: AppTema.uyari, fontWeight: FontWeight.w600)),
                    ],
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTema.metinUcuncul),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _bilgi(IconData ikon, String baslik, String aciklama) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ikon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(baslik,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTema.metinIkincil)),
          const SizedBox(height: 6),
          Text(aciklama,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTema.metinUcuncul)),
        ]),
      ),
    );
  }
}
