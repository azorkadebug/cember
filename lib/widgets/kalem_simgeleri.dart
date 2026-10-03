import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/kontrol_kalemi.dart';
import '../tema.dart';

/// Çember'e özel çizilmiş simgeler (tasarım sistemi: KalemSimgeleri,
/// `design/tasarim-sistemi/assets/Simgeler/`).
///
/// Material'da Kıyafet, Ayakkabı, Sarı Kart, Sağlık ve Mola'yı doğru
/// anlatan simge yoktu (`checkroom`, `directions_run`, `style`,
/// `medical_services`, `front_hand`). 24×24 ızgara, dolu, yumuşak köşe:
/// Material Icons Round'un yanında aynı ailedenmiş gibi durur.
enum OzelSimge { kiyafet, ayakkabi, sariKart, saglik, mola }

/// SVG kaynakları, tasarım sistemindeki dosyaların aynısı (yalnız `fill`
/// rengi atıldı; renk [ColorFilter] ile veriliyor). Dosyadan değil
/// dizgeden okunuyor: ilk çizimde varlık yükleme gecikmesi olmasın.
const Map<OzelSimge, String> _svgler = {
  OzelSimge.kiyafet:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M9 3.2C9.6 4.6 10.7 5.4 12 5.4S14.4 4.6 15 3.2L19.6 5C20.3 5.3 20.8 5.8 21.1 6.5L22.4 9.6C22.6 10.1 22.4 10.6 21.9 10.8L19.2 12C18.7 12.2 18.2 12 18 11.5V19.5C18 20.3 17.3 21 16.5 21H7.5C6.7 21 6 20.3 6 19.5V11.5C5.8 12 5.3 12.2 4.8 12L2.1 10.8C1.6 10.6 1.4 10.1 1.6 9.6L2.9 6.5C3.2 5.8 3.7 5.3 4.4 5Z"/></svg>',
  OzelSimge.ayakkabi:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M3.5 6C4.3 6 5 6.6 5 7.4V8C5 9.1 5.9 10 7 10C8.4 10 9.4 9 9.6 7.7L9.8 6.6L14 9.8L18.6 12.3C20.9 13.4 22 14.6 22 16.3V17H2V7.5C2 6.7 2.7 6 3.5 6ZM12 9.85A.8.8 0 1 0 12 11.45A.8.8 0 1 0 12 9.85ZM14.4 11.2A.8.8 0 1 0 14.4 12.8A.8.8 0 1 0 14.4 11.2ZM16.8 12.5A.8.8 0 1 0 16.8 14.1A.8.8 0 1 0 16.8 12.5Z"/><path d="M2 18.5H22V19C22 20.1 21.1 21 20 21H4C2.9 21 2 20.1 2 19Z"/></svg>',
  OzelSimge.sariKart:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect x="8" y="3" width="11" height="16" rx="2" transform="rotate(12 13.5 11)"/><rect x="1.5" y="8.5" width="5" height="2" rx="1"/><rect x="2.5" y="12.5" width="3.5" height="2" rx="1"/></svg>',
  OzelSimge.saglik:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill-rule="evenodd" d="M9 3.5H15A1.5 1.5 0 0 1 16.5 5V7H14.5V5.5H9.5V7H7.5V5A1.5 1.5 0 0 1 9 3.5ZM4 7H20A2 2 0 0 1 22 9V19A2 2 0 0 1 20 21H4A2 2 0 0 1 2 19V9A2 2 0 0 1 4 7ZM11 10.5V13H8.5V15H11V17.5H13V15H15.5V13H13V10.5Z"/></svg>',
  OzelSimge.mola:
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect x="9.5" y="1.5" width="5" height="2.2" rx="1.1"/><rect x="11" y="3" width="2" height="3"/><rect x="17.1" y="5.7" width="2.2" height="3.4" rx="1.1" transform="rotate(45 18.2 7.4)"/><path fill-rule="evenodd" d="M12 5.5A8 8 0 1 1 12 21.5A8 8 0 1 1 12 5.5ZM10 10A1 1 0 0 0 9 11V16A1 1 0 0 0 11 16V11A1 1 0 0 0 10 10ZM14 10A1 1 0 0 0 13 11V16A1 1 0 0 0 15 16V11A1 1 0 0 0 14 10Z"/></svg>',
};

/// Testler her kaynağın ayrıştırılabildiğini doğrulasın diye.
@visibleForTesting
String ozelSimgeSvg(OzelSimge s) => _svgler[s]!;

/// Tasarım sisteminin alt sınırı: 16'nın altında ayrıntılar kayboluyor.
const double _enKucuk = 16;

/// [Icon] gibi davranır: renk ve boyut verilmezse çevredeki [IconTheme]'den.
class OzelSimgeWidget extends StatelessWidget {
  final OzelSimge simge;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  const OzelSimgeWidget(this.simge, {super.key, this.size, this.color, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final boyut = (size ?? tema.size ?? 24).clamp(_enKucuk, double.infinity).toDouble();
    final renk = color ?? tema.color ?? AppTema.ana;
    return SvgPicture.string(
      _svgler[simge]!,
      width: boyut,
      height: boyut,
      colorFilter: ColorFilter.mode(renk, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}

/// Kalem ikon anahtarından özel simge; karşılığı olmayanlar (Resim, Müzik
/// vb. branşların kalemleri) Material ikonunda kalır.
const Map<String, OzelSimge> _kalemOzelSimgeleri = {
  'shirt': OzelSimge.kiyafet,
  'shoe': OzelSimge.ayakkabi,
  'card': OzelSimge.sariKart,
  // Kalem değil ama aynı yerlerde (sayaç rozeti, öğrenci kartı) duruyor.
  'saglik': OzelSimge.saglik,
};

/// Bir kontrol kaleminin simgesi: Çember'e özel çizim varsa o, yoksa
/// [kalemIkonu]'nun Material ikonu.
class KalemSimgesi extends StatelessWidget {
  final String anahtar;
  final double? size;
  final Color? color;
  const KalemSimgesi(this.anahtar, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final ozel = _kalemOzelSimgeleri[anahtar];
    if (ozel != null) return OzelSimgeWidget(ozel, size: size, color: color);
    return Icon(kalemIkonu(anahtar), size: size, color: color);
  }
}


// ---------------------------------------------------------------------------
// Öğrenci satırındaki renkli çıkartmalar (Teneffüs, 2026-10-04): kare/çerçeve
// yok, şeklin kendisi mürekkep kenarlı ve renkli — sarı kart etiketiyle aynı
// dil. "Kıyafet eksik" yazısının yerine (Sabri).
// ---------------------------------------------------------------------------
const String _tisortCikartma = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="-1 0 26 24"><path d="M9 3.2C9.6 4.6 10.7 5.4 12 5.4S14.4 4.6 15 3.2L19.6 5C20.3 5.3 20.8 5.8 21.1 6.5L22.4 9.6C22.6 10.1 22.4 10.6 21.9 10.8L19.2 12C18.7 12.2 18.2 12 18 11.5V19.5C18 20.3 17.3 21 16.5 21H7.5C6.7 21 6 20.3 6 19.5V11.5C5.8 12 5.3 12.2 4.8 12L2.1 10.8C1.6 10.6 1.4 10.1 1.6 9.6L2.9 6.5C3.2 5.8 3.7 5.3 4.4 5Z" fill="#4FA3F7" stroke="#1F2430" stroke-width="1.7" stroke-linejoin="round"/><path d="M9 3.2C9.6 4.6 10.7 5.4 12 5.4S14.4 4.6 15 3.2" fill="none" stroke="#1F2430" stroke-width="1.7" stroke-linecap="round"/></svg>''';
const String _ayakkabiCikartma = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 2 24 21"><path d="M3.5 6C4.3 6 5 6.6 5 7.4V8C5 9.1 5.9 10 7 10C8.4 10 9.4 9 9.6 7.7L9.8 6.6L14 9.8L18.6 12.3C20.9 13.4 22 14.6 22 16.3V17.6H2V7.5C2 6.7 2.7 6 3.5 6Z" fill="#FFA63D" stroke="#1F2430" stroke-width="1.6" stroke-linejoin="round"/><circle cx="12" cy="10.9" r=".95" fill="#1F2430"/><circle cx="14.4" cy="12.3" r=".95" fill="#1F2430"/><circle cx="16.8" cy="13.6" r=".95" fill="#1F2430"/><path d="M2 17.6H22V18.8C22 20.1 21.1 21 20 21H4C2.9 21 2 20.1 2 18.8Z" fill="#FFFFFF" stroke="#1F2430" stroke-width="1.6" stroke-linejoin="round"/></svg>''';
const String _notCikartma = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M5 3.5H15.5L20 8V19.5C20 20.3 19.3 21 18.5 21H5.5C4.7 21 4 20.3 4 19.5V4.5C4 3.9 4.4 3.5 5 3.5Z" fill="#FFD84D" stroke="#1F2430" stroke-width="1.7" stroke-linejoin="round"/><path d="M15.5 3.5V7C15.5 7.6 15.9 8 16.5 8H20" fill="#FFF2B0" stroke="#1F2430" stroke-width="1.7" stroke-linejoin="round"/><path d="M7.5 12H16M7.5 15.5H13.5" stroke="#1F2430" stroke-width="1.6" stroke-linecap="round"/></svg>''';

/// Eksik/sayaç kalemi çıkartması. Kıyafet ve ayakkabı renkli çizim; diğer
/// kalemler mürekkep renkli simge. [sayi] 2 ve üstündeyse köşede rozet.
class KalemCikartmasi extends StatelessWidget {
  final String anahtar;
  final int sayi;
  final double boyut;
  const KalemCikartmasi(this.anahtar, {super.key, this.sayi = 1, this.boyut = 30});

  @override
  Widget build(BuildContext context) {
    final Widget sekil = switch (anahtar) {
      'shirt' => SvgPicture.string(_tisortCikartma, width: boyut, height: boyut),
      'shoe' => SvgPicture.string(_ayakkabiCikartma, width: boyut * 1.05, height: boyut),
      _ => KalemSimgesi(anahtar, size: boyut * 0.85, color: AppTema.ana),
    };
    if (sayi < 2) return sekil;
    return Stack(clipBehavior: Clip.none, children: [
      sekil,
      Positioned(
        right: -5,
        top: -5,
        child: Container(
          constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
          padding: const EdgeInsets.symmetric(horizontal: 3),
          alignment: Alignment.center,
          decoration: const ShapeDecoration(color: AppTema.ana, shape: StadiumBorder()),
          child: Text('$sayi',
              textScaler: TextScaler.noScaling,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, height: 1.1)),
        ),
      ),
    ]);
  }
}

/// Öğrencinin notu varsa listede görünen sarı not kâğıdı.
class NotCikartmasi extends StatelessWidget {
  final double boyut;
  const NotCikartmasi({super.key, this.boyut = 26});

  @override
  Widget build(BuildContext context) =>
      Transform.rotate(angle: -0.12, child: SvgPicture.string(_notCikartma, width: boyut, height: boyut));
}
