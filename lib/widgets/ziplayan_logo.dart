import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Sınıflarım'daki logo: dokununca bekleme ekranındaki gibi bir kez zıplar.
/// İşlevi yok, yalnız tepki (Sabri, 2026-10-04). "Hareketi azalt" açıksa durur.
class ZiplayanLogo extends StatefulWidget {
  final double boyut;
  const ZiplayanLogo({super.key, this.boyut = 46});

  @override
  State<ZiplayanLogo> createState() => _ZiplayanLogoState();
}

class _ZiplayanLogoState extends State<ZiplayanLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _zipla() {
    if (MediaQuery.of(context).disableAnimations) return;
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.boyut;
    return GestureDetector(
      onTap: _zipla,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) {
          final t = _c.value;
          // Çömel (0-0,15) → havada dön (0,15-0,8) → yere değip ezil, toparlan.
          double y = 0, sx = 1, sy = 1, aci = 0;
          if (t < 0.15) {
            final k = math.sin(t / 0.15 * math.pi);
            sx = 1 + 0.08 * k;
            sy = 1 - 0.08 * k;
          } else if (t < 0.8) {
            final k = (t - 0.15) / 0.65;
            y = -b * 0.32 * math.sin(k * math.pi);
            aci = 2 * math.pi * Curves.easeInOut.transform(k);
          } else {
            final k = math.sin((t - 0.8) / 0.2 * math.pi);
            sx = 1 + 0.1 * k;
            sy = 1 - 0.1 * k;
          }
          return Transform.translate(
            offset: Offset(0, y),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(sx, sy, 1),
              child: Transform.rotate(angle: aci, child: child),
            ),
          );
        },
        child: SvgPicture.asset('assets/images/logo_simge.svg', width: b, height: b),
      ),
    );
  }
}
