import 'package:flutter/material.dart';
import '../tema.dart';
import '../models/ogrenci.dart';
import '../models/kontrol_kalemi.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

/// Günlük yoklama ızgarası: öğrenci × (geldi/yok + günlük kalemler).
/// Tarihli kayıt tutar; "Yeni Ders / Tümü Geldi" ile sıfırlanır.
class YoklamaEkrani extends StatefulWidget {
  final String sinifId;
  final String? sinifAd;
  final List<KontrolKalemi> kalemler;
  const YoklamaEkrani({super.key, required this.sinifId, this.sinifAd, required this.kalemler});

  @override
  State<YoklamaEkrani> createState() => _YoklamaEkraniState();
}

class _Kayit {
  bool geldi;
  Map<String, bool> kalemler; // kalemId -> getirdi mi (true=getirdi/var)
  _Kayit({this.geldi = true, Map<String, bool>? kalemler}) : kalemler = kalemler ?? {};
}

class _YoklamaEkraniState extends State<YoklamaEkrani> {
  late final FirestoreService _db;
  bool _yukleniyor = true;
  bool _kaydediyor = false;
  DateTime _tarih = DateTime.now();
  List<Ogrenci> _ogrenciler = [];
  final Map<String, _Kayit> _kayitlar = {};

  // Sadece günlük kalemler ızgarada gösterilir (sayaç kalemleri öğrenci kartından).
  List<KontrolKalemi> get _gunlukKalemler =>
      widget.kalemler.where((k) => k.tip == KalemTipi.gunluk).toList();

  String get _tarihKey =>
      '${_tarih.year}-${_tarih.month.toString().padLeft(2, '0')}-${_tarih.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _db = FirestoreService(uid: AuthService().uid);
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      final snap = await _db.ogrencilerStream(widget.sinifId).first;
      final ogrenciler = snap.docs
          .map((d) => Ogrenci.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.gorunenAd.toLowerCase().compareTo(b.gorunenAd.toLowerCase()));
      final yoklama = await _db.yoklamaGetir(widget.sinifId, _tarihKey);
      final kayitlarRaw = (yoklama?['kayitlar'] as Map?) ?? {};

      _kayitlar.clear();
      for (final o in ogrenciler) {
        final r = kayitlarRaw[o.id];
        if (r is Map) {
          _kayitlar[o.id] = _Kayit(
            geldi: r['geldi'] ?? true,
            kalemler: {
              for (final k in _gunlukKalemler)
                k.id: (r['kalemler'] as Map?)?[k.id] ?? true,
            },
          );
        } else {
          // Kaydı olmayan öğrenci: varsayılan geldi + hepsi getirdi.
          _kayitlar[o.id] = _Kayit(
            geldi: true,
            kalemler: {for (final k in _gunlukKalemler) k.id: true},
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _ogrenciler = ogrenciler;
        _yukleniyor = false;
      });
    } catch (_) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediyor = true);
    final kayitlar = {
      for (final o in _ogrenciler)
        o.id: {
          'geldi': _kayitlar[o.id]?.geldi ?? true,
          'kalemler': _kayitlar[o.id]?.kalemler ?? {},
        },
    };
    try {
      await _db.yoklamaKaydet(widget.sinifId, _tarihKey, kayitlar);
      if (mounted) {
        setState(() => _kaydediyor = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$_tarihKey yoklaması kaydedildi'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _kaydediyor = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Kaydedilemedi, tekrar deneyin.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _tumuGeldi() {
    setState(() {
      for (final o in _ogrenciler) {
        _kayitlar[o.id] = _Kayit(
          geldi: true,
          kalemler: {for (final k in _gunlukKalemler) k.id: true},
        );
      }
    });
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _tarih,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
    );
    if (secilen != null) {
      setState(() => _tarih = secilen);
      await _yukle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gelenSayisi = _ogrenciler.where((o) => _kayitlar[o.id]?.geldi ?? true).length;
    final bugun = DateTime.now();
    final buGun = _tarih.year == bugun.year && _tarih.month == bugun.month && _tarih.day == bugun.day;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Yoklama${widget.sinifAd != null ? ' • ${widget.sinifAd}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          GestureDetector(
            onTap: _tarihSec,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(buGun ? 'Bugün ($_tarihKey)' : _tarihKey,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more_rounded, size: 16),
            ]),
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today_rounded, size: 20), onPressed: _tarihSec),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _ogrenciler.isEmpty
              ? Center(child: Text('Bu sınıfta öğrenci yok.', style: TextStyle(color: Colors.grey.shade500)))
              : Column(children: [
                  // Üst özet + "Tümü Geldi"
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(children: [
                      Icon(Icons.groups_rounded, color: AppTema.ana, size: 20),
                      const SizedBox(width: 8),
                      Text('$gelenSayisi / ${_ogrenciler.length} geldi',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _tumuGeldi,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Yeni Ders / Tümü Geldi'),
                        style: TextButton.styleFrom(foregroundColor: AppTema.ana),
                      ),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      itemCount: _ogrenciler.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ogrenciKarti(_ogrenciler[i]),
                    ),
                  ),
                ]),
      floatingActionButton: _yukleniyor || _ogrenciler.isEmpty
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppTema.ana,
              foregroundColor: Colors.white,
              onPressed: _kaydediyor ? null : _kaydet,
              icon: _kaydediyor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_rounded),
              label: const Text('Kaydet'),
            ),
    );
  }

  Widget _ogrenciKarti(Ogrenci o) {
    final kayit = _kayitlar[o.id] ??= _Kayit(kalemler: {for (final k in _gunlukKalemler) k.id: true});
    final geldi = kayit.geldi;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: geldi ? Colors.green : Colors.red.shade300, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(o.gorunenAd, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
          GestureDetector(
            onTap: () => setState(() => kayit.geldi = !kayit.geldi),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: geldi ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(geldi ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 16, color: geldi ? Colors.green : Colors.red),
                const SizedBox(width: 6),
                Text(geldi ? 'Geldi' : 'Yok',
                    style: TextStyle(fontWeight: FontWeight.w700, color: geldi ? Colors.green.shade800 : Colors.red.shade700)),
              ]),
            ),
          ),
        ]),
        if (geldi && _gunlukKalemler.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _gunlukKalemler.map((k) {
              final getirdi = kayit.kalemler[k.id] ?? true;
              return GestureDetector(
                onTap: () => setState(() => kayit.kalemler[k.id] = !getirdi),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: getirdi ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: getirdi ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(kalemIkonu(k.ikon), size: 15, color: getirdi ? Colors.green.shade700 : Colors.red.shade400),
                    const SizedBox(width: 6),
                    Text(k.ad, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: getirdi ? Colors.green.shade800 : Colors.red.shade700)),
                    const SizedBox(width: 4),
                    Icon(getirdi ? Icons.check_rounded : Icons.close_rounded,
                        size: 14, color: getirdi ? Colors.green : Colors.red),
                  ]),
                ),
              );
            }).toList(),
          ),
        ],
      ]),
    );
  }
}
