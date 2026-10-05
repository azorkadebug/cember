// "Yenilikler" penceresi: sürüm başına bir kez açılır, tanıtımı yeni
// bitiren kullanıcıya hiç çıkmaz, dar ekranda ve büyük yazıda taşmaz.
import 'package:cember/tema_renkleri.dart';
import 'package:cember/widgets/yenilikler_penceresi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _fontYukle(String aile, List<String> dosyalar) async {
  final yukleyici = FontLoader(aile);
  for (final f in dosyalar) {
    yukleyici.addFont(rootBundle.load(f));
  }
  await yukleyici.load();
}

/// Sınıflarım'ın açılışta yaptığını yapan en küçük ekran.
class _Acilis extends StatefulWidget {
  const _Acilis();
  @override
  State<_Acilis> createState() => _AcilisState();
}

class _AcilisState extends State<_Acilis> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) YeniliklerPenceresi.gerekirseGoster(context);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Sınıflarım'));
}

Widget _uygulama({Brightness parlaklik = Brightness.light, double olcek = 1.0}) => MaterialApp(
      theme: cemberTemasi(parlaklik),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(olcek)),
        child: child!,
      ),
      home: const _Acilis(),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _fontYukle('Nunito', [for (final w in [400, 600, 700, 800, 900]) 'assets/fonts/Nunito-$w.ttf']);
    await _fontYukle('Fredoka', [for (final w in [500, 600, 700]) 'assets/fonts/Fredoka-$w.ttf']);
  });

  testWidgets('önceki sürümü kullanan öğretmene bir kez açılır', (tester) async {
    SharedPreferences.setMockInitialValues({'tanitim_goruldu_v1_1': true});
    await tester.pumpWidget(_uygulama());
    await tester.pumpAndSettle();
    expect(find.text("Çember'deki yenilikler"), findsOneWidget);

    await tester.tap(find.text('Devam et'));
    await tester.pumpAndSettle();
    expect(find.text("Çember'deki yenilikler"), findsNothing);

    // Uygulama yeniden açılınca çıkmaz.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_uygulama());
    await tester.pumpAndSettle();
    expect(find.text("Çember'deki yenilikler"), findsNothing);
  });

  testWidgets('X ile kapanır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(_uygulama());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kapat'));
    await tester.pumpAndSettle();
    expect(find.text("Çember'deki yenilikler"), findsNothing);
  });

  testWidgets('tanıtımı yeni bitiren kullanıcıya çıkmaz', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await YeniliklerPenceresi.goruldueIsaretle(); // tanitim_ekrani _bitir()
    await tester.pumpWidget(_uygulama());
    await tester.pumpAndSettle();
    expect(find.text("Çember'deki yenilikler"), findsNothing);
  });

  testWidgets('eski sürümün kaydı varsa yeni sürümde yine açılır', (tester) async {
    SharedPreferences.setMockInitialValues({'yenilikler_gorulen_surum': '1.1.0'});
    await tester.pumpWidget(_uygulama());
    await tester.pumpAndSettle();
    expect(find.text("Çember'deki yenilikler"), findsOneWidget);
  });

  const boyutlar = {
    'dar 320x568': Size(320, 568),
    'telefon 390x844': Size(390, 844),
    'yatay 844x390': Size(844, 390),
    'iPad 1024x1366': Size(1024, 1366),
  };
  for (final b in boyutlar.entries) {
    for (final olcek in [1.0, 1.5, 2.0]) {
      for (final p in Brightness.values) {
        testWidgets('${b.key}, ölçek $olcek, ${p.name}: taşmaz', (tester) async {
          tester.view.physicalSize = b.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          SharedPreferences.setMockInitialValues({});
          await tester.pumpWidget(_uygulama(parlaklik: p, olcek: olcek));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Devam et'), findsOneWidget);
          // Düğmeye kaydırarak ulaşılabiliyor ve basılabiliyor.
          await tester.ensureVisible(find.text('Devam et'));
          await tester.tap(find.text('Devam et'));
          await tester.pumpAndSettle();
          expect(find.text("Çember'deki yenilikler"), findsNothing);
        });
      }
    }
  }
}
