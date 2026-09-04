import '../tema.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/girdi.dart';
import '../models/ogrenci.dart';
import '../services/mac_durumu.dart';
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

  _Ceza({required this.takimIndex, required this.oyuncu}) : kalanSaniye = 120;
}

class SkorEkrani extends StatefulWidget {
  final List<TakimBilgi> takimlar;
  const SkorEkrani({super.key, required this.takimlar});

  @override
  State<SkorEkrani> createState() => _SkorEkraniState();
}

class _SkorEkraniState extends State<SkorEkrani> with TickerProviderStateMixin {
  Timer? _timer;
  int _kalanSaniye = 0;
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
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _durumGeriYukle();
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
      _pulseCtrl.repeat(reverse: true);
      setState(() => _timerCalisiyor = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _kalanSaniye--;
          if (_kalanSaniye <= 0) {
            _kalanSaniye = 0; _timerCalisiyor = false; _timerBitti = true;
            t.cancel(); _pulseCtrl.reset();
            _sureBittiAlarmi();
          }
        });
      });
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
        backgroundColor: AppTema.panelKoyu2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.front_hand_rounded, color: Colors.red.shade400, size: 22),
          const SizedBox(width: 8),
          Text("2 dk Ceza — ${t.renkAdi}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
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
                leading: Text(o.isMale ? "♂" : "♀",
                    style: TextStyle(color: o.isMale ? Colors.blue.shade300 : Colors.pink.shade300, fontSize: 14)),
                title: Text(o.gorunenAd, style: TextStyle(
                    color: zatenCezali ? Colors.white30 : Colors.white,
                    fontWeight: FontWeight.w600)),
                trailing: zatenCezali
                    ? Text("Cezalı", style: TextStyle(color: Colors.red.shade300, fontSize: 12))
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
            child: const Text("İptal", style: TextStyle(color: Colors.white60)),
          ),
        ],
      ),
    );
  }

  void _cezaBaslat(int takimIndex, Ogrenci oyuncu) {
    final ceza = _Ceza(takimIndex: takimIndex, oyuncu: oyuncu);
    ceza.timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        ceza.kalanSaniye--;
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
    // Sistem sesi + titreşim
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();

    final t = widget.takimlar[takimIndex];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTema.panelKoyu2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.green.withAlpha(30), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text("Ceza Bitti!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        ]),
        content: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: t.renk, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(TextSpan(children: [
              // gorunenAd: demo modunda gerçek ad ekranda görünmemeli
              TextSpan(text: oyuncu.gorunenAd, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              TextSpan(text: " oyuna dönebilir!", style: TextStyle(color: Colors.white.withAlpha(180))),
            ])),
          ),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: AppTema.panelKoyu1,
      appBar: _sunum ? null : AppBar(
        backgroundColor: AppTema.panelKoyu1,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Sınıfa dön',
          onPressed: () => Navigator.pop(context, 'geridon'),
        ),
        title: const Text("Skor Tablosu", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
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
                  baslik: 'Timer (kronometre)',
                  aciklama: 'Başlat/Durdur düğmesi ile zamanı kontrol et. Hazır süreler (0:30, 1:00, 2:00, 3:00, 5:00, 10:00) ile periyotları hızlıca ayarla. Sıfırla butonu zamanı 0:00\'a getirir.',
                  renk: Color(0xFF1976D2),
                ),
                YardimBolumu(
                  ikon: Icons.report_rounded,
                  baslik: '2 dakika ceza sistemi',
                  aciklama: 'Takım kartı üstünde "Ceza" düğmesi → cezalanacak oyuncuyu seç. Seçilen oyuncu 2 dakika boyunca takımdan düşer (kırmızı banner üstte gösterir). Süre dolunca otomatik geri döner. Buz hokeyi/futsal mantığı — disiplinsizliği oyun içinde yönet, dışlama yerine "soğuma" molası.',
                  renk: Color(0xFFE53935),
                ),
                YardimBolumu(
                  ikon: Icons.flag_circle_rounded,
                  baslik: 'Sınıfa dön / etkinliği bitir',
                  aciklama: 'Sol üstteki ok ile sınıf ekranına dönebilirsin: skor ve süre saklanır, süre arka planda işlemeye devam eder. Sınıflarım ekranındaki "Etkinlik devam ediyor" şeridinden geri gel ya da oradaki ⏹ ile etkinliği bitir.',
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
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
              child: Column(
                children: [
                  Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: _skorPaneli()),
                  _timerWidget(),
                  // Ceza bannerleri
                  if (_cezalar.isNotEmpty) _cezaBannerleri(),
                  const SizedBox(height: 8),
                  Expanded(child: _takimListeleri()),
                ],
              ),
            ),
          ),
        if (_alarmGoster) _alarmKatmani(),
      ]),
    ),
    );
  }

  Widget _skorPaneli() {
    final n = widget.takimlar.length;
    // İki takımda yan yana; üç ve üstünde 2 sütunlu sarma. Eskiden hepsi
    // tek satırda Expanded'dı: 430 px'te 4 takımda kart 90 px kalıyor,
    // −/+ düğmeleri (44+10+22+10+44 = 130 px) kartın dışında kalıyordu —
    // puan girilemiyordu (denetim K1).
    if (n <= 2) {
      return Row(
        children: List.generate(n, (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == n - 1 ? 0 : 4),
            child: _skorKarti(i),
          ),
        )),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      final kartGenislik = (c.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8, runSpacing: 8,
        children: List.generate(n, (i) => SizedBox(width: kartGenislik, child: _skorKarti(i))),
      );
    });
  }

  Widget _skorKarti(int i) {
    final t = widget.takimlar[i];
    final cezaSayisi = _takimCezalari(i).length;
    // Sarı/beyaz formada beyaz metin 1,5:1'e düşüyordu (denetim Y4);
    // zemine göre beyaz ya da koyu seçiliyor.
    final metin = AppTema.ustMetin(t.renk);
    final dolgu = AppTema.ustDolgu(t.renk);
    // 3+ takımda kartlar iki satıra bölündüğü için dikeyde sıkı tutuluyor;
    // yoksa oyuncu listelerine yer kalmıyor.
    final kompakt = widget.takimlar.length > 2;
    // Siyah formada siyah-saydam ceza düğmesi görünmüyordu; sarıda koyu
    // metin koyu pill üstüne düşüyordu. Metin rengine göre pill.
    final cezaZemin = cezaSayisi > 0
        ? const Color(0xFF8E1F1A)
        : metin == Colors.white
            ? (t.renk.computeLuminance() < 0.08 ? Colors.white.withAlpha(50) : Colors.black.withAlpha(115))
            : Colors.white.withAlpha(170);
    final cezaMetin = cezaSayisi > 0 ? Colors.white : metin;
    return Container(
      padding: EdgeInsets.symmetric(vertical: kompakt ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [t.renk.withAlpha(200), t.renk]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: t.renk.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(t.isim, style: TextStyle(color: metin, fontWeight: FontWeight.w800, fontSize: 13),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(t.renkAdi, style: TextStyle(color: metin.withAlpha(200), fontSize: 12)),
          SizedBox(height: kompakt ? 2 : 6),
          // Skor
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _skorBtn(Icons.remove_rounded, '${t.isim} skorunu azalt', metin, dolgu,
                  () => setState(() { if (t.skor > 0) { t.skor--; MacDurumu().kaydet(); } })),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Semantics(
                  liveRegion: true,
                  label: '${t.isim} skoru ${t.skor}',
                  excludeSemantics: true,
                  child: Text("${t.skor}", style: TextStyle(color: metin, fontSize: kompakt ? 30 : 38, fontWeight: FontWeight.w900)),
                ),
              ),
              _skorBtn(Icons.add_rounded, '${t.isim} skorunu artır', metin, dolgu,
                  () => setState(() { t.skor++; MacDurumu().kaydet(); })),
            ],
          ),
          SizedBox(height: kompakt ? 2 : 6),
          // Ceza butonu
          Material(
            color: cezaZemin,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _cezaVer(i),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: kompakt ? 8 : 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.front_hand_rounded, color: cezaMetin, size: 15),
                    const SizedBox(width: 5),
                    Text(
                      cezaSayisi > 0 ? "Ceza ($cezaSayisi)" : "2dk Ceza",
                      style: TextStyle(color: cezaMetin, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skorBtn(IconData icon, String etiket, Color ikonRengi, Color dolgu, VoidCallback onTap) {
    // Ekranın en sık basılan düğmeleri semantik ağaçta isimsizdi (denetim K2).
    return Semantics(
      button: true,
      label: etiket,
      excludeSemantics: true,
      child: Material(
        color: dolgu,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          // 38x38'di; maç temposunda ayakta, tek elle basılıyor — 44'e çıktı.
          child: SizedBox(
            width: 44, height: 44,
            child: Icon(icon, color: ikonRengi, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _cezaBannerleri() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withAlpha(40)),
      ),
      // Üçten fazla ceza aynı anda olursa şerit sınırsız büyüyüp altındaki
      // takım listesini eziyordu; artık kendi içinde kayıyor.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 132),
        child: SingleChildScrollView(
          child: Column(
        children: _cezalar.map((c) {
          final t = widget.takimlar[c.takimIndex];
          final progress = c.kalanSaniye / 120;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(Icons.front_hand_rounded, color: Colors.red.shade400, size: 14),
                const SizedBox(width: 6),
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: t.renk, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(c.oyuncu.gorunenAd,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                // Mini progress bar
                SizedBox(
                  width: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withAlpha(20),
                      valueColor: AlwaysStoppedAnimation(
                        c.kalanSaniye <= 10 ? Colors.red : Colors.red.shade300,
                      ),
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _sureFmt(c.kalanSaniye),
                  style: TextStyle(
                    color: c.kalanSaniye <= 10 ? Colors.red : Colors.red.shade300,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),
                // İptal butonu
                InkWell(
                  onTap: () {
                    c.timer.cancel();
                    setState(() => _cezalar.remove(c));
                  },
                  customBorder: const CircleBorder(),
                  child: Semantics(
                    label: '${c.oyuncu.gorunenAd} cezasını iptal et',
                    button: true,
                    child: SizedBox(
                      width: 44, height: 44,
                      child: Icon(Icons.close_rounded, color: Colors.white.withAlpha(160), size: 18),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _timerWidget() {
    final progress = _toplamSaniye > 0 ? _kalanSaniye / _toplamSaniye : 0.0;
    final timerColor = _timerBitti
        ? Colors.red
        : _kalanSaniye <= 10 && _kalanSaniye > 0 && _timerCalisiyor
            ? Colors.orange
            : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTema.panelKoyu2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = _timerCalisiyor && _kalanSaniye <= 10 ? 1.0 + _pulseCtrl.value * 0.05 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Text(_sureFmt(_kalanSaniye), style: TextStyle(
                    color: timerColor, fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 4)),
              );
            },
          ),
          if (_toplamSaniye > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress, backgroundColor: Colors.white.withAlpha(20),
                valueColor: AlwaysStoppedAnimation(timerColor.withAlpha(200)), minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Row'du: 360 px'te 6 × 58 px = 348 px, kartın 296 px'lik iç
          // genişliğine sığmayıp "10:00" kesiliyordu (denetim Y3).
          Wrap(alignment: WrapAlignment.center, runSpacing: 6, children: [
            _presetBtn("0:30", 30), _presetBtn("1:00", 60), _presetBtn("2:00", 120),
            _presetBtn("3:00", 180), _presetBtn("5:00", 300), _presetBtn("10:00", 600),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Semantics(
              button: true, label: 'Süreyi sıfırla', excludeSemantics: true,
              child: Tooltip(
                message: 'Süreyi sıfırla',
                child: Material(
                  color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14), onTap: _sifirla,
                    child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.replay_rounded, color: Colors.white70, size: 24)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Material(
              color: _timerBitti ? Colors.red.withAlpha(40) : _timerCalisiyor ? Colors.orange.withAlpha(40) : Colors.green.withAlpha(40),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18), onTap: _baslaDurdur,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  child: Row(children: [
                    Icon(
                      _timerBitti ? Icons.alarm_off_rounded : _timerCalisiyor ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: _timerBitti ? Colors.red : _timerCalisiyor ? Colors.orange : Colors.green, size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timerBitti ? "SÜRE BİTTİ" : _timerCalisiyor ? "DURDUR" : "BAŞLAT",
                      style: TextStyle(
                        color: _timerBitti ? Colors.red : _timerCalisiyor ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w800, fontSize: 16,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _presetBtn(String label, int saniye) {
    final secili = _toplamSaniye == saniye;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        // Seçili hâl koyu lacivert zeminde AppTema.ana (charcoal) metinle
        // neredeyse okunmuyordu; artık açık zemin + koyu metin ile net.
        color: secili ? Colors.white.withAlpha(235) : Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10), onTap: () => _sureAyarla(saniye),
          // Yükseklik ~27px'di; dokunma hedefi 44'e çıkarıldı.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 52),
            // Wrap gevşek ama sınırlı genişlik verir; widthFactor olmadan
            // Center tüm satıra yayılıyordu.
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(label, style: TextStyle(
                  color: secili ? AppTema.panelKoyu1 : Colors.white70,
                  fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _isimDuzenle(Ogrenci o) {
    final c = TextEditingController(text: o.ad);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("İsim Düzenle"),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: GirdiSiniri.ogrenciAdi,
          buildCounter: gizliSayac,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTema.ana, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTema.ana, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final elementAdi = o.element != null ? ElementSistemi.etiketler[o.element] : null;
    final etiket = [
      o.gorunenAd,
      if (isKaptan) 'kaptan',
      if (isCezali) 'cezalı',
      if (o.eslesenIdler.isNotEmpty) 'eşli',
      ?elementAdi,
      o.isMale ? 'erkek' : 'kız',
    ].join(', ');
    // Satır 21 px'ti ve ekran okuyucu yalnız sembolleri okuyordu (denetim
    // O9); 32 px asgari yükseklik, tek birleşik etiket.
    return Semantics(
      button: true,
      label: '$etiket. İsmi düzenlemek için dokun, taşımak için basılı tut',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              Text(o.isMale ? "♂" : "♀",
                  style: TextStyle(color: o.isMale ? Colors.blue.shade300 : Colors.pink.shade300, fontSize: 12)),
              if (o.element != null) ...[
                const SizedBox(width: 3),
                Text(ElementSistemi.sembol(o.element)!, style: const TextStyle(fontSize: 12)),
              ],
              if (o.eslesenIdler.isNotEmpty) ...[
                const SizedBox(width: 3),
                Icon(Icons.link_rounded, size: 13, color: Colors.white.withAlpha(180)),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  o.gorunenAd,
                  style: TextStyle(
                    color: isCezali ? Colors.red.shade300 : isKaptan ? Colors.amber : Colors.white70,
                    fontWeight: isKaptan ? FontWeight.w800 : FontWeight.w400,
                    fontSize: 12,
                    decoration: isCezali ? TextDecoration.lineThrough : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // "©" telif işareti kaptan demekti; ekran okuyucu "telif hakkı"
              // diyordu (denetim D5).
              if (isKaptan) const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
              if (isCezali)
                Icon(Icons.front_hand_rounded, color: Colors.red.shade400, size: 12),
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
        paneller = GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: (c.maxWidth / 2) / ((c.maxHeight - 150) / ((n + 1) ~/ 2)),
          children: [for (var i = 0; i < n; i++) Padding(padding: const EdgeInsets.all(6), child: _sunumTakimPaneli(i))],
        );
      }
      return Column(children: [
        Expanded(child: Stack(children: [
          paneller,
          Positioned(
            top: 4, right: 4,
            child: IconButton(
              tooltip: 'Sunum modundan çık',
              style: IconButton.styleFrom(backgroundColor: Colors.black.withAlpha(90)),
              icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
              onPressed: _sunumuAcKapa,
            ),
          ),
        ])),
        _sunumSureSeridi(),
      ]);
    });
  }

  Widget _sunumTakimPaneli(int i) {
    final t = widget.takimlar[i];
    final metin = AppTema.ustMetin(t.renk);
    final cezaSayisi = _takimCezalari(i).length;
    return Semantics(
      button: true,
      label: '${t.isim} skoru ${t.skor}. Artırmak için dokun, azaltmak için basılı tut',
      excludeSemantics: true,
      child: Material(
        color: t.renk,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => setState(() { t.skor++; MacDurumu().kaydet(); }),
          onLongPress: () => setState(() { if (t.skor > 0) { t.skor--; MacDurumu().kaydet(); } }),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Column(children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(t.isim,
                    style: TextStyle(color: metin, fontWeight: FontWeight.w800, fontSize: 30, letterSpacing: .5)),
              ),
              Text(t.renkAdi, style: TextStyle(color: metin.withAlpha(200), fontSize: 14)),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text('${t.skor}',
                        style: TextStyle(color: metin, fontWeight: FontWeight.w900, fontSize: 260, height: 1)),
                  ),
                ),
              ),
              Row(children: [
                Semantics(
                  button: true, label: '${t.isim} skorunu azalt', excludeSemantics: true,
                  child: Material(
                    color: AppTema.ustDolgu(t.renk),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => setState(() { if (t.skor > 0) { t.skor--; MacDurumu().kaydet(); } }),
                      child: SizedBox(width: 52, height: 52, child: Icon(Icons.remove_rounded, color: metin, size: 28)),
                    ),
                  ),
                ),
                const Spacer(),
                if (cezaSayisi > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF8E1F1A), borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.front_hand_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('Ceza ($cezaSayisi)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ]),
                  )
                else
                  Text('dokun +1', style: TextStyle(color: metin.withAlpha(150), fontSize: 13)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sunumSureSeridi() {
    final progress = _toplamSaniye > 0 ? _kalanSaniye / _toplamSaniye : 0.0;
    final renk = _timerBitti
        ? Colors.red
        : _kalanSaniye <= 10 && _kalanSaniye > 0 && _timerCalisiyor
            ? Colors.orange
            : Colors.white;
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 0, 6, 6),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppTema.panelKoyu2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_sureFmt(_kalanSaniye),
                  style: TextStyle(color: renk, fontSize: 72, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 4, height: 1)),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true, label: 'Süreyi sıfırla', excludeSemantics: true,
            child: Material(
              color: Colors.white.withAlpha(15), borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14), onTap: _sifirla,
                child: const Padding(padding: EdgeInsets.all(14), child: Icon(Icons.replay_rounded, color: Colors.white70, size: 28)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _timerBitti ? Colors.red.withAlpha(40) : _timerCalisiyor ? Colors.orange.withAlpha(40) : Colors.green.withAlpha(40),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18), onTap: _baslaDurdur,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                child: Row(children: [
                  Icon(
                    _timerBitti ? Icons.alarm_off_rounded : _timerCalisiyor ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _timerBitti ? Colors.red : _timerCalisiyor ? Colors.orange : Colors.green, size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timerBitti ? "BİTTİ" : _timerCalisiyor ? "DURDUR" : "BAŞLAT",
                    style: TextStyle(
                      color: _timerBitti ? Colors.red : _timerCalisiyor ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.w800, fontSize: 18,
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
        if (_toplamSaniye > 0) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress, backgroundColor: Colors.white.withAlpha(20),
              valueColor: AlwaysStoppedAnimation(renk.withAlpha(200)), minHeight: 6,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, runSpacing: 6, children: [
          _presetBtn("0:30", 30), _presetBtn("1:00", 60), _presetBtn("2:00", 120),
          _presetBtn("3:00", 180), _presetBtn("5:00", 300), _presetBtn("10:00", 600),
        ]),
      ]),
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
                      style: TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, letterSpacing: 6)),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.takimlar.map((t) => '${t.isim} ${t.skor}').join('   •   '),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 40),
                Text('Kapatmak için dokun', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 16)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _takimListeleri() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(widget.takimlar.length, (i) {
          final t = widget.takimlar[i];
          final cezaliIdler = _takimCezalari(i).map((c) => c.oyuncu.id).toSet();
          return Expanded(
            child: DragTarget<_SuruklenenOgrenci>(
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
                return Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4, right: i == widget.takimlar.length - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: AppTema.panelKoyu2, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: uzerindeHover ? t.renk : t.renk.withAlpha(60), width: uzerindeHover ? 2 : 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: t.renk.withAlpha(uzerindeHover ? 60 : 30),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                        ),
                        child: Center(
                          child: Text(
                            "${t.isim.isNotEmpty ? t.isim : t.renkAdi} (${t.oyuncular.length})",
                            // Takım renginde yazılıyordu: siyah formada 1,3:1,
                            // turuncuda 1,6:1 (denetim O6). Renk artık zeminde.
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: t.oyuncular.length,
                          itemBuilder: (context, j) {
                            final o = t.oyuncular[j];
                            final isKaptan = t.kaptan != null && o.id == t.kaptan!.id;
                            final isCezali = cezaliIdler.contains(o.id);
                            return LongPressDraggable<_SuruklenenOgrenci>(
                              data: _SuruklenenOgrenci(ogrenci: o, kaynakTakimIndex: i),
                              delay: const Duration(milliseconds: 200),
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: t.renk.withAlpha(200),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 8)],
                                  ),
                                  child: Text(o.gorunenAd, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _oyuncuSatiri(o, isKaptan: isKaptan, isCezali: isCezali, takimRenk: t.renk),
                              ),
                              child: GestureDetector(
                                onTap: () => _isimDuzenle(o),
                                child: _oyuncuSatiri(o, isKaptan: isKaptan, isCezali: isCezali, takimRenk: t.renk),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
