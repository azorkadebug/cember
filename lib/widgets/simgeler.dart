import 'package:flutter/material.dart';
import '../models/ogrenci.dart';

/// Emoji ve ♂♀ metin sembolleri cihazdan cihaza farklı çiziliyor, iOS
/// Simülatörü ve bazı Android'lerde hiç çizilmiyordu (tasarım listesi #6,
/// 2026-09-06). Her yerde aynı ikonlar.

/// Element (ateş/su/toprak/hava) simgesi: renkli yuvarlatılmış zemin + ikon.
class ElementSimgesi extends StatelessWidget {
  final String element;
  final double boyut;
  /// Zemin olmadan yalnız ikon (satır içi kullanım).
  final bool sade;
  const ElementSimgesi(this.element, {super.key, this.boyut = 22, this.sade = false});

  @override
  Widget build(BuildContext context) {
    final ikon = ElementSistemi.ikonlar[element] ?? Icons.help_outline_rounded;
    final renk = ElementSistemi.renkler[element] ?? Colors.grey;
    if (sade) return Icon(ikon, size: boyut, color: renk);
    return Container(
      width: boyut, height: boyut,
      decoration: BoxDecoration(color: renk.withAlpha(36), borderRadius: BorderRadius.circular(boyut * 0.28)),
      child: Icon(ikon, size: boyut * 0.66, color: renk),
    );
  }
}

/// Cinsiyet simgesi: mavi ♂ / pembe ♀ ikon.
class CinsiyetSimgesi extends StatelessWidget {
  final bool isMale;
  final double boyut;
  final Color? renk;
  const CinsiyetSimgesi(this.isMale, {super.key, this.boyut = 18, this.renk});

  static Color rengi(bool isMale) => isMale ? const Color(0xFF1E88E5) : const Color(0xFFD81B60);

  @override
  Widget build(BuildContext context) =>
      Icon(isMale ? Icons.male_rounded : Icons.female_rounded, size: boyut, color: renk ?? rengi(isMale));
}
