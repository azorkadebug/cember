// Çember'e özel simgeler: her SVG ayrıştırılabiliyor mu, kalem anahtarı
// doğru simgeye mi düşüyor. Bozuk bir SVG ekranda hata vermeden boş
// kalır; bu yüzden ayrıştırma doğrudan sınanıyor.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cember/widgets/kalem_simgeleri.dart';

Widget _sar(Widget w) => MaterialApp(home: Scaffold(body: Center(child: w)));

Future<Size> _ayristir(WidgetTester tester, String svg) async {
  final bilgi = await tester.runAsync(() => vg.loadPicture(SvgStringLoader(svg), null));
  final boyut = bilgi!.size;
  bilgi.picture.dispose();
  return boyut;
}

void main() {
  for (final s in OzelSimge.values) {
    testWidgets('${s.name} SVG ayrıştırılır, 24×24', (tester) async {
      expect(await _ayristir(tester, ozelSimgeSvg(s)), const Size(24, 24));
    });
  }

  testWidgets('sınama bozuk SVG yakalıyor', (tester) async {
    Object? hata;
    await tester.runAsync(() async {
      try {
        await vg.loadPicture(const SvgStringLoader('<svg><path d="M9 3 Z <<"/></sv'), null);
      } catch (e) {
        hata = e;
      }
    });
    expect(hata, isNotNull);
  });

  testWidgets('16 pikselin altına inmez', (tester) async {
    await tester.pumpWidget(_sar(const OzelSimgeWidget(OzelSimge.mola, size: 12)));
    expect(tester.getSize(find.byType(SvgPicture)), const Size(16, 16));
  });

  testWidgets('özel çizimi olan kalem SVG, olmayan Material ikonu', (tester) async {
    await tester.pumpWidget(_sar(const Row(mainAxisSize: MainAxisSize.min, children: [
      KalemSimgesi('shirt'),
      KalemSimgesi('shoe'),
      KalemSimgesi('card'),
      KalemSimgesi('saglik'),
      KalemSimgesi('brush'),
    ])));
    expect(find.byType(SvgPicture), findsNWidgets(4));
    expect(find.byIcon(Icons.brush_rounded), findsOneWidget);
  });
}
