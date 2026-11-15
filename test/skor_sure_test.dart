// Skor ekranı ↔ MacDurumu süre tutarlılığı (denetim #5 Y2/O3/D7).
// Süre MacDurumu'nda tek yerde; skor ekranı bandın ⏸/▶'ına ve ekran
// dışında biten süreye uymalı. Saat sahte: gerçek bekleme yok.
import 'package:cember/models/ogrenci.dart';
import 'package:cember/screens/skor_ekrani.dart';
import 'package:cember/services/mac_durumu.dart';
import 'package:cember/tema.dart';
import 'package:cember/tema_renkleri.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late DateTime simdi;
var alarmSayisi = 0;

List<TakimBilgi> _takimlar() => [
      for (final (i, renk) in [(0, 'Kırmızı'), (1, 'Mavi')])
        TakimBilgi(
          isim: 'Takım $i',
          renkAdi: renk,
          renk: AppTema.formaRengi(renk),
          oyuncular: [Ogrenci(id: 'o$i', ad: 'Oyuncu $i')],
        ),
    ];

/// Süre her rakamı ayrı kutuda çiziyor; okunur değer Semantics etiketinde.
Finder _sure(String metin) => find.bySemanticsLabel(metin);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<TakimBilgi> takimlar;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MacDurumu.tamTemizlik();
    simdi = DateTime(2026, 11, 15, 10);
    MacDurumu.saat = () => simdi;
    alarmSayisi = 0;
    MacDurumu.alarmCal = () => alarmSayisi++;
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final kanal in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
      m.setMockMethodCallHandler(MethodChannel(kanal), (_) async => null);
    }
    MacDurumu.kullaniciAyarla('uid_1');
    takimlar = _takimlar();
    MacDurumu().macBaslat('s1', takimlar);
  });

  Future<void> ac(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: cemberTemasi(Brightness.light),
      home: SkorEkrani(takimlar: takimlar),
    ));
    await tester.pump();
  }

  /// Ekranı kapatır; [bitir] ise maçı da bitirir (MacDurumu'nun bitiş
  /// zamanlayıcısı test sonunda bekleyen Timer bırakmasın).
  Future<void> kapat(WidgetTester tester, {bool bitir = true}) async {
    await tester.pumpWidget(const SizedBox());
    if (bitir) MacDurumu().macBitir();
  }

  // Zemindeki daireler sürekli canlandığı için pumpAndSettle bitmiyor.
  Future<void> bekle(WidgetTester tester) => tester.pump(const Duration(milliseconds: 500));

  tearDown(() => MacDurumu().macBitir());

  testWidgets('Y2: bant ⏸ basılınca skor ekranı BAŞLAT gösterir, süre donar; ▶ ile DURDUR', (tester) async {
    final mac = MacDurumu();
    mac.sureAyarla(300);
    mac.baslat();
    simdi = simdi.add(const Duration(seconds: 3));
    await ac(tester);
    expect(find.text('DURDUR'), findsOneWidget);
    expect(_sure('04:57'), findsOneWidget);

    mac.duraklat(); // Sınıflarım bandındaki ⏸ (ekran açıkken de aynı yol)
    await tester.pump();
    simdi = simdi.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('BAŞLAT'), findsOneWidget);
    expect(_sure('04:57'), findsOneWidget);

    mac.devamEt();
    await tester.pump();
    simdi = simdi.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('DURDUR'), findsOneWidget);
    expect(_sure('04:52'), findsOneWidget);
    await kapat(tester);
  });

  testWidgets('O3: ekran açıkken biterse katman açılır; düdük MacDurumu’ndan bir kez', (tester) async {
    final mac = MacDurumu();
    mac.sureAyarla(30);
    mac.baslat();
    await ac(tester);
    simdi = simdi.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('SÜRE BİTTİ'), findsWidgets);
    expect(alarmSayisi, 1);
    await kapat(tester);
  });

  testWidgets('O3: ekran dışında bitmişse dönüşte katman yeniden açılmaz, alarm tekrar çalmaz', (tester) async {
    final mac = MacDurumu();
    mac.sureAyarla(30);
    mac.baslat();
    simdi = simdi.add(const Duration(seconds: 40));
    mac.kontrolEt(); // bitiş zamanlayıcısı ekran dışında tetiklendi
    expect(alarmSayisi, 1);
    await ac(tester);
    expect(find.text('Kapatmak için dokun'), findsNothing);
    expect(find.text('SÜRE BİTTİ'), findsOneWidget); // yalnız düğme etiketi
    expect(alarmSayisi, 1);
    await kapat(tester);
  });

  testWidgets('D7: mola skor ekranından çıkıp dönünce kaldığı yerden sürer', (tester) async {
    await ac(tester);
    await tester.tap(find.text('Mola').first);
    await bekle(tester);
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Oyuncu 0')));
    await bekle(tester);
    expect(MacDurumu().molalar.length, 1);
    await kapat(tester, bitir: false);

    simdi = simdi.add(const Duration(seconds: 30));
    await ac(tester);
    expect(find.text('Mola (1)'), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
    await kapat(tester);
  });
}
