import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ogrenci.dart';
import '../tema.dart';
import '../tema_renkleri.dart';
import '../utils/metin.dart';
import '../widgets/cikartma.dart';
import '../widgets/sus_daireleri.dart';

/// Sınıftan rastgele öğrenci seçer (Sabri, 2026-10-05).
///
/// Yalnız gelenler kuraya girer. "Tekrar çıkmasın" açıkken aynı gün çekilen
/// öğrenci, herkes bir kez çıkana kadar yeniden çıkmaz; kayıt yalnız bu
/// cihazda (SharedPreferences), veritabanına yazılmaz.
class KuraEkrani extends StatefulWidget {
  final String sinifId;
  final String? sinifAd;
  final List<Ogrenci> ogrenciler;
  final Map<String, Color> renkler;
  const KuraEkrani({
    super.key,
    required this.sinifId,
    this.sinifAd,
    required this.ogrenciler,
    required this.renkler,
  });

  @override
  State<KuraEkrani> createState() => _KuraEkraniState();
}

class _KuraEkraniState extends State<KuraEkrani> {
  final _rnd = Random();
  Set<String> _cekilenler = {};
  bool _tekrarYok = true;
  Ogrenci? _gosterilen;
  bool _donuyor = false;
  bool _bitti = false; // son öğrenci yerine oturdu mu (büyüme animasyonu)
  Timer? _zamanlayici;

  List<Ogrenci> get _gelenler => widget.ogrenciler.where((o) => o.buradaMi).toList();
  String get _anahtar => 'kura_${widget.sinifId}';

  static String _bugun() {
    final b = DateTime.now();
    return '${b.year}-${b.month}-${b.day}';
  }

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    super.dispose();
  }

  Future<void> _yukle() async {
    try {
      final p = await SharedPreferences.getInstance();
      _tekrarYok = p.getBool('kura_tekrar_yok') ?? true;
      final ham = p.getString(_anahtar);
      if (ham != null) {
        final m = jsonDecode(ham) as Map<String, dynamic>;
        if (m['tarih'] == _bugun()) _cekilenler = {...(m['cekilenler'] as List).cast<String>()};
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _kaydet() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_anahtar, jsonEncode({'tarih': _bugun(), 'cekilenler': _cekilenler.toList()}));
      await p.setBool('kura_tekrar_yok', _tekrarYok);
    } catch (_) {}
  }

  List<Ogrenci> get _havuz {
    final gelenler = _gelenler;
    if (!_tekrarYok) return gelenler;
    final kalan = gelenler.where((o) => !_cekilenler.contains(o.id)).toList();
    return kalan;
  }

  void _cek() {
    if (_donuyor) return;
    final gelenler = _gelenler;
    if (gelenler.isEmpty) return;
    var havuz = _havuz;
    if (havuz.isEmpty) {
      // Herkes çıktı: tur baştan.
      _cekilenler.clear();
      havuz = gelenler;
    }
    final secilen = havuz[_rnd.nextInt(havuz.length)];
    _cekilenler.add(secilen.id);
    unawaited(_kaydet());

    if (MediaQuery.of(context).disableAnimations || gelenler.length == 1) {
      setState(() { _gosterilen = secilen; _bitti = true; });
      return;
    }
    // Slot makinesi: adlar hızla döner, giderek yavaşlar, seçilende durur.
    setState(() { _donuyor = true; _bitti = false; });
    var adim = 0;
    const toplam = 22;
    void sonraki() {
      if (!mounted) return;
      adim++;
      if (adim >= toplam) {
        setState(() { _gosterilen = secilen; _donuyor = false; _bitti = true; });
        return;
      }
      Ogrenci aday;
      do {
        aday = gelenler[_rnd.nextInt(gelenler.length)];
      } while (gelenler.length > 1 && aday.id == _gosterilen?.id);
      setState(() => _gosterilen = aday);
      final t = adim / toplam;
      _zamanlayici = Timer(Duration(milliseconds: (45 + 260 * t * t * t).round()), sonraki);
    }
    sonraki();
  }

  void _sifirla() {
    setState(() { _cekilenler.clear(); _gosterilen = null; _bitti = false; });
    unawaited(_kaydet());
  }

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    final gelenler = _gelenler;
    final cekilenSayisi = gelenler.where((o) => _cekilenler.contains(o.id)).length;
    final o = _gosterilen;
    final renk = o == null ? const Color(0xFFFFD84D) : AppTema.ogrenciRengi(o.id, widget.renkler);

    return Scaffold(
      backgroundColor: r.sayfa,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: r.metin,
        title: Text(widget.sinifAd == null ? 'Kura' : 'Kura · ${widget.sinifAd}', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Stack(children: [
        const Positioned.fill(
          child: SusDaireleri(daireler: [
            SusDaire(Offset(0.98, 0.06), 200, Color(0x99FFD84D), genlik: 14),
            SusDaire(Offset(0.02, 0.55), 140, Color(0x664DD9C6), genlik: 12),
            SusDaire(Offset(0.92, 0.86), 120, Color(0x66FF6B57)),
            SusDaire(Offset(0.12, 0.12), 36, Color(0x994FA3F7), genlik: 8),
          ]),
        ),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(children: [
                  Expanded(
                    child: Center(
                      child: gelenler.isEmpty
                          ? Text('Kuraya girecek öğrenci yok.\nYoklamada herkes "yok" görünüyor ya da sınıf boş.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: r.metinIkincil))
                          : _sahne(o, renk),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: SertGolgeli(
                      child: FilledButton.icon(
                        onPressed: gelenler.isEmpty || _donuyor ? null : _cek,
                        icon: const Icon(Icons.casino_rounded, size: 26),
                        label: Text(o == null ? 'Kura Çek' : 'Tekrar Çek'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(60),
                          textStyle: const TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: Text(
                        _tekrarYok
                            ? '$cekilenSayisi / ${gelenler.length} çekildi'
                            : '${gelenler.length} öğrenci kurada',
                        style: TextStyle(fontWeight: FontWeight.w700, color: r.metinIkincil),
                      ),
                    ),
                    if (_tekrarYok && cekilenSayisi > 0)
                      TextButton(onPressed: _donuyor ? null : _sifirla, child: const Text('Sıfırla')),
                  ]),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Çıkan öğrenci tekrar çıkmasın', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Herkes bir kez çıkınca baştan başlar'),
                    value: _tekrarYok,
                    onChanged: _donuyor ? null : (v) { setState(() => _tekrarYok = v); unawaited(_kaydet()); },
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sahne(Ogrenci? o, Color renk) {
    final r = context.renk;
    if (o == null) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 120, height: 120,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: const Color(0xFFFFD84D),
            shape: const CircleBorder(side: BorderSide(color: AppTema.ana, width: 3)),
            shadows: [BoxShadow(color: r.sertGolge, offset: const Offset(5, 5))],
          ),
          child: const Text('?', style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 64, fontWeight: FontWeight.w700, color: AppTema.ana)),
        ),
        const SizedBox(height: 20),
        Text('Kim çıkacak?',
            style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 30, fontWeight: FontWeight.w600, color: r.metin)),
      ]);
    }
    return Semantics(
      liveRegion: true,
      label: _donuyor ? 'Kura çekiliyor' : 'Çıkan: ${o.gorunenAd}',
      excludeSemantics: true,
      child: AnimatedScale(
        scale: _bitti ? 1.08 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.elasticOut,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 132, height: 132,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: renk,
              shape: const CircleBorder(side: BorderSide(color: AppTema.ana, width: 3)),
              shadows: [BoxShadow(color: r.sertGolge, offset: const Offset(5, 5))],
            ),
            child: Text(basHarfler(o.gorunenAd),
                textScaler: TextScaler.noScaling,
                style: const TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 52, fontWeight: FontWeight.w600, color: AppTema.ana)),
          ),
          const SizedBox(height: 22),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(o.gorunenAd,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: AppTema.baslikFontu,
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: _donuyor ? r.metinIkincil : r.metin)),
          ),
        ]),
      ),
    );
  }
}
