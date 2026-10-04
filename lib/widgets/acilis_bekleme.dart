import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tema_renkleri.dart';
import '../utils/acilis_sinyali.dart';

/// Açılışta giriş/profil kontrolü sürerken gösterilen bekleme ekranı.
///
/// Web'de HTML açılış ekranı (web/index.html) bu bekleme bitene kadar üstte
/// kalır: eskiden Flutter'ın ilk karesinde kalkıyor, arkasından dönen halka
/// ve sonra asıl ekran geliyordu; logo iki kez "sekiyordu" (Sabri,
/// 2026-10-05). Son [AcilisBekleme] kalkınca HTML ekranı tek geçişle söner.
/// Bu widget HTML ekranının aynısı: zaman aşımında ya da mobilde görünür.
class AcilisBekleme extends StatefulWidget {
  const AcilisBekleme({super.key});

  /// runApp'ten sonra çağrılır: ilk karede hiç bekleme ekranı yoksa
  /// (oturum anında hazırsa) açılış ekranı yine kalksın.
  static void ilkKareKontrol() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_AcilisBeklemeState._acik == 0 && !_AcilisBeklemeState._kaldirildi) {
        _AcilisBeklemeState._kaldirildi = true;
        acilisEkraniniKaldir();
      }
    });
  }

  @override
  State<AcilisBekleme> createState() => _AcilisBeklemeState();
}

class _AcilisBeklemeState extends State<AcilisBekleme> with SingleTickerProviderStateMixin {
  static int _acik = 0;
  static bool _kaldirildi = false;
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _acik++;
  }

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
    _acik--;
    _c.dispose();
    // Aynı karede bir sonraki bekleme ekranı kurulmuş olabilir (giriş →
    // profil kontrolü); kare bitince hâlâ hiç yoksa açılış biter.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_acik == 0 && !_kaldirildi) {
        _kaldirildi = true;
        acilisEkraniniKaldir();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    return Scaffold(
      backgroundColor: r.sayfa,
      body: Center(
        child: Semantics(
          label: 'Çember yükleniyor',
          excludeSemantics: true,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                // web/index.html'deki @keyframes zipla/golge ile aynı eğri.
                final t = _c.value;
                final k = math.sin(t * math.pi); // 0 → 1 → 0
                final y = -38 * k;
                final sx = t < 0.12 || t > 0.88 ? 1.06 : 1.0;
                final sy = t < 0.12 || t > 0.88 ? 0.94 : 1.0;
                return Column(children: [
                  Transform.translate(
                    offset: Offset(0, y),
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(sx, sy, 1),
                      child: Transform.rotate(
                        angle: 10 * math.pi / 180 * k,
                        child: SvgPicture.asset('assets/images/logo_simge.svg', width: 104, height: 104),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Transform.scale(
                    scaleX: 1 - 0.45 * k,
                    child: Container(
                      width: 76, height: 12,
                      decoration: BoxDecoration(
                        color: r.metin.withValues(alpha: 0.2 - 0.12 * k),
                        borderRadius: const BorderRadius.all(Radius.elliptical(38, 6)),
                      ),
                    ),
                  ),
                ]);
              },
            ),
            const SizedBox(height: 14),
            Text('Çember', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: r.metin)),
            const SizedBox(height: 14),
            Text('Yükleniyor…', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: r.metinIkincil)),
          ]),
        ),
      ),
    );
  }
}
