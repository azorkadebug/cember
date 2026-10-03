import 'package:flutter/material.dart';

import '../models/ogrenci.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../tema.dart';
import '../utils/egitim_yili.dart';
import '../utils/metin.dart';
import '../widgets/simgeler.dart';
import '../widgets/kalem_simgeleri.dart';

/// Geçmiş yılların sınıflarından öğrenci seçip bu sınıfa aktarır.
///
/// Şubeler her yıl karıştığı için sınıf toptan taşınmıyor: öğretmen 6A'dan
/// üç, 6C'den dört öğrenciyi seçip 7E'ye ekleyebiliyor. Aktarılan kayıt
/// yenidir; eski sınıftaki kayıt arşivde olduğu gibi kalır.
class GecenYildanEkleEkrani extends StatefulWidget {
  final String hedefSinifId;
  final String hedefSinifAd;
  const GecenYildanEkleEkrani({super.key, required this.hedefSinifId, required this.hedefSinifAd});

  @override
  State<GecenYildanEkleEkrani> createState() => _GecenYildanEkleEkraniState();
}

class _EskiSinif {
  final String id, ad, yil;
  final List<Ogrenci> ogrenciler;
  _EskiSinif(this.id, this.ad, this.yil, this.ogrenciler);
}

class _GecenYildanEkleEkraniState extends State<GecenYildanEkleEkrani> {
  late final FirestoreService _db = FirestoreService(uid: AuthService().uid);
  final _aramaC = TextEditingController();
  List<_EskiSinif> _siniflar = [];
  Set<String> _mevcutAdlar = {};
  /// Seçim anahtarı: "sınıfId/öğrenciId".
  final Set<String> _secili = {};
  bool _yukleniyor = true;
  bool _hata = false;
  bool _kaydediyor = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _aramaC.dispose();
    super.dispose();
  }

  Future<void> _yukle() async {
    setState(() { _yukleniyor = true; _hata = false; });
    try {
      final simdiki = EgitimYili.simdiki;
      final snap = await _db.siniflarGetir();
      final eskiler = snap.docs.where((d) {
        final yil = EgitimYili.sinifin(d.data() as Map<String, dynamic>?);
        return yil.compareTo(simdiki) < 0;
      }).toList();
      final sonuc = await Future.wait(eskiler.map((d) async {
        final data = d.data() as Map<String, dynamic>?;
        final ogrenciler = await _db.ogrencileriGetir(d.id)
          ..sort((a, b) => trKarsilastir(a.ad, b.ad));
        return _EskiSinif(d.id, (data?['ad'] ?? d.id).toString(), EgitimYili.sinifin(data), ogrenciler);
      }));
      // En yeni yıl üstte, yıl içinde sınıf adına göre.
      sonuc.sort((a, b) {
        final y = b.yil.compareTo(a.yil);
        return y != 0 ? y : trKarsilastir(a.ad, b.ad);
      });
      final mevcut = await _db.mevcutOgrenciAdlari(widget.hedefSinifId);
      if (!mounted) return;
      setState(() {
        _siniflar = sonuc.where((s) => s.ogrenciler.isNotEmpty).toList();
        _mevcutAdlar = mevcut.map(trKucult).toSet();
        _yukleniyor = false;
      });
    } catch (_) {
      if (mounted) setState(() { _hata = true; _yukleniyor = false; });
    }
  }

  bool _sinifta(Ogrenci o) => _mevcutAdlar.contains(trKucult(o.ad.trim()));

  Future<void> _aktar() async {
    if (_secili.isEmpty || _kaydediyor) return;
    setState(() => _kaydediyor = true);
    final kopyalar = <Ogrenci>[];
    for (final s in _siniflar) {
      for (final o in s.ogrenciler) {
        if (_secili.contains('${s.id}/${o.id}')) {
          kopyalar.add(o.yeniYilKopyasi(sinifId: s.id, sinifAd: s.ad, egitimYili: s.yil));
        }
      }
    }
    try {
      await _db.ogrencilerTopluEkle(widget.hedefSinifId, kopyalar);
      if (mounted) Navigator.pop(context, kopyalar.length);
    } catch (e) {
      if (!mounted) return;
      setState(() => _kaydediyor = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Öğrenciler eklenemedi. ${FirestoreService.hataMesaji(e)}"),
        backgroundColor: AppTema.tehlike,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Geçen Yıldan Ekle", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text("Hedef: ${widget.hedefSinifAd}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
        ]),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
          child: _govde(),
        ),
      ),
      bottomNavigationBar: _yukleniyor || _hata || _siniflar.isEmpty ? null : _altCubuk(),
    );
  }

  Widget _govde() {
    if (_yukleniyor) return const Center(child: CircularProgressIndicator(color: AppTema.vurgu));
    if (_hata) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Geçmiş sınıflar okunamadı.", style: TextStyle(color: AppTema.tehlike)),
          const SizedBox(height: 8),
          TextButton(onPressed: _yukle, child: const Text("Tekrar Dene")),
        ]),
      );
    }
    if (_siniflar.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text("Geçmiş yıllarda öğrencili sınıf yok",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTema.metinIkincil)),
            const SizedBox(height: 6),
            const Text("Geçen yılın sınıfları burada görünür. Bir sınıfı geçmiş yıla taşımak için Sınıflarım'da karta sola kaydır.",
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppTema.metinUcuncul)),
          ]),
        ),
      );
    }
    final q = trKucult(_aramaC.text.trim());
    final bolumler = <Widget>[];
    for (final s in _siniflar) {
      final liste = q.isEmpty ? s.ogrenciler : s.ogrenciler.where((o) => trKucult(o.ad).contains(q)).toList();
      if (liste.isEmpty) continue;
      final secilebilir = liste.where((o) => !_sinifta(o)).toList();
      final hepsiSecili = secilebilir.isNotEmpty && secilebilir.every((o) => _secili.contains('${s.id}/${o.id}'));
      bolumler.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 0, 4),
        child: Row(children: [
          Expanded(
            child: Text("${s.ad.toUpperCase()}  ·  ${s.yil}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppTema.metinUcuncul)),
          ),
          if (secilebilir.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                for (final o in secilebilir) {
                  final k = '${s.id}/${o.id}';
                  hepsiSecili ? _secili.remove(k) : _secili.add(k);
                }
              }),
              child: Text(hepsiSecili ? "Seçimi Kaldır" : "Tümünü Seç"),
            ),
        ]),
      ));
      bolumler.add(Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (final o in liste) _satir(s, o),
        ]),
      ));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TextField(
          controller: _aramaC,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: "Öğrenci ara...",
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 8),
        const Text("Ad, cinsiyet, beceri puanı, element ve sağlık notları taşınır. Yoklama, sayaçlar, notlar ve rozetler yeni yılda sıfırdan başlar.",
            style: TextStyle(fontSize: 12, color: AppTema.metinIkincil)),
        if (bolumler.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(child: Text("Aramaya uyan öğrenci yok.", style: TextStyle(color: AppTema.metinUcuncul))),
          ),
        ...bolumler,
      ],
    );
  }

  Widget _satir(_EskiSinif s, Ogrenci o) {
    final k = '${s.id}/${o.id}';
    final sinifta = _sinifta(o);
    return CheckboxListTile(
      value: sinifta || _secili.contains(k),
      onChanged: sinifta ? null : (v) => setState(() => v == true ? _secili.add(k) : _secili.remove(k)),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppTema.vurgu,
      dense: true,
      title: Row(children: [
        CinsiyetSimgesi(o.isMale, boyut: 16),
        const SizedBox(width: 6),
        Flexible(child: Text(o.gorunenAd, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: sinifta ? AppTema.metinUcuncul : Colors.black87))),
        if (o.saglikNotlari.isNotEmpty) ...[
          const SizedBox(width: 6),
          const OzelSimgeWidget(OzelSimge.saglik, size: 16, color: Colors.teal),
        ],
      ]),
      subtitle: sinifta
          ? const Text("Zaten bu sınıfta", style: TextStyle(fontSize: 12, color: AppTema.metinUcuncul))
          : null,
    );
  }

  Widget _altCubuk() {
    final n = _secili.length;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: Row(children: [
          Expanded(
            child: Text(n == 0 ? "Öğrenci seç" : "$n öğrenci seçildi",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTema.anaKoyu)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTema.vurgu,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 2,
            ),
            onPressed: n == 0 || _kaydediyor ? null : _aktar,
            icon: _kaydediyor
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.group_add_rounded),
            label: Text(n == 0 ? "Ekle" : "$n Öğrenci Ekle", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
