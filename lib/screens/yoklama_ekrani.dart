import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  /// Kontrol kalemi çipleri açık olan öğrenciler. Kartlar varsayılan olarak
  /// tek satır — 30 kişilik sınıfta ekranda 6-7 öğrenci yerine 15+ görünsün.
  final Set<String> _acik = {};

  // Sadece günlük kalemler ızgarada gösterilir (sayaç kalemleri öğrenci kartından).
  List<KontrolKalemi> get _gunlukKalemler =>
      widget.kalemler.where((k) => k.tip == KalemTipi.gunluk).toList();

  /// Firestore doküman anahtarı — ISO kalmalı, sıralanabilir olsun diye.
  String get _tarihKey =>
      '${_tarih.year}-${_tarih.month.toString().padLeft(2, '0')}-${_tarih.day.toString().padLeft(2, '0')}';

  /// Ekranda gösterilen hâli: "23 Ağustos 2026".
  String get _tarihEtiketi => DateFormat('d MMMM yyyy', 'tr').format(_tarih);

  @override
  void initState() {
    super.initState();
    _db = FirestoreService(uid: AuthService().uid);
    _yukle();
  }

  Future<void> _yukle() async {
    setState(() => _yukleniyor = true);
    try {
      // Akış açıp ilk olayı beklemek yerine tek seferlik okuma — dinleyici
      // kurup hemen iptal etmek gereksiz maliyet.
      final ogrenciler = (await _db.ogrencileriGetir(widget.sinifId))
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
          content: Text('$_tarihEtiketi yoklaması kaydedildi'),
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

  /// Listede işaretlenmiş bir "Yok" ya da eksik kalem var mı?
  /// Varsa sıfırlamak veri siliyor demektir; yoksa zaten temiz, sormaya gerek yok.
  bool get _isaretVar => _ogrenciler.any((o) {
        final k = _kayitlar[o.id];
        if (k == null) return false;
        return !k.geldi || k.kalemler.values.any((v) => v == false);
      });

  Future<void> _tumuGeldi() async {
    // Eskiden tek dokunuşla, onay sormadan o günün tüm yoklaması siliniyordu.
    if (_isaretVar) {
      final onay = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Yoklama sıfırlansın mı?'),
          content: const Text(
              'Bu dersteki tüm "Yok" işaretleri ve eksik kalemler silinip herkes "Geldi" olarak işaretlenecek.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sıfırla',
                  style: TextStyle(color: AppTema.tehlike, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (onay != true) return;
    }
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yoklama${widget.sinifAd != null ? ' • ${widget.sinifAd}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Semantics(
              button: true,
              label: 'Tarih: $_tarihEtiketi, değiştirmek için dokun',
              excludeSemantics: true,
              child: GestureDetector(
              onTap: _tarihSec,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: Text(buGun ? 'Bugün — $_tarihEtiketi' : _tarihEtiketi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more_rounded, size: 16),
              ]),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today_rounded, size: 20), tooltip: 'Tarih seç', onPressed: _tarihSec),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _ogrenciler.isEmpty
              ? const Center(child: Text('Bu sınıfta öğrenci yok.', style: TextStyle(color: AppTema.metinIkincil)))
              // 1440 px'te isim solda, "Geldi" 1270 px sağdaydı (denetim O5).
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
                  child: Column(children: [
                  // Üst özet + "Tümü Geldi"
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, color: AppTema.metinUcuncul, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Karta dokununca kalemler açılır',
                            style: TextStyle(color: AppTema.metinIkincil, fontSize: 13)),
                      ),
                      TextButton.icon(
                        onPressed: _tumuGeldi,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Yeni Ders / Tümü Geldi'),
                        // Yıkıcı bir toplu işlem — sıradan bir metin düğmesi
                        // gibi görünmesin.
                        style: TextButton.styleFrom(foregroundColor: AppTema.uyari),
                      ),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      // FAB yüksekliği (56) + kenar boşlukları + tampon.
                      // 100 iken Kaydet düğmesi son kartın rozetini örtüyordu.
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: _ogrenciler.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ogrenciKarti(_ogrenciler[i]),
                    ),
                  ),
                ]),
                  ),
                ),
      // Yüzen Kaydet düğmesi "Geldi" sütununun tam üstünde duruyordu
      // (denetim D6); öğrenci listesindeki gibi sabit alt çubuk + sayaç.
      bottomNavigationBar: _yukleniyor || _ogrenciler.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                // heightFactor olmadan Align alt çubuğu tüm ekrana yayıyordu.
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
                    child: Row(children: [
                      const Icon(Icons.groups_rounded, color: AppTema.ana, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text('$gelenSayisi / ${_ogrenciler.length} geldi',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTema.vurgu,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: _kaydediyor ? null : _kaydet,
                        icon: _kaydediyor
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded),
                        label: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _ogrenciKarti(Ogrenci o) {
    final kayit = _kayitlar[o.id] ??= _Kayit(kalemler: {for (final k in _gunlukKalemler) k.id: true});
    final geldi = kayit.geldi;
    // Kalemler yalnızca gelen öğrenci için anlamlı.
    final kalemlerVar = geldi && _gunlukKalemler.isNotEmpty;
    final acik = _acik.contains(o.id);
    final eksikSayisi = kalemlerVar
        ? _gunlukKalemler.where((k) => (kayit.kalemler[k.id] ?? true) == false).length
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: geldi ? Colors.green : Colors.red.shade300, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: kalemlerVar
              ? () => setState(() => acik ? _acik.remove(o.id) : _acik.add(o.id))
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(children: [
              Expanded(
                child: Text(o.gorunenAd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              // Katlıyken de eksik bilgisi kaybolmasın.
              if (!acik && eksikSayisi > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTema.tehlikeZemin,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$eksikSayisi eksik',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppTema.tehlike)),
                ),
                const SizedBox(width: 8),
              ],
              // 85×36 px'ti, toggle rolü yoktu (denetim O11/O9).
              Semantics(
                button: true,
                toggled: geldi,
                label: geldi ? 'Geldi, yok saymak için dokun' : 'Yok, geldi saymak için dokun',
                excludeSemantics: true,
                child: GestureDetector(
                onTap: () => setState(() => kayit.geldi = !kayit.geldi),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: geldi ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: geldi ? Colors.green.shade200 : Colors.red.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(geldi ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        size: 16, color: geldi ? AppTema.basari : Colors.red),
                    const SizedBox(width: 6),
                    Text(geldi ? 'Geldi' : 'Yok',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: geldi ? AppTema.basari : Colors.red.shade700)),
                  ]),
                ),
                ),
              ),
              // Kalemi olmayan kartta ok gösterme — açılacak bir şey yok.
              SizedBox(
                width: 32,
                child: kalemlerVar
                    ? AnimatedRotation(
                        turns: acik ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.expand_more_rounded,
                            size: 22, color: AppTema.metinUcuncul),
                      )
                    : null,
              ),
            ]),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: acik && kalemlerVar
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _gunlukKalemler.map((k) {
                final getirdi = kayit.kalemler[k.id] ?? true;
                return Semantics(
                  button: true,
                  toggled: getirdi,
                  label: '${k.ad} ${getirdi ? "getirdi" : "getirmedi"}',
                  excludeSemantics: true,
                  child: GestureDetector(
                  onTap: () => setState(() => kayit.kalemler[k.id] = !getirdi),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: getirdi ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: getirdi ? Colors.green.shade200 : Colors.red.shade200),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(kalemIkonu(k.ikon), size: 15,
                          color: getirdi ? AppTema.basari : AppTema.tehlike),
                      const SizedBox(width: 6),
                      Text(k.ad, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: getirdi ? AppTema.basari : Colors.red.shade700)),
                      const SizedBox(width: 4),
                      Icon(getirdi ? Icons.check_rounded : Icons.close_rounded,
                          size: 14, color: getirdi ? AppTema.basari : AppTema.tehlike),
                    ]),
                  ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ]),
    );
  }
}
