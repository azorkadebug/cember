// Skor ekranı yerleşim testi: 2/3/4 takım, dar/normal/yatay ekran, 1,0 ve
// 1,5 yazı ölçeği, normal ve sunum modu. Taşma (RenderFlex overflow) ya da
// başka bir çizim hatası olursa test düşer. Denetim #3'te 320 px'te 100+
// skorda düğmeler kartın dışına itiliyor, yatay telefonda sayaca
// ulaşılamıyordu; bu test o sınıf hataları yakalar.
import 'package:cember/models/ogrenci.dart';
import 'package:cember/screens/skor_ekrani.dart';
import 'package:cember/tema.dart';
import 'package:cember/tema_renkleri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<TakimBilgi> _takimlar(int n, {int skor = 0}) {
  const adlar = ['Kozmik Köfteciler', 'Roket Tavukları', 'Ayran United', 'Tahtaya Kalkmam', 'Kraker Komandoları', 'Patlayan Mısırlar'];
  const renkler = ['Kırmızı', 'Mavi', 'Sarı', 'Siyah', 'Yeşil', 'Turuncu'];
  return List.generate(n, (i) {
    final oyuncular = List.generate(
        7, (j) => Ogrenci(id: 't$i-$j', ad: 'Öğrenci Uzunsoyadlıoğlu $i$j', isMale: j.isEven));
    return TakimBilgi(
      isim: adlar[i],
      renkAdi: renkler[i],
      renk: AppTema.formaRengi(renkler[i]),
      oyuncular: oyuncular,
      kaptan: oyuncular.first,
      skor: skor,
    );
  });
}

Future<void> _fontYukle(String aile, List<String> dosyalar) async {
  final yukleyici = FontLoader(aile);
  for (final f in dosyalar) {
    yukleyici.addFont(rootBundle.load(f));
  }
  await yukleyici.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Testin varsayılan yazı tipi her harfi tam kare çizer, metinler gerçekte
  // olduğundan çok geniş ölçülür; gerçek fontlarla ölç.
  setUpAll(() async {
    await _fontYukle('Nunito', [for (final w in [400, 600, 700, 800, 900]) 'assets/fonts/Nunito-$w.ttf']);
    await _fontYukle('Fredoka', [for (final w in [500, 600, 700]) 'assets/fonts/Fredoka-$w.ttf']);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Ses ve ekran-uyanık eklentileri testte yok; sessizce yanıtla.
    for (final kanal in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
      m.setMockMethodCallHandler(MethodChannel(kanal), (_) async => null);
    }
    m.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]),
    );
  });

  const boyutlar = {
    'dar 320x568': Size(320, 568),
    'telefon 390x844': Size(390, 844),
    'yatay 844x390': Size(844, 390),
  };

  for (final b in boyutlar.entries) {
    for (final n in [2, 3, 4, 6]) {
      for (final olcek in [1.0, 1.5]) {
        for (final skor in [0, 105]) {
          testWidgets('${b.key}, $n takım, ölçek $olcek, skor $skor', (tester) async {
            tester.view.physicalSize = b.value;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(MaterialApp(
              theme: cemberTemasi(Brightness.light),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(olcek)),
                child: child!,
              ),
              home: SkorEkrani(takimlar: _takimlar(n, skor: skor)),
            ));
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull, reason: 'normal mod');

            // Sunum modu
            await tester.tap(find.byTooltip('Sunum modu'));
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull, reason: 'sunum modu');
          });
        }
      }
    }
  }
}
