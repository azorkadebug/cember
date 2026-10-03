import '../tema.dart';
import '../tema_renkleri.dart';
import '../widgets/cikartma.dart';
import '../widgets/kalem_simgeleri.dart';
import '../widgets/simgeler.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/girdi.dart';
import '../models/ogrenci.dart';
import '../services/mac_durumu.dart';
import '../services/demo_modu.dart';
import '../widgets/yardim_diyalogu.dart';

class TakimBilgi {
  final String isim;
  final String renkAdi;
  final Color renk;
  final List<Ogrenci> oyuncular;
  final Ogrenci? kaptan;
  int skor;

  TakimBilgi({
    required this.isim,
    required this.renkAdi,
    required this.renk,
    required this.oyuncular,
    this.kaptan,
    this.skor = 0,
  });
}

class _SuruklenenOgrenci {
  final Ogrenci ogrenci;
  final int kaynakTakimIndex;
  _SuruklenenOgrenci({required this.ogrenci, required this.kaynakTakimIndex});
}

class _Ceza {
  final int takimIndex;
  final Ogrenci oyuncu;
  int kalanSaniye;
  late Timer timer;

  _Ceza({required this.takimIndex, required this.oyuncu})
      : kalanSaniye = 120,
        bitis = DateTime.now().add(const Duration(seconds: 120));
  final DateTime bitis;
}

class SkorEkrani extends StatefulWidget {
  final List<TakimBilgi> takimlar;
  const SkorEkrani({super.key, required this.takimlar});

  @override
  State<SkorEkrani> createState() => _SkorEkraniState();
}

class _SkorEkraniState extends State<SkorEkrani> with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  int _kalanSaniye = 0;
  /// Süre geri sayımı tik saymaz, bitiş anına bağlıdır: iOS uygulamayı
  /// arka plana alınca Timer donuyor, kaçırılan saniyeler geri gelmiyordu
  /// (denetim #4 Y4). Kalan = bitiş − şimdi.
  DateTime? _bitis;
  int _toplamSaniye = 0;
  bool _timerCalisiyor = false;
  bool _timerBitti = false;
  late AnimationController _pulseCtrl;
  final List<_Ceza> _cezalar = [];
  /// Sunum modu: tablet/projeksiyon için tam ekran, devasa skor, dokununca
  /// +1 (Sabri'nin listesi #1, 2026-09-05). Ekran uyanık tutulur.
  bool _sunum = false;
  /// Süre bitti uyarısı (tam ekran kırmızı, titreşim, düdük) — iki modda da.
  bool _alarmGoster = false;
  final _ses = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    // Düdük sessiz modda da çalsın (playback) ama Bluetooth'tan çalan müziği
    // kesmesin: duckOthers müziği kısar, düdük bitince geri getirir
    // (denetim #4 Y5). Web'de desteklenmez, sessizce geçilir.
    unawaited(AudioPlayer.global.setAudioContext(AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.duckOthers},
      ),
      android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.gainTransientMayDuck),
    )).catchError((_) {}));
    _durumGeriYukle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Arka plandan dönünce süreyi hemen duvar saatine göre tazele; bittiyse
    // alarmı bir kez çal.
    if (state == AppLifecycleState.resumed && _timerCalisiyor) {
      _tik();
    }
  }

  /// Süreyi bitiş anından hesaplar; bitince alarmı çalar.
  void _tik() {
    if (_bitis == null) return;
    final kalan = (_bitis!.difference(DateTime.now()).inMilliseconds / 1000).ceil();
    setState(() {
      _kalanSaniye = kalan < 0 ? 0 : kalan;
      if (_kalanSaniye <= 10 && _kalanSaniye > 0 && !_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
      if (_kalanSaniye <= 0) {
        _kalanSaniye = 0; _timerCalisiyor = false; _timerBitti = true; _bitis = null;
        _timer?.cancel(); _pulseCtrl.reset();
        _sureBittiAlarmi();
      }
    });
  }

  void _durumGeriYukle() {
    final mac = MacDurumu();
    if (mac.toplamSaniye > 0) {
      _toplamSaniye = mac.toplamSaniye;
      _kalanSaniye = mac.kalanSaniyeHesapla();
      _timerBitti = mac.timerBitti;
      // Timer çalışıyordu ve henüz bitmemişse devam ettir
      if (mac.timerCalisiyor && !_timerBitti && _kalanSaniye > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _baslaDurdur());
      }
    }
  }

  @override
  void dispose() {
    // Çıkarken durumu kaydet
    MacDurumu().durumKaydet(
      kalanSn: _kalanSaniye,
      toplamSn: _toplamSaniye,
      calisiyor: _timerCalisiyor,
      bitti: _timerBitti,
    );
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulseCtrl.dispose();
    for (var c in _cezalar) { c.timer.cancel(); }
    _ses.dispose();
    if (_sunum) unawaited(WakelockPlus.disable());
    super.dispose();
  }

  void _sureAyarla(int saniye) {
    _timer?.cancel();
    setState(() { _kalanSaniye = saniye; _toplamSaniye = saniye; _timerCalisiyor = false; _timerBitti = false; });
    _pulseCtrl.reset();
  }

  void _baslaDurdur() {
    if (_timerBitti) return;
    if (_timerCalisiyor) {
      _timer?.cancel();
      _pulseCtrl.reset();
      _bitis = null;
      setState(() => _timerCalisiyor = false);
    } else {
      // Süre seçilmeden BAŞLAT'a basınca burada sessizce return ediliyordu:
      // düğme etkin görünüyor, basılıyor, hiçbir şey olmuyordu. Artık
      // varsayılan 1 dakikayla başlıyor.
      if (_kalanSaniye <= 0) {
        _toplamSaniye = 60;
        _kalanSaniye = 60;
        _timerBitti = false;
      }
      // Nabız animasyonu süre boyunca değil yalnız son 10 sn'de: 60 fps
      // sürekli çizim 10 dk'lık maçta tableti ısıtıyordu (denetim #3 O1).
      if (_kalanSaniye <= 10) _pulseCtrl.repeat(reverse: true);
      _bitis = DateTime.now().add(Duration(seconds: _kalanSaniye));
      setState(() => _timerCalisiyor = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tik());
    }
  }

  void _sifirla() {
    _timer?.cancel(); _pulseCtrl.reset();
    setState(() { _kalanSaniye = _toplamSaniye; _timerCalisiyor = false; _timerBitti = false; });
  }

  String _sureFmt(int saniye) {
    final m = saniye ~/ 60;
    final s = saniye % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  /// Süre bitince: tam ekran kırmızı katman + titreşim + kısa düdük.
  /// Eskiden yalnız sayaç kırmızıya dönüyordu; salonda kimse fark etmiyordu.
  void _sureBittiAlarmi() {
    setState(() => _alarmGoster = true);
    _pulseCtrl.repeat(reverse: true);
    unawaited(_ses.play(AssetSource('sounds/sure_bitti.wav')).catchError((_) {}));
    unawaited(() async {
      for (var i = 0; i < 3; i++) {
        unawaited(HapticFeedback.heavyImpact());
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }());
  }

  void _sunumuAcKapa() {
    setState(() => _sunum = !_sunum);
    unawaited(_sunum ? WakelockPlus.enable() : WakelockPlus.disable());
  }

  void _cezaVer(int takimIndex) {
    final t = widget.takimlar[takimIndex];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          OzelSimgeWidget(OzelSimge.mola, color: ctx.renk.tehlike, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text("2 dk Mola — ${t.renkAdi}")),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: t.oyuncular.length,
            itemBuilder: (context, i) {
              final o = t.oyuncular[i];
              // Zaten cezalı mı?
              final zatenCezali = _cezalar.any((c) => c.oyuncu.id == o.id);
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: CinsiyetSimgesi(o.isMale, boyut: 18),
                title: Text(o.gorunenAd, style: TextStyle(
                    color: zatenCezali ? ctx.renk.metinUcuncul : ctx.renk.metin,
                    fontWeight: FontWeight.w700)),
                trailing: zatenCezali
                    ? Text("Molada", style: TextStyle(color: ctx.renk.tehlike, fontSize: 13, fontWeight: FontWeight.w700))
                    : null,
                enabled: !zatenCezali,
                onTap: () {
                  Navigator.pop(ctx);
                  _cezaBaslat(takimIndex, o);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
        ],
      ),
    );
  }

  void _cezaBaslat(int takimIndex, Ogrenci oyuncu) {
    final ceza = _Ceza(takimIndex: takimIndex, oyuncu: oyuncu);
    ceza.timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        ceza.kalanSaniye = ((ceza.bitis.difference(DateTime.now()).inMilliseconds / 1000).ceil()).clamp(0, 120);
        if (ceza.kalanSaniye <= 0) {
          t.cancel();
          _cezalar.remove(ceza);
          _cezaBittiUyari(takimIndex, oyuncu);
        }
      });
    });
    setState(() => _cezalar.add(ceza));
  }

  void _cezaBittiUyari(int takimIndex, Ogrenci oyuncu) {
    // Düdükle aynı yoldan (sessiz modu aşar); sistem sesi sessiz modda gelmiyordu.
    unawaited(_ses.play(AssetSource('sounds/sure_bitti.wav')).catchError((_) {}));
    unawaited(HapticFeedback.heavyImpact());

    final t = widget.takimlar[takimIndex];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.check_circle_rounded, color: ctx.renk.basari, size: 28),
          const SizedBox(width: 10),
          const Expanded(child: Text("Mola bitti")),
        ]),
        content: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: t.renk, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              // gorunenAd: demo modunda gerçek ad ekranda görünmemeli
              TextSpan(text: oyuncu.gorunenAd, style: TextStyle(color: ctx.renk.metin, fontWeight: FontWeight.w800)),
              TextSpan(text: " oyuna dönebilir!", style: TextStyle(color: ctx.renk.metinGovde)),
            ])),
          ),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Tamam", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  List<_Ceza> _takimCezalari(int takimIndex) {
    return _cezalar.where((c) => c.takimIndex == takimIndex).toList();
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_alarmGoster) { setState(() => _alarmGoster = false); return; }
        if (_sunum) { _sunumuAcKapa(); return; }
        // Süre bilinçli olarak DURDURULMUYOR: dispose'da çıkış zamanı
        // kaydediliyor, "Devam Et" ile dönüşte geçen süre düşülüyor
        // (mac_durumu.dart kalanSaniyeHesapla). Eskiden burada
        // _baslaDurdur() çağrılıp sayaç sessizce donuyordu (denetim O1).
        Navigator.pop(context, 'geridon');
      },
      child: Scaffold(
      backgroundColor: context.renk.sayfa,
      appBar: _sunum ? null : AppBar(
        backgroundColor: context.renk.sayfa,
        foregroundColor: context.renk.metin,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Sınıfa dön',
          onPressed: () => Navigator.pop(context, 'geridon'),
        ),
        title: Text("Skor Tablosu", style: TextStyle(color: context.renk.metin)),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded),
            tooltip: 'Sunum modu',
            onPressed: _sunumuAcKapa,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => YardimDiyalogu.goster(
              context,
              baslik: 'Skor Tablosu — Yardım',
              bolumler: const [
                YardimBolumu(
                  ikon: Icons.add_circle_rounded,
                  baslik: 'Skor +/-',
                  aciklama: 'Her takımın altındaki "+" ve "−" düğmeleri ile skoru artır/azalt. Yanlış basarsan "−" ile geri al.',
                  renk: Color(0xFF43A047),
                ),
                YardimBolumu(
                  ikon: Icons.fullscreen_rounded,
                  baslik: 'Sunum modu',
                  aciklama: 'Sağ üstteki tam ekran simgesi tabloyu salondan okunur hâle getirir: takım adı ve skor devasa, süre altta. Takımın alanına dokununca +1, basılı tutunca −1. Ekran uyanık kalır. Süre bitince tam ekran kırmızı uyarı, titreşim ve düdük.',
                  renk: Color(0xFF00897B),
                ),
                YardimBolumu(
                  ikon: Icons.timer_rounded,
                  baslik: 'Süre sayacı',
                  aciklama: 'Geri sayım: hazır süreyi seç (0:30 … 10:00), Başlat/Durdur ile yönet. Sıfırla, seçili süreye geri döndürür. Süre bitince tam ekran uyarı, titreşim ve düdük.',
                  renk: Color(0xFF1976D2),
                ),
                YardimBolumu(
                  ikon: Icons.report_rounded,
                  baslik: '2 dakika mola',
                  aciklama: 'Takım kartındaki "2 dk Mola" düğmesi → oyuncuyu seç. Oyuncu 2 dakika oyundan çıkar (üstte kırmızı şerit), süre dolunca kendiliğinden döner. Buz hokeyi/futsal mantığı: dışlama yerine soğuma molası. Perdede "molada" görünür, "ceza" değil.',
                  renk: Color(0xFFE53935),
                ),
                YardimBolumu(
                  ikon: Icons.flag_circle_rounded,
                  baslik: 'Sınıfa dön / etkinliği bitir',
                  aciklama: 'Sol üstteki ok ile sınıf ekranına dönebilirsin: skor ve süre saklanır, uygulama açık kaldığı sürece süre işlemeye devam eder. Sınıflarım ekranındaki "Etkinlik devam ediyor" şeridine dokununca skor tablosu açılır; ⏹ ile etkinliği bitir.',
                  renk: Color(0xFF8E24AA),
                ),
                YardimBolumu(
                  ikon: Icons.tips_and_updates_rounded,
                  baslik: 'Önerilen kullanım',
                  aciklama: 'Basketbol için 10 dk timer + 0\'a sayma. Voleybol için süre yok, sadece skor (25 puan vb.). Futbol/futsal için 5-10 dk yarı + ceza sistemi. Bilgi yarışması/münazara için sadece skor da yeter.',
                  renk: Color(0xFFFB8C00),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(children: [
        if (_sunum)
          SafeArea(child: _sunumGovdesi())
        else
          // 1440 px'te 700 px'lik kartların ortasında 44 px'lik düğmeler
          // kalıyordu; masaüstü/iPad'de gövde 720'ye sınırlı (Center değil
          // Align — iPad kaydırma notu, tema.dart).
          SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
                child: Column(
                  children: [
                    Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), child: _skorPaneli()),
                    _timerWidget(),
                    if (_cezalar.isNotEmpty) _cezaBannerleri(),
                    const SizedBox(height: 16),
                    _takimListeleri(),
                  ],
                ),
              ),
            ),
          ),
        if (_alarmGoster) _alarmKatmani(),
      ]),
    ),
    );
  }

  // ------------------------------------------------------------------
  // "Teneffüs" skor ekranı (2026-10-04): krem zemin, her takım kendi forma
  // renginde çıkartma kart. Sayfa kaydırılır: yatay telefonda ve 4 takımda
  // sayaç ve kadrolar ekran dışında kalıyordu (denetim #3).
  // ------------------------------------------------------------------
  static const _tabular = [FontFeature.tabularFigures()];

  String _takimAdi(TakimBilgi t) => t.isim.isNotEmpty ? t.isim : t.renkAdi;

  Widget _skorPaneli() {
    final n = widget.takimlar.length;
    if (n <= 2) {
      return Column(children: [
        for (var i = 0; i < n; i++)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: _skorKarti(i, genis: true)),
      ]);
    }
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (var i = 0; i < n; i++) SizedBox(width: w, child: _skorKarti(i, genis: false))],
      );
    });
  }

  Widget _skorKarti(int i, {required bool genis}) {
    final t = widget.takimlar[i];
    final cezaSayisi = _takimCezalari(i).length;
    // Sarı/beyaz formada beyaz yazı okunmuyordu (denetim Y4).
    final metin = AppTema.ustMetin(t.renk);
    final ad = _takimAdi(t);
    // Skor kutusuna sığacak kadar küçülür: 100'e çıkınca +/− düğmeleri
    // kartın dışına itiliyordu (denetim #3, 320 px).
    final skor = Semantics(
      liveRegion: true,
      label: '$ad skoru ${t.skor}',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('${t.skor}',
            style: TextStyle(
                fontFamily: AppTema.baslikFontu,
                fontWeight: FontWeight.w700,
                fontSize: genis ? 96 : 64,
                height: 1,
                color: metin,
                fontFeatures: _tabular)),
      ),
    );
    // Dar kartta (3+ takım) 44/52 px; 320 px'te 48/64 sığmıyordu.
    final dugmeler = Row(mainAxisSize: MainAxisSize.min, children: [
      _yuvarlakDugme(Icons.remove_rounded, '$ad skorunu azalt',
          () => setState(() { if (t.skor > 0) { t.skor--; MacDurumu().kaydet(); } }), kucuk: !genis),
      SizedBox(width: genis ? 10 : 6),
      _yuvarlakDugme(Icons.add_rounded, '$ad skorunu artır',
          () => setState(() { t.skor++; MacDurumu().kaydet(); }), ana: true, kucuk: !genis),
    ]);
    final baslik = Column(
      crossAxisAlignment: genis ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(ad,
            maxLines: genis ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: genis ? TextAlign.start : TextAlign.center,
            style: TextStyle(
                fontFamily: AppTema.baslikFontu, fontSize: genis ? 24 : 18, fontWeight: FontWeight.w600, color: metin, height: 1.1)),
        const SizedBox(height: 2),
        Text('${t.renkAdi} · ${t.oyuncular.length} kişi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: metin, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
    // Mola −/+'dan ayrı satırda: 4 takımda aralarında 2 px kalıyordu (denetim #3).
    final mola = _molaDugmesi(i, cezaSayisi);
    return Cikartma(
      renk: t.renk,
      kenarRengi: AppTema.ana,
      dolgu: EdgeInsets.all(genis ? 16 : 12),
      child: genis
          ? Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [baslik, const SizedBox(height: 14), mola],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(height: 92, child: skor),
                  const SizedBox(height: 8),
                  dugmeler,
                ]),
              ),
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              baslik,
              const SizedBox(height: 4),
              SizedBox(height: 64, child: skor),
              const SizedBox(height: 8),
              dugmeler,
              const SizedBox(height: 12),
              mola,
            ]),
    );
  }

  /// Beyaz yuvarlak (−, sıfırla) ya da limon hap (+) çıkartma düğme.
  Widget _yuvarlakDugme(IconData icon, String etiket, VoidCallback onTap, {bool ana = false, bool kucuk = false}) {
    const kenar = BorderSide(color: AppTema.ana, width: 2.5);
    final ShapeBorder sekil = ana ? const StadiumBorder(side: kenar) : const CircleBorder(side: kenar);
    return Semantics(
      button: true,
      label: etiket,
      excludeSemantics: true,
      child: SertGolgeli(
        daire: !ana,
        kayma: 3,
        child: Material(
          color: ana ? const Color(0xFFFFD84D) : Colors.white,
          shape: sekil,
          child: InkWell(
            customBorder: sekil,
            onTap: onTap,
            child: SizedBox(
              width: ana ? (kucuk ? 52 : 64) : (kucuk ? 44 : 48),
              height: kucuk ? 44 : 48,
              child: Icon(icon, color: AppTema.ana, size: kucuk ? 24 : 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _molaDugmesi(int i, int cezaSayisi) {
    final aktif = cezaSayisi > 0;
    final yazi = aktif ? Colors.white : AppTema.ana;
    const sekil = StadiumBorder(side: BorderSide(color: AppTema.ana, width: 2));
    return Material(
      color: aktif ? AppTema.ana : Colors.white,
      shape: sekil,
      child: InkWell(
        customBorder: sekil,
        onTap: () => _cezaVer(i),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // "2 dk" diyalog başlığında; dar kartta etiket sığsın diye kısa.
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              OzelSimgeWidget(OzelSimge.mola, color: yazi, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(aktif ? 'Mola ($cezaSayisi)' : 'Mola',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: yazi, fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _cezaBannerleri() {
    final r = context.renk;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Cikartma(
        renk: r.yokZemin,
        kayma: 3,
        dolgu: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        // Üçten fazla ceza aynı anda olursa şerit sınırsız büyüyüp altındaki
        // takım listesini eziyordu; artık kendi içinde kayıyor.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: Column(
              children: _cezalar.map((c) {
                final t = widget.takimlar[c.takimIndex];
                final progress = c.kalanSaniye / 120;
                return Row(
                  children: [
                    OzelSimgeWidget(OzelSimge.mola, color: r.yokMetin, size: 18),
                    const SizedBox(width: 6),
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(color: t.renk, shape: BoxShape.circle, border: Border.all(color: AppTema.ana, width: 1.5)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(c.oyuncu.gorunenAd,
                          style: TextStyle(color: r.metin, fontWeight: FontWeight.w700, fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(
                      width: 44,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: r.kart,
                          valueColor: AlwaysStoppedAnimation(r.yokMetin),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _sureFmt(c.kalanSaniye),
                      style: TextStyle(color: r.yokMetin, fontWeight: FontWeight.w800, fontSize: 14, fontFeatures: _tabular),
                    ),
                    InkWell(
                      onTap: () {
                        c.timer.cancel();
                        setState(() => _cezalar.remove(c));
                      },
                      customBorder: const CircleBorder(),
                      child: Semantics(
                        label: '${c.oyuncu.gorunenAd} cezasını iptal et',
                        button: true,
                        child: SizedBox(width: 44, height: 44, child: Icon(Icons.close_rounded, color: r.metin, size: 20)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Color _sureRengi() {
    final r = context.renk;
    if (_timerBitti) return r.tehlike;
    if (_kalanSaniye <= 10 && _kalanSaniye > 0 && _timerCalisiyor) return r.uyari;
    return r.metin;
  }

  Widget _timerWidget() {
    final r = context.renk;
    final progress = _toplamSaniye > 0 ? _kalanSaniye / _toplamSaniye : 0.0;
    final sureRengi = _sureRengi();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Cikartma(
        dolgu: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                final scale = _timerCalisiyor && _kalanSaniye <= 10 ? 1.0 + _pulseCtrl.value * 0.05 : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Text(_sureFmt(_kalanSaniye),
                      style: TextStyle(
                          fontFamily: AppTema.baslikFontu,
                          color: sureRengi,
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          fontFeatures: _tabular)),
                );
              },
            ),
            if (_toplamSaniye > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: r.yuzeyGri,
                  valueColor: AlwaysStoppedAnimation(sureRengi == r.metin ? r.vurgu : sureRengi),
                  minHeight: 8,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 8, children: [
              _presetBtn("0:30", 30), _presetBtn("1:00", 60), _presetBtn("2:00", 120),
              _presetBtn("3:00", 180), _presetBtn("5:00", 300), _presetBtn("10:00", 600),
            ]),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 14,
              runSpacing: 10,
              children: [
                Tooltip(message: 'Süreyi sıfırla', child: _yuvarlakDugme(Icons.replay_rounded, 'Süreyi sıfırla', _sifirla)),
                _baslatDugmesi(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _baslatDugmesi({bool kisa = false}) {
    final r = context.renk;
    final zemin = _timerBitti ? r.tehlike : _timerCalisiyor ? AppTema.ana : r.vurgu;
    final yazi = _timerBitti || _timerCalisiyor ? Colors.white : r.vurguMetin;
    final etiket = _timerBitti ? (kisa ? "BİTTİ" : "SÜRE BİTTİ") : _timerCalisiyor ? "DURDUR" : "BAŞLAT";
    final sekil = StadiumBorder(side: BorderSide(color: r.kenar, width: 2.5));
    return SertGolgeli(
      kayma: 3,
      child: Material(
        color: zemin,
        shape: sekil,
        child: InkWell(
          customBorder: sekil,
          onTap: _baslaDurdur,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _timerBitti ? Icons.alarm_off_rounded : _timerCalisiyor ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: yazi, size: 28,
              ),
              const SizedBox(width: 8),
              Text(etiket,
                  style: TextStyle(fontFamily: AppTema.baslikFontu, color: yazi, fontWeight: FontWeight.w600, fontSize: 19)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _presetBtn(String label, int saniye) {
    final r = context.renk;
    final secili = _toplamSaniye == saniye;
    final sekil = StadiumBorder(side: BorderSide(color: secili ? AppTema.ana : r.kenar, width: 2));
    return Material(
      color: secili ? const Color(0xFFFFD84D) : r.kart,
      shape: sekil,
      child: InkWell(
        customBorder: sekil,
        onTap: () => _sureAyarla(saniye),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 56),
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(label,
                  style: TextStyle(
                      color: secili ? AppTema.ana : r.metin, fontWeight: FontWeight.w800, fontSize: 15, fontFeatures: _tabular)),
            ),
          ),
        ),
      ),
    );
  }

  void _isimDuzenle(Ogrenci o) {
    // Demo modunda pencere gerçek adı gösteriyordu (denetim #3).
    if (DemoModu.aktif) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo modunda ad düzenlenemez.')));
      return;
    }
    final c = TextEditingController(text: o.ad);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("İsim Düzenle"),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: GirdiSiniri.ogrenciAdi,
          buildCounter: gizliSayac,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTema.vurgu, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTema.vurgu, foregroundColor: Colors.white,
            ),
            onPressed: () {
              final yeniAd = c.text.trim();
              if (yeniAd.isNotEmpty && yeniAd != o.ad) {
                setState(() => o.ad = yeniAd);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).then((_) => c.dispose());
  }

  Widget _oyuncuSatiri(Ogrenci o, {required bool isKaptan, required bool isCezali, required Color takimRenk}) {
    final r = context.renk;
    final elementAdi = o.element != null ? ElementSistemi.etiketler[o.element] : null;
    final etiket = [
      o.gorunenAd,
      if (isKaptan) 'kaptan',
      if (isCezali) 'molada',
      if (o.eslesenIdler.isNotEmpty) 'eşli',
      ?elementAdi,
      o.isMale ? 'erkek' : 'kız',
    ].join(', ');
    // 32 px'ti, satırlar bitişikti (denetim #3): 44 px.
    return Semantics(
      button: true,
      label: '$etiket. İsmi düzenlemek için dokun, taşımak için basılı tut',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            children: [
              CinsiyetSimgesi(o.isMale, boyut: 16),
              if (o.element != null) ...[
                const SizedBox(width: 3),
                ElementSimgesi(o.element!, boyut: 14, sade: true),
              ],
              if (o.eslesenIdler.isNotEmpty) ...[
                const SizedBox(width: 3),
                Icon(Icons.link_rounded, size: 14, color: r.metinUcuncul),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  o.gorunenAd,
                  style: TextStyle(
                    color: isCezali ? r.tehlike : r.metin,
                    fontWeight: isKaptan ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                    fontStyle: isCezali ? FontStyle.italic : FontStyle.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isKaptan) Icon(Icons.star_rounded, color: r.uyari, size: 18),
              if (isCezali) OzelSimgeWidget(OzelSimge.mola, color: r.tehlike, size: 16),
            ],
          ),
        ),
      ),
    );
  }


  // ------------------------------------------------------------------
  // SUNUM MODU
  // ------------------------------------------------------------------
  Widget _sunumGovdesi() {
    final n = widget.takimlar.length;
    return LayoutBuilder(builder: (context, c) {
      final yatay = c.maxWidth > c.maxHeight;
      Widget paneller;
      if (n <= 2 || (yatay && n <= 4)) {
        paneller = Row(children: [
          for (var i = 0; i < n; i++)
            Expanded(child: Padding(padding: const EdgeInsets.all(6), child: _sunumTakimPaneli(i))),
        ]);
      } else {
        // Yükseklik azken oran negatife/sıfıra düşebiliyordu (denetim #3).
        final satir = (n + 1) ~/ 2;
        final hucreY = ((c.maxHeight - 200).clamp(160.0, double.infinity)) / satir;
        paneller = GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: (c.maxWidth / 2) / hucreY,
          children: [for (var i = 0; i < n; i++) Padding(padding: const EdgeInsets.all(6), child: _sunumTakimPaneli(i))],
        );
      }
      return Column(children: [
        Expanded(child: paneller),
        _sunumSureSeridi(),
      ]);
    });
  }

  Widget _sunumTakimPaneli(int i) {
    final t = widget.takimlar[i];
    final metin = AppTema.ustMetin(t.renk);
    final cezaSayisi = _takimCezalari(i).length;
    final sekil = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
      side: const BorderSide(color: AppTema.ana, width: 3),
    );
    return Semantics(
      button: true,
      label: '${_takimAdi(t)} skoru ${t.skor}. Artırmak için dokun, azaltmak için basılı tut',
      excludeSemantics: true,
      // Sunumda büyük yazı ayarı adı büyütüp skoru 12 px'e eziyordu
      // (denetim #3): panel kendi ölçeğinde kalır.
      child: MediaQuery.withNoTextScaling(
        child: Container(
          margin: const EdgeInsets.only(right: 5, bottom: 5),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            shadows: const [BoxShadow(color: AppTema.ana, offset: Offset(5, 5))],
          ),
          child: Material(
            color: t.renk,
            shape: sekil,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() { t.skor++; MacDurumu().kaydet(); }),
              onLongPress: () => setState(() { if (t.skor > 0) { t.skor--; MacDurumu().kaydet(); } }),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_takimAdi(t),
                        style: TextStyle(fontFamily: AppTema.baslikFontu, color: metin, fontWeight: FontWeight.w600, fontSize: 30)),
                  ),
                  Text(t.renkAdi, style: TextStyle(color: metin, fontSize: 15, fontWeight: FontWeight.w700)),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text('${t.skor}',
                            style: TextStyle(
                                fontFamily: AppTema.baslikFontu,
                                color: metin,
                                fontWeight: FontWeight.w700,
                                fontSize: 260,
                                height: 1,
                                fontFeatures: _tabular)),
                      ),
                    ),
                  ),
                  Row(children: [
                    _yuvarlakDugme(Icons.remove_rounded, '${_takimAdi(t)} skorunu azalt',
                        () => setState(() { if (t.skor > 0) { t.skor--; MacDurumu().kaydet(); } })),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: cezaSayisi > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const ShapeDecoration(color: AppTema.ana, shape: StadiumBorder()),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const OzelSimgeWidget(OzelSimge.mola, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text('Mola ($cezaSayisi)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ]),
                      )
                    // alpha 110 ile neredeyse görünmüyordu (denetim #3).
                    : Text('dokun +1', style: TextStyle(color: metin, fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sunumSureSeridi() {
    final r = context.renk;
    final progress = _toplamSaniye > 0 ? _kalanSaniye / _toplamSaniye : 0.0;
    final sureRengi = _sureRengi();
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
      child: Cikartma(
        dolgu: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: LayoutBuilder(builder: (context, c) {
        // Dar ekranda (320 px) süre ve dört düğme tek satıra sığmıyordu.
        final dar = c.maxWidth < 440;
        final sure = FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_sureFmt(_kalanSaniye),
                    style: TextStyle(
                        fontFamily: AppTema.baslikFontu,
                        color: sureRengi,
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        height: 1,
                        fontFeatures: _tabular)),
              );
        // Takım adının üstüne biniyordu (denetim #3); şeritte.
        final cik = _yuvarlakDugme(Icons.fullscreen_exit_rounded, 'Sunum modundan çık', _sunumuAcKapa);
        final kontroller = [
          _yuvarlakDugme(Icons.replay_rounded, 'Süreyi sıfırla', _sifirla),
          const SizedBox(width: 6),
          _baslatDugmesi(kisa: true),
        ];
        return Column(mainAxisSize: MainAxisSize.min, children: [
          if (dar) ...[
            Row(children: [Expanded(child: sure), const SizedBox(width: 8), cik]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: kontroller),
          ] else
            Row(children: [
              Expanded(child: sure),
              const SizedBox(width: 8),
              ...kontroller,
              const SizedBox(width: 6),
              cik,
            ]),
          if (_toplamSaniye > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: r.yuzeyGri,
                valueColor: AlwaysStoppedAnimation(sureRengi == r.metin ? r.vurgu : sureRengi),
                minHeight: 8,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
            _presetBtn("0:30", 30), _presetBtn("1:00", 60), _presetBtn("2:00", 120),
            _presetBtn("3:00", 180), _presetBtn("5:00", 300), _presetBtn("10:00", 600),
          ]),
        ]);
        }),
      ),
    );
  }

  Widget _alarmKatmani() {
    return Positioned.fill(
      child: Semantics(
        liveRegion: true,
        label: 'Süre bitti',
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, _) => Material(
            color: Color.lerp(const Color(0xFFB3261E), const Color(0xFFE53935), _pulseCtrl.value),
            child: InkWell(
              onTap: () { _pulseCtrl.reset(); setState(() => _alarmGoster = false); },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.alarm_rounded, color: Colors.white, size: 96),
                const SizedBox(height: 16),
                FittedBox(
                  child: Text('SÜRE BİTTİ',
                      style: TextStyle(fontFamily: AppTema.baslikFontu, color: Colors.white, fontSize: 72, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.takimlar.map((t) => '${t.isim} ${t.skor}').join('   •   '),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 40),
                // %70 beyaz 3,7:1'di (denetim #3).
                const Text('Kapatmak için dokun', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  /// Kadrolar: en çok 2 sütun. 4 takımda 4 dar sütun ~85 px'e iniyor, adlar
  /// "Asy…" oluyordu (denetim #3). Sayfa kaydığı için listeler tam boy.
  Widget _takimListeleri() {
    final n = widget.takimlar.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: LayoutBuilder(builder: (context, c) {
        final sutun = n < 2 ? 1 : 2;
        final w = (c.maxWidth - 8 * (sutun - 1)) / sutun;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (var i = 0; i < n; i++) SizedBox(width: w, child: _takimListesi(i))],
        );
      }),
    );
  }

  Widget _takimListesi(int i) {
    final r = context.renk;
    final t = widget.takimlar[i];
    final cezaliIdler = _takimCezalari(i).map((c) => c.oyuncu.id).toSet();
    final ustMetin = AppTema.ustMetin(t.renk);
    return DragTarget<_SuruklenenOgrenci>(
      onWillAcceptWithDetails: (details) => details.data.kaynakTakimIndex != i,
      onAcceptWithDetails: (details) {
        setState(() {
          final kaynak = widget.takimlar[details.data.kaynakTakimIndex];
          kaynak.oyuncular.remove(details.data.ogrenci);
          t.oyuncular.add(details.data.ogrenci);
        });
      },
      builder: (context, candidateData, rejectedData) {
        final uzerindeHover = candidateData.isNotEmpty;
        return Cikartma(
          kayma: 3,
          yaricap: 18,
          kenarKalinligi: uzerindeHover ? 3.5 : 2,
          kenarRengi: uzerindeHover ? r.vurgu : r.kenar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: t.renk,
                  border: Border(bottom: BorderSide(color: r.kenar, width: 2)),
                ),
                child: Text(
                  "${_takimAdi(t)} (${t.oyuncular.length})",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppTema.baslikFontu, color: ustMetin, fontWeight: FontWeight.w600, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (final o in t.oyuncular)
                      Builder(builder: (context) {
                        final isKaptan = t.kaptan != null && o.id == t.kaptan!.id;
                        final isCezali = cezaliIdler.contains(o.id);
                        return LongPressDraggable<_SuruklenenOgrenci>(
                          data: _SuruklenenOgrenci(ogrenci: o, kaynakTakimIndex: i),
                          delay: const Duration(milliseconds: 200),
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: ShapeDecoration(
                                color: t.renk,
                                shape: const StadiumBorder(side: BorderSide(color: AppTema.ana, width: 2)),
                                shadows: const [BoxShadow(color: AppTema.ana, offset: Offset(3, 3))],
                              ),
                              child: Text(o.gorunenAd,
                                  style: TextStyle(color: ustMetin, fontWeight: FontWeight.w800, fontSize: 14)),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _oyuncuSatiri(o, isKaptan: isKaptan, isCezali: isCezali, takimRenk: t.renk),
                          ),
                          child: InkWell(
                            onTap: () => _isimDuzenle(o),
                            child: _oyuncuSatiri(o, isKaptan: isKaptan, isCezali: isCezali, takimRenk: t.renk),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
