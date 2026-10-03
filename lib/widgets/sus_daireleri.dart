import 'dart:math' as math;

import 'package:flutter/material.dart';

/// "Teneffüs" süs dairelerinden biri. [konum] kutunun içinde 0-1 arası
/// (merkez); [cap] piksel. [genlik] dairenin süzülürken gidip geldiği mesafe.
class SusDaire {
  final Offset konum;
  final double cap;
  final Color renk;
  final double genlik;
  const SusDaire(this.konum, this.cap, this.renk, {this.genlik = 10});
}

/// Arka planda yavaşça süzülen renkli daireler. Dokunmaya kapalı; sistemde
/// "hareketi azalt" açıksa durur.
class SusDaireleri extends StatefulWidget {
  final List<SusDaire> daireler;
  final Duration tur;
  const SusDaireleri({super.key, required this.daireler, this.tur = const Duration(seconds: 9)});

  @override
  State<SusDaireleri> createState() => _SusDaireleriState();
}

class _SusDaireleriState extends State<SusDaireleri> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.tur);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _DairePainter(widget.daireler, _c),
        ),
      ),
    );
  }
}

class _DairePainter extends CustomPainter {
  final List<SusDaire> daireler;
  final Animation<double> t;
  _DairePainter(this.daireler, this.t) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final aci = t.value * 2 * math.pi;
    for (var i = 0; i < daireler.length; i++) {
      final d = daireler[i];
      // Her daire kendi evresiyle küçük bir elips çizer; hepsi aynı anda
      // aynı yöne kaymasın.
      final evre = aci + i * 1.9;
      final merkez = Offset(d.konum.dx * size.width, d.konum.dy * size.height) +
          Offset(math.cos(evre) * d.genlik, math.sin(evre * 2) * d.genlik * 0.6);
      canvas.drawCircle(merkez, d.cap / 2, Paint()..color = d.renk);
    }
  }

  @override
  bool shouldRepaint(_DairePainter eski) => eski.daireler != daireler;
}
