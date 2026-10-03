import 'package:flutter/material.dart';

import '../tema_renkleri.dart';

/// "Teneffüs" görünümünün çıkartması: mürekkep kenarlı, bulanıklıksız ve
/// sağ alta kaydırılmış gölgeli kutu. Kart, bant ve büyük düğmelerin ortak
/// kalıbı; renk ve köşe dışında her yerde aynı dursun diye tek yerde.
class Cikartma extends StatelessWidget {
  const Cikartma({
    super.key,
    required this.child,
    this.renk,
    this.yaricap = 22,
    this.kayma = 4,
    this.kenarKalinligi = 2.5,
    this.kenarRengi,
    this.dolgu = EdgeInsets.zero,
    this.onTap,
    this.onLongPress,
    this.semantik,
  });

  final Widget child;

  /// Zemin; verilmezse temanın kart rengi.
  final Color? renk;
  final double yaricap;

  /// Gölgenin sağa ve aşağı kayması (px). 0: gölgesiz.
  final double kayma;
  final double kenarKalinligi;
  final Color? kenarRengi;
  final EdgeInsetsGeometry dolgu;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semantik;

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    final sekil = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(yaricap),
      side: BorderSide(color: kenarRengi ?? r.kenar, width: kenarKalinligi),
    );
    Widget ic = Padding(padding: dolgu, child: child);
    if (onTap != null || onLongPress != null) {
      ic = InkWell(customBorder: sekil, onTap: onTap, onLongPress: onLongPress, child: ic);
    }
    return Container(
      // Gölge kutunun dışına taşar; komşusuna binmesin diye yer ayır.
      margin: EdgeInsets.only(right: kayma, bottom: kayma),
      // Gölge katmanı kenar çizmez; kenarı yalnız Material çizer (ikisi de
      // çizince arada ince bir boşlukla çift çizgi görünüyordu).
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(yaricap)),
        shadows: kayma == 0
            ? null
            : [BoxShadow(color: r.sertGolge, offset: Offset(kayma, kayma))],
      ),
      child: Material(
        color: renk ?? r.kart,
        shape: sekil,
        clipBehavior: Clip.antiAlias,
        child: semantik == null ? ic : Semantics(label: semantik, child: ic),
      ),
    );
  }
}

/// Hap ya da yuvarlak düğmenin arkasına sert gölge koyar (FAB, ana eylem).
class SertGolgeli extends StatelessWidget {
  const SertGolgeli({super.key, required this.child, this.daire = false, this.kayma = 4});

  final Widget child;
  final bool daire;
  final double kayma;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: kayma, bottom: kayma),
      decoration: ShapeDecoration(
        shape: daire ? const CircleBorder() : const StadiumBorder(),
        shadows: [BoxShadow(color: context.renk.sertGolge, offset: Offset(kayma, kayma))],
      ),
      child: child,
    );
  }
}
