import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ogrenci.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _sureAyarla(int saniye) {
    _timer?.cancel();
    setState(() {
      _kalanSaniye = saniye;
      _toplamSaniye = saniye;
      _timerCalisiyor = false;
      _timerBitti = false;
    });
    _pulseCtrl.reset();
  }

  void _baslaDurdur() {
    if (_timerBitti) return;
    if (_timerCalisiyor) {
      _timer?.cancel();
      _pulseCtrl.reset();
      setState(() => _timerCalisiyor = false);
    } else {
      if (_kalanSaniye <= 0) return;
      _pulseCtrl.repeat(reverse: true);
      setState(() => _timerCalisiyor = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() {
          _kalanSaniye--;
          if (_kalanSaniye <= 0) {
            _kalanSaniye = 0;
            _timerCalisiyor = false;
            _timerBitti = true;
            t.cancel();
            _pulseCtrl.reset();
          }
        });
      });
    }
  }

  void _sifirla() {
    _timer?.cancel();
    _pulseCtrl.reset();
    setState(() {
      _kalanSaniye = _toplamSaniye;
      _timerCalisiyor = false;
      _timerBitti = false;
    });
  }

  String _sureFmt(int saniye) {
    final m = saniye ~/ 60;
    final s = saniye % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Skor Tablosu", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: Column(
        children: [
          // Skor paneli
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _skorPaneli(),
          ),
          // Timer
          _timerWidget(),
          const SizedBox(height: 8),
          // Takım listeleri yan yana
          Expanded(child: _takimListeleri()),
        ],
      ),
    );
  }

  Widget _skorPaneli() {
    return Row(
      children: List.generate(widget.takimlar.length, (i) {
        final t = widget.takimlar[i];
        final isFirst = i == 0;
        final isLast = i == widget.takimlar.length - 1;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: isFirst ? 0 : 4,
              right: isLast ? 0 : 4,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [t.renk.withAlpha(200), t.renk],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: t.renk.withAlpha(60), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Text(t.isim, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(t.renkAdi, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 10)),
                const SizedBox(height: 8),
                // Skor
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _skorBtn(Icons.remove_rounded, () => setState(() { if (t.skor > 0) t.skor--; }), t.renk),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text("${t.skor}", style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                    ),
                    _skorBtn(Icons.add_rounded, () => setState(() => t.skor++), t.renk),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _skorBtn(IconData icon, VoidCallback onTap, Color renk) {
    return Material(
      color: Colors.white.withAlpha(40),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 24),
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
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        children: [
          // Timer display
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final scale = _timerCalisiyor && _kalanSaniye <= 10 ? 1.0 + _pulseCtrl.value * 0.05 : 1.0;
              return Transform.scale(
                scale: scale,
                child: Text(
                  _sureFmt(_kalanSaniye),
                  style: TextStyle(
                    color: timerColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    letterSpacing: 4,
                  ),
                ),
              );
            },
          ),
          if (_toplamSaniye > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withAlpha(20),
                valueColor: AlwaysStoppedAnimation(timerColor.withAlpha(200)),
                minHeight: 4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Preset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _presetBtn("0:30", 30),
              _presetBtn("1:00", 60),
              _presetBtn("2:00", 120),
              _presetBtn("3:00", 180),
              _presetBtn("5:00", 300),
              _presetBtn("10:00", 600),
            ],
          ),
          const SizedBox(height: 12),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sıfırla
              Material(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _sifirla,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.replay_rounded, color: Colors.white70, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Başla/Durdur
              Material(
                color: _timerBitti
                    ? Colors.red.withAlpha(40)
                    : _timerCalisiyor
                        ? Colors.orange.withAlpha(40)
                        : Colors.green.withAlpha(40),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _baslaDurdur,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          _timerBitti
                              ? Icons.alarm_off_rounded
                              : _timerCalisiyor
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          color: _timerBitti ? Colors.red : _timerCalisiyor ? Colors.orange : Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timerBitti ? "SÜRE BİTTİ" : _timerCalisiyor ? "DURDUR" : "BAŞLAT",
                          style: TextStyle(
                            color: _timerBitti ? Colors.red : _timerCalisiyor ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetBtn(String label, int saniye) {
    final secili = _toplamSaniye == saniye;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: secili ? Colors.orange.withAlpha(40) : Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _sureAyarla(saniye),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(label, style: TextStyle(
              color: secili ? Colors.orange : Colors.white60,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            )),
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
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : 4,
                right: i == widget.takimlar.length - 1 ? 0 : 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: t.renk.withAlpha(60)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: t.renk.withAlpha(30),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    ),
                    child: Center(
                      child: Text("${t.renkAdi} (${t.oyuncular.length})",
                          style: TextStyle(color: t.renk, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  // Players
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: t.oyuncular.length,
                      itemBuilder: (context, j) {
                        final o = t.oyuncular[j];
                        final isKaptan = t.kaptan != null && o.id == t.kaptan!.id;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          child: Row(
                            children: [
                              Text(o.isMale ? "♂" : "♀",
                                  style: TextStyle(color: o.isMale ? Colors.blue.shade300 : Colors.pink.shade300, fontSize: 12)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "${o.ad}${isKaptan ? ' ©' : ''}",
                                  style: TextStyle(
                                    color: isKaptan ? Colors.amber : Colors.white70,
                                    fontWeight: isKaptan ? FontWeight.w800 : FontWeight.w400,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
