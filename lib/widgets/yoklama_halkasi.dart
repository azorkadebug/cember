import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema.dart';
import '../tema_renkleri.dart';

/// Sınıf kartının solundaki yoklama halkası (tasarım sistemi: SinifKarti).
///
/// 52px; ortada sınıf kısaltması, etrafında son yoklamada gelenlerin oranı
/// kadar turkuaz yay (ilerleme göstergesi — turkuaz kuralına uyar).
/// [oran] null: yoklama alınmamış, yalnız iz. [bos]: öğrencisiz sınıf,
/// kesik çizgili halka.
class YoklamaHalkasi extends StatelessWidget {
  const YoklamaHalkasi({
    super.key,
    required this.kisaltma,
    this.oran,
    this.bos = false,
    this.secili = false,
    this.semantik,
    this.renkler,
    this.yaziBoyutu = 16,
  });

  final String kisaltma;
  final double? oran;
  final bool bos;
  final bool secili;
  final String? semantik;

  /// Renkli sınıf kartında halka beyaz yuvarlağın üstünde durur; koyu temada
  /// da açık renklerle çizilsin diye.
  final CemberRenkleri? renkler;

  /// Ortadaki yazı; kısaltma yerine "%92" gibi yüzde de olabilir.
  final double yaziBoyutu;

  static const double boyut = 52;

  @override
  Widget build(BuildContext context) {
    final hareketYok = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final hedef = bos ? 0.0 : (oran ?? 0.0);
    final r = renkler ?? context.renk;
    return Semantics(
      label: semantik,
      excludeSemantics: true,
      child: SizedBox(
        width: boyut,
        height: boyut,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: hedef),
          duration: hareketYok ? Duration.zero : const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, deger, child) => CustomPaint(
            painter: _HalkaBoyaci(
              oran: deger,
              bos: bos,
              izRengi: secili ? r.kart : r.yuzeyAna,
              kesikRengi: r.cizgi,
              yayRengi: r.vurgu,
            ),
            child: child,
          ),
          child: Center(
            child: Text(
              kisaltma,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontFamily: AppTema.baslikFontu,
                fontSize: yaziBoyutu,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: bos ? r.metinUcuncul : r.metin,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HalkaBoyaci extends CustomPainter {
  _HalkaBoyaci({
    required this.oran,
    required this.bos,
    required this.izRengi,
    required this.kesikRengi,
    required this.yayRengi,
  });

  final double oran;
  final bool bos;
  final Color izRengi;
  final Color kesikRengi;
  final Color yayRengi;

  static const double _kalinlik = 5;
  static const double _yaricap = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final merkez = size.center(Offset.zero);
    final kutu = Rect.fromCircle(center: merkez, radius: _yaricap);

    if (bos) {
      // Kesik çizgi: 4px çizgi, 4px boşluk.
      final kesik = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = kesikRengi;
      const parca = 4.0;
      final cevre = 2 * math.pi * _yaricap;
      final adet = (cevre / (parca * 2)).floor();
      final aci = 2 * math.pi / adet;
      for (var i = 0; i < adet; i++) {
        canvas.drawArc(kutu, i * aci, aci / 2, false, kesik);
      }
      return;
    }

    final iz = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kalinlik
      ..color = izRengi;
    canvas.drawCircle(merkez, _yaricap, iz);

    if (oran <= 0) return;
    final yay = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kalinlik
      ..strokeCap = StrokeCap.round
      ..color = yayRengi;
    if (oran >= 1) {
      canvas.drawCircle(merkez, _yaricap, yay);
    } else {
      canvas.drawArc(kutu, -math.pi / 2, 2 * math.pi * oran, false, yay);
    }
  }

  @override
  bool shouldRepaint(_HalkaBoyaci eski) =>
      eski.oran != oran ||
      eski.bos != bos ||
      eski.izRengi != izRengi ||
      eski.kesikRengi != kesikRengi ||
      eski.yayRengi != yayRengi;
}
