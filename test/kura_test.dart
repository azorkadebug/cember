import 'package:cember/models/ogrenci.dart';
import 'package:cember/screens/kura_ekrani.dart';
import 'package:cember/tema_renkleri.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('kura: gelmeyen çıkmaz, tekrar yokken herkes bir kez çıkar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final ogrenciler = [
      for (var i = 0; i < 5; i++) Ogrenci(id: 'o$i', ad: 'Öğrenci $i', isMale: i.isEven),
    ];
    await tester.pumpWidget(MaterialApp(
      theme: cemberTemasi(Brightness.light),
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true, size: Size(390, 844)),
        child: KuraEkrani(sinifId: 's1', ogrenciler: ogrenciler, gelmeyenler: const {'o4'}, renkler: const {}),
      ),
    ));
    await tester.pump();
    final cikanlar = <String>{};
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byIcon(Icons.casino_rounded));
      await tester.pump(const Duration(milliseconds: 400));
      final ad = ogrenciler.firstWhere((o) => find.text(o.ad).evaluate().isNotEmpty).ad;
      cikanlar.add(ad);
    }
    expect(cikanlar.length, 4, reason: 'tekrar yok: 4 gelen 4 farklı');
    expect(cikanlar.contains('Öğrenci 4'), isFalse, reason: 'gelmeyen kuraya girmez');
    expect(find.text('4 / 4 çekildi'), findsOneWidget);
  });

  testWidgets('kura: dünden kalan buradaMi:false kurayı daraltmaz (denetim #5 Y1)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // Eski belge: tarihsiz `buradaMi:false` kalmış, bugün yoklamada yok yazılmamış.
    final ogrenciler = [
      for (var i = 0; i < 5; i++) Ogrenci(id: 'o$i', ad: 'Öğrenci $i', isMale: i.isEven),
    ]..[4].buradaMi = false;
    await tester.pumpWidget(MaterialApp(
      theme: cemberTemasi(Brightness.light),
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true, size: Size(390, 844)),
        child: KuraEkrani(sinifId: 's2', ogrenciler: ogrenciler, renkler: const {}),
      ),
    ));
    await tester.pump();
    expect(find.text('0 / 5 çekildi'), findsOneWidget);
  });
}
