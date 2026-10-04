import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../tema.dart';
import '../tema_renkleri.dart';
import '../utils/metin.dart';
import '../widgets/kalem_simgeleri.dart';
import '../widgets/cikartma.dart';
import '../widgets/simgeler.dart';
import '../models/ogrenci.dart';
import '../models/kontrol_kalemi.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

/// Günlük yoklama ızgarası: öğrenci × (geldi/yok + günlük kalemler).
/// Tarihli kayıt tutar; "Hepsini Geldi Yap" ile sıfırlanır (Kaydet gerekir).
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
  bool _hata = false;
  DateTime _tarih = DateTime.now();
  List<Ogrenci> _ogrenciler = [];
  /// Öğrenci listesiyle aynı renkler (alfabetik sıra).
  Map<String, Color> _renkler = const {};
  final Map<String, _Kayit> _kayitlar = {};
  /// Yüklendiği andaki kopya: Kaydet yalnız buna göre DEĞİŞEN öğrencileri
  /// yazar. Tüm sınıf yazılınca iki cihazda son kaydeden kazanıyor, diğerinin
  /// işaretlediği devamsızlık siliniyordu (denetim #3 Y2).
  Map<String, _Kayit> _ilkKayitlar = {};
  /// Bu tarih için Firestore'da yoklama dokümanı var mı? Yoksa ilk Kaydet,
  /// değişiklik olmasa da dokümanı oluşturur: herkes geldiğinde ("Hepsini
  /// Geldi Yap" + Kaydet) eskiden "Değişiklik yok." deyip hiçbir şey
  /// yazmıyordu, sınıf kartındaki halka "yoklama alınmadı" kalıyordu.
  bool _kayitVar = false;
  Map<String, _Kayit> _kopyala(Map<String, _Kayit> m) =>
      {for (final e in m.entries) e.key: _Kayit(geldi: e.value.geldi, kalemler: Map.of(e.value.kalemler))};
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
        ..sort((a, b) => trKarsilastir(a.gorunenAd, b.gorunenAd));
      final yoklama = await _db.yoklamaGetir(widget.sinifId, _tarihKey);
      final kayitlarRaw = (yoklama?['kayitlar'] as Map?) ?? {};
      _kayitVar = yoklama != null;

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
        _renkler = AppTema.ogrenciRenkHaritasi(ogrenciler.map((o) => o.id));
        _ilkKayitlar = _kopyala(_kayitlar);
        _hata = false;
        _yukleniyor = false;
      });
    } catch (_) {
      // Okuma hatası "Bu sınıfta öğrenci yok" diye görünüyordu (denetim #3 Y8).
      if (mounted) setState(() { _hata = true; _yukleniyor = false; });
    }
  }

  Future<void> _kaydet() async {
    // Yalnız değişen öğrencilerin değişen alanları; set(merge) haritayı derin
    // birleştirdiği için diğer cihazın kayıtları korunur.
    final kayitlar = <String, dynamic>{};
    for (final o in _ogrenciler) {
      final simdi = _kayitlar[o.id];
      final ilk = _ilkKayitlar[o.id];
      if (simdi == null) continue;
      final fark = <String, dynamic>{};
      if (ilk == null || simdi.geldi != ilk.geldi) fark['geldi'] = simdi.geldi;
      final kalemFark = <String, bool>{};
      simdi.kalemler.forEach((k, v) {
        if (ilk == null || ilk.kalemler[k] != v) kalemFark[k] = v;
      });
      if (kalemFark.isNotEmpty) fark['kalemler'] = kalemFark;
      if (fark.isNotEmpty) kayitlar[o.id] = fark;
    }
    if (kayitlar.isEmpty && _kayitVar) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Değişiklik yok.')));
      return;
    }
    setState(() => _kaydediyor = true);
    try {
      // Sınıf listesindeki "buradaMi" ile aynı kayda işlesin (denetim #4 Y1);
      // bugünün yoklaması için geldi/yok değişenler listeye de yazılır.
      final b = DateTime.now();
      final buGunMu = _tarih.year == b.year && _tarih.month == b.month && _tarih.day == b.day;
      if (buGunMu) {
        for (final e in kayitlar.entries) {
          final g = (e.value as Map)['geldi'];
          if (g is bool) unawaited(_db.buradaMiGuncelle(widget.sinifId, e.key, g).catchError((_) {}));
        }
      }
      await _db
          .yoklamaKaydet(widget.sinifId, _tarihKey, kayitlar)
          // Çevrimdışıyken süresiz bekliyordu, mesaj yoktu (denetim #3 Y8).
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() { _kaydediyor = false; _kayitVar = true; _ilkKayitlar = _kopyala(_kayitlar); });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$_tarihEtiketi yoklaması kaydedildi'),
          backgroundColor: AppTema.basari,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } on TimeoutException {
      // Yazma kuyrukta: kalıcı önbellek açık, bağlantı gelince gidecek.
      if (mounted) {
        setState(() { _kaydediyor = false; _kayitVar = true; _ilkKayitlar = _kopyala(_kayitlar); });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bağlantı yok. Yoklama kaydedildi, internet gelince gönderilecek.'),
          backgroundColor: AppTema.uyari,
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _kaydediyor = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Kaydedilemedi, tekrar dene.'),
          backgroundColor: AppTema.tehlike,
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
          title: const Text('Yoklama sıfırlansın mı?'),
          content: const Text(
              'Bu dersteki tüm "Yok" işaretleri ve eksik kalemler silinip herkes "Geldi" olarak işaretlenecek.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Sıfırla',
                  style: TextStyle(color: ctx.renk.tehlike, fontWeight: FontWeight.w700)),
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

  bool get _kirli => _ogrenciler.any((o) {
        final s = _kayitlar[o.id], i = _ilkKayitlar[o.id];
        if (s == null || i == null) return false;
        if (s.geldi != i.geldi) return true;
        return s.kalemler.entries.any((e) => i.kalemler[e.key] != e.value);
      });

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    final gelenSayisi = _ogrenciler.where((o) => _kayitlar[o.id]?.geldi ?? true).length;
    final bugun = DateTime.now();
    final buGun = _tarih.year == bugun.year && _tarih.month == bugun.month && _tarih.day == bugun.day;

    // Kaydetmeden çıkışta değişiklik sessizce kayboluyordu (denetim #4 Y8).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_kirli) { Navigator.pop(context); return; }
        final secim = await showDialog<String>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Kaydedilmemiş değişiklikler'),
            content: const Text('Yoklamada kaydetmediğin işaretler var.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, 'cik'), child: const Text('Kaydetmeden çık')),
              FilledButton(onPressed: () => Navigator.pop(c, 'kaydet'), child: const Text('Kaydet')),
            ],
          ),
        );
        if (secim == 'kaydet') await _kaydet();
        if (secim != null && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
      backgroundColor: r.sayfa,
      appBar: AppBar(
        backgroundColor: r.sayfa,
        foregroundColor: r.metin,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yoklama${widget.sinifAd != null ? ' • ${widget.sinifAd}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: AppTema.baslikFontu, fontWeight: FontWeight.w600, fontSize: 20)),
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: r.metinIkincil)),
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
          : _hata
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.cloud_off_rounded, size: 56, color: r.bosDurumIkonu),
                    const SizedBox(height: 12),
                    Text('Yoklama yüklenemedi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: r.metinIkincil)),
                    const SizedBox(height: 4),
                    Text('Bağlantını kontrol edip tekrar dene.', style: TextStyle(color: r.metinUcuncul)),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: _yukle, icon: const Icon(Icons.refresh_rounded), label: const Text('Tekrar dene')),
                  ]),
                )
              : _ogrenciler.isEmpty
              ? Center(child: Text('Bu sınıfta öğrenci yok.', style: TextStyle(color: r.metinIkincil)))
              // 1440 px'te isim solda, "Geldi" 1270 px sağdaydı (denetim O5).
              : Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
                  child: Column(children: [
                  // Üst özet + "Tümü Geldi"
                  // Dar ekran ve büyük yazıda bilgi metni hece hece
                  // bölünüyordu (denetim #3): Wrap, sığmazsa düğme alta.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text('Karta dokununca kalemler açılır',
                            style: TextStyle(color: r.metinIkincil, fontSize: 13, fontWeight: FontWeight.w600)),
                        OutlinedButton.icon(
                          onPressed: _tumuGeldi,
                          icon: const Icon(Icons.done_all_rounded, size: 20),
                          label: const Text('Hepsi Geldi'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      // FAB yüksekliği (56) + kenar boşlukları + tampon.
                      // 100 iken Kaydet düğmesi son kartın rozetini örtüyordu.
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _ogrenciler.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              decoration: BoxDecoration(
                color: r.sayfa,
                border: Border(top: BorderSide(color: r.cizgi, width: 1.5)),
              ),
              child: SafeArea(
                // heightFactor olmadan Align alt çubuğu tüm ekrana yayıyordu.
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
                    child: Row(children: [
                      Icon(Icons.groups_rounded, color: r.ikonAna, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          child: Text('$gelenSayisi / ${_ogrenciler.length} geldi',
                              style: const TextStyle(fontFamily: AppTema.baslikFontu, fontWeight: FontWeight.w600, fontSize: 20)),
                        ),
                      ),
                      SertGolgeli(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                          ),
                          onPressed: _kaydediyor ? null : _kaydet,
                          icon: _kaydediyor
                              ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: r.vurguMetin))
                              : const Icon(Icons.save_rounded),
                          label: const Text('Kaydet', style: TextStyle(fontSize: 19)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _ogrenciKarti(Ogrenci o) {
    final r = context.renk;
    final kayit = _kayitlar[o.id] ??= _Kayit(kalemler: {for (final k in _gunlukKalemler) k.id: true});
    final geldi = kayit.geldi;
    // Kalemler yalnızca gelen öğrenci için anlamlı.
    final kalemlerVar = geldi && _gunlukKalemler.isNotEmpty;
    final acik = _acik.contains(o.id);
    final eksikSayisi = kalemlerVar
        ? _gunlukKalemler.where((k) => (kayit.kalemler[k.id] ?? true) == false).length
        : 0;

    return Cikartma(
      kayma: 3,
      kenarKalinligi: 2,
      yaricap: 18,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: kalemlerVar
              ? () => setState(() => acik ? _acik.remove(o.id) : _acik.add(o.id))
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: geldi ? AppTema.ogrenciRengi(o.id, _renkler) : const Color(0xFFE6E2DA),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTema.ana, width: 2),
                ),
                child: Text(basHarfler(o.gorunenAd),
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 14, fontWeight: FontWeight.w600, color: AppTema.ana)),
              ),
              const SizedBox(width: 8),
              CinsiyetSimgesi(o.isMale, boyut: 16),
              const SizedBox(width: 3),
              Expanded(
                // Büyük yazıda ve "eksik" rozetiyle ad "Ayşe Yıl…" diye
                // kesiliyordu, aynı adlılar ayırt edilemiyordu (denetim #4).
                child: Text(o.gorunenAd,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: geldi ? r.metin : r.metinUcuncul)),
              ),
              // Katlıyken de eksik bilgisi kaybolmasın.
              if (!acik && eksikSayisi > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.tehlikeZemin,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: r.tehlike, width: 1.5),
                  ),
                  child: Text('$eksikSayisi eksik',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800, color: r.tehlike)),
                ),
                const SizedBox(width: 8),
              ],
              // 85×36 px'ti, toggle rolü yoktu (denetim O11/O9).
              Semantics(
                // container: yoksa çip satırın (InkWell) düğümüne karışıyor,
                // ekran okuyucu ve otomasyon çipe ayrı ulaşamıyor.
                container: true,
                button: true,
                toggled: geldi,
                label: geldi ? 'Geldi, yok saymak için dokun' : 'Yok, geldi saymak için dokun',
                // excludeSemantics GestureDetector'ın dokunma eylemini de
                // siliyordu; ekran okuyucuda çipe basılamıyordu (denetim #3 O8).
                onTap: () => setState(() => kayit.geldi = !kayit.geldi),
                excludeSemantics: true,
                child: GestureDetector(
                onTap: () => setState(() => kayit.geldi = !kayit.geldi),
                // Geldi: çimen yeşili çıkartma; Yok: mürekkep. Durum yalnız
                // renkle değil ikon ve sözcükle de verilir.
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 84),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: ShapeDecoration(
                    color: geldi ? const Color(0xFF63C77A) : r.murekkepDolgu,
                    shape: const StadiumBorder(side: BorderSide(color: AppTema.ana, width: 2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(geldi ? Icons.check_rounded : Icons.close_rounded,
                        size: 18, color: geldi ? AppTema.ana : r.murekkepUstu),
                    const SizedBox(width: 4),
                    Text(geldi ? 'Geldi' : 'Yok',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: geldi ? AppTema.ana : r.murekkepUstu)),
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
                        child: Icon(Icons.expand_more_rounded,
                            size: 22, color: r.metinUcuncul),
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
                  container: true,
                  button: true,
                  toggled: getirdi,
                  label: '${k.ad} ${getirdi ? "getirdi" : "getirmedi"}',
                  onTap: () => setState(() => kayit.kalemler[k.id] = !getirdi),
                  excludeSemantics: true,
                  child: GestureDetector(
                  onTap: () => setState(() => kayit.kalemler[k.id] = !getirdi),
                  // 41 px'ti (denetim #3): 44.
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: ShapeDecoration(
                      color: getirdi ? r.kart : r.yokZemin,
                      shape: StadiumBorder(side: BorderSide(color: getirdi ? r.kenar : r.yokMetin, width: 2)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      KalemSimgesi(k.ikon, size: 18,
                          color: getirdi ? r.basari : r.tehlike),
                      const SizedBox(width: 6),
                      Text(k.ad, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: getirdi ? r.metin : r.yokMetin)),
                      const SizedBox(width: 4),
                      Icon(getirdi ? Icons.check_rounded : Icons.close_rounded,
                          size: 14, color: getirdi ? r.basari : r.tehlike),
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
