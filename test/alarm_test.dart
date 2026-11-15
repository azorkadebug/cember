// Mola / süre bitişi için telefon alarmı (AlarmKit / yerel bildirim) ve
// skor ekranı dışında biten molanın uygulama içi duyurusu.
//
// Yerel kanal sahte: gönderilen alarm listeleri kaydedilir. Saat enjekte;
// mola zamanlayıcısı testWidgets'ın sahte zamanında ilerletilir.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cember/models/ogrenci.dart';
import 'package:cember/screens/skor_ekrani.dart' show TakimBilgi;
import 'package:cember/services/alarm_servisi.dart';
import 'package:cember/services/mac_durumu.dart';

late DateTime simdi;
var alarmSayisi = 0;
final gonderilenler = <List<Map<String, Object>>>[];
String yerelYanit = 'alarmkit';
final duyurular = <String>[];

final _ayse = Ogrenci(id: 'a1', ad: 'Ayşe', isMale: false);
final _ali = Ogrenci(id: 'a2', ad: 'Ali');

MacDurumu _mac() {
  MacDurumu.kullaniciAyarla('uid_1');
  final m = MacDurumu();
  m.macBaslat('s1', [
    TakimBilgi(isim: 'A', renkAdi: 'Kırmızı', renk: Colors.red, oyuncular: [_ayse, _ali], kaptan: _ayse),
  ]);
  return m;
}

Future<void> _bekle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> get _sonKimlikler =>
    gonderilenler.isEmpty ? const [] : gonderilenler.last.map((a) => a['id'] as String).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AlarmServisi.sifirla();
    AlarmServisi.destekleniyor = () => true;
    yerelYanit = 'alarmkit';
    gonderilenler.clear();
    AlarmServisi.gonder = (liste) async {
      gonderilenler.add(liste);
      return yerelYanit;
    };
    await MacDurumu.tamTemizlik();
    simdi = DateTime(2026, 11, 15, 10);
    MacDurumu.saat = () => simdi;
    alarmSayisi = 0;
    MacDurumu.alarmCal = () => alarmSayisi++;
    MacDurumu.skorEkraniSayisi = 0;
    duyurular.clear();
    MacDurumu.molaBittiDuyuru = (renk, o) => duyurular.add('$renk:${o.ad}');
  });

  tearDown(() async {
    MacDurumu().macBitir();
    await _bekle();
    AlarmServisi.sifirla();
  });

  group('Telefona kurulan alarmlar', () {
    test('mola eklenince alarm kurulur; metinde öğrenci adı YOK, takım rengi var', () async {
      final m = _mac();
      m.molaEkle(0, 'a1');
      await _bekle();
      final mola = gonderilenler.last.single;
      expect(mola['id'], 'mola_a1');
      expect(mola['baslik'], 'Mola bitti');
      expect(mola['govde'], contains('Kırmızı'));
      expect(mola['govde'], isNot(contains('Ayşe')));
      expect(mola['zaman'], simdi.add(const Duration(seconds: 120)).millisecondsSinceEpoch);
    });

    test('süre başlayınca kurulur; durdur, bant ⏸ ve sıfırla iptal eder', () async {
      final m = _mac();
      m.sureAyarla(300);
      m.baslat();
      await _bekle();
      expect(_sonKimlikler, ['sure']);
      m.durdur();
      await _bekle();
      expect(_sonKimlikler, isEmpty);
      m.baslat();
      await _bekle();
      expect(_sonKimlikler, ['sure']);
      m.duraklat();
      await _bekle();
      expect(_sonKimlikler, isEmpty);
      m.devamEt();
      await _bekle();
      expect(_sonKimlikler, ['sure']);
      m.sifirla();
      await _bekle();
      expect(_sonKimlikler, isEmpty);
    });

    test('devam edince yeni bitiş anıyla yeniden kurulur', () async {
      final m = _mac();
      m.sureAyarla(300);
      m.baslat();
      await _bekle();
      final ilk = gonderilenler.last.single['zaman'] as int;
      simdi = simdi.add(const Duration(seconds: 60));
      m.durdur();
      simdi = simdi.add(const Duration(seconds: 30));
      m.baslat();
      await _bekle();
      expect(gonderilenler.last.single['zaman'], ilk + 30 * 1000);
    });

    test('mola iptali, maç bitişi ve çıkış alarmları kaldırır', () async {
      final m = _mac();
      final mola = m.molaEkle(0, 'a1');
      m.molaEkle(0, 'a2');
      await _bekle();
      expect(_sonKimlikler, ['mola_a1', 'mola_a2']);
      m.molaKaldir(mola);
      await _bekle();
      expect(_sonKimlikler, ['mola_a2']);
      m.macBitir();
      await _bekle();
      expect(_sonKimlikler, isEmpty);

      _mac().molaEkle(0, 'a1');
      await _bekle();
      expect(_sonKimlikler, ['mola_a1']);
      await MacDurumu.tamTemizlik();
      await _bekle();
      expect(_sonKimlikler, isEmpty);
    });

    test('liste değişmediyse yerel tarafa tekrar gidilmez', () async {
      final m = _mac();
      m.molaEkle(0, 'a1');
      await _bekle();
      final sayi = gonderilenler.length;
      await m.kaydet();
      await m.kaydet();
      await _bekle();
      expect(gonderilenler.length, sayi);
    });

    test('web/Android: yerel tarafa hiç gidilmez', () async {
      AlarmServisi.destekleniyor = () => false;
      _mac().molaEkle(0, 'a1');
      await _bekle();
      expect(gonderilenler, isEmpty);
      expect(AlarmServisi.yol, AlarmYolu.yok);
    });

    test('yerel hata uygulamayı durdurmaz, yol "yok" olur', () async {
      AlarmServisi.gonder = (_) async => throw Exception('kanal yok');
      _mac().molaEkle(0, 'a1');
      await _bekle();
      expect(AlarmServisi.yol, AlarmYolu.yok);
    });
  });

  group('Uygulama içi düdük iki kez çalmasın', () {
    test('AlarmKit: telefon çalıyor, uygulama düdüğü çalmaz', () async {
      final m = _mac();
      m.sureAyarla(60);
      m.baslat();
      await _bekle();
      expect(AlarmServisi.yol, AlarmYolu.alarmKit);
      simdi = simdi.add(const Duration(seconds: 61));
      expect(m.kontrolEt(), isTrue);
      expect(alarmSayisi, 0);
    });

    test('Bildirim: zamanında (uygulama önde) düdük çalar; geç fark edildiyse çalmaz', () async {
      yerelYanit = 'bildirim';
      final m = _mac();
      m.sureAyarla(60);
      m.baslat();
      await _bekle();
      expect(AlarmServisi.yol, AlarmYolu.bildirim);
      simdi = simdi.add(const Duration(seconds: 60));
      expect(m.kontrolEt(), isTrue);
      expect(alarmSayisi, 1);

      m.sifirla();
      m.baslat();
      await _bekle();
      simdi = simdi.add(const Duration(minutes: 5)); // arka plandan dönüş
      expect(m.kontrolEt(), isTrue);
      expect(alarmSayisi, 1);
    });

    test('Yerel alarm yok (izin reddi): düdük her zaman çalar', () async {
      yerelYanit = 'yok';
      final m = _mac();
      m.sureAyarla(60);
      m.baslat();
      await _bekle();
      simdi = simdi.add(const Duration(minutes: 5));
      expect(m.kontrolEt(), isTrue);
      expect(alarmSayisi, 1);
    });
  });

  group('Skor ekranı dışında biten mola', () {
    testWidgets('duyurulur, mola düşer, (yerel alarm yoksa) düdük çalar', (tester) async {
      yerelYanit = 'yok';
      final m = _mac();
      m.molaEkle(0, 'a1');
      await tester.runAsync(_bekle);
      simdi = simdi.add(const Duration(seconds: 120));
      await tester.pump(const Duration(seconds: 121));
      expect(duyurular, ['Kırmızı:Ayşe']);
      expect(m.molalar, isEmpty);
      expect(alarmSayisi, 1);
    });

    testWidgets('AlarmKit varken duyurulur ama düdük çalmaz', (tester) async {
      final m = _mac();
      m.molaEkle(0, 'a1');
      await tester.runAsync(_bekle);
      simdi = simdi.add(const Duration(seconds: 120));
      await tester.pump(const Duration(seconds: 121));
      expect(duyurular, ['Kırmızı:Ayşe']);
      expect(alarmSayisi, 0);
    });

    testWidgets('skor ekranı açıkken dokunmaz (ekran kendisi bitirir)', (tester) async {
      MacDurumu.skorEkraniSayisi = 1;
      final m = _mac();
      m.molaEkle(0, 'a1');
      simdi = simdi.add(const Duration(seconds: 120));
      await tester.pump(const Duration(seconds: 121));
      expect(duyurular, isEmpty);
      expect(m.molalar, hasLength(1));
    });

    testWidgets('erken iptal edilen mola duyurulmaz', (tester) async {
      final m = _mac();
      final mola = m.molaEkle(0, 'a1');
      m.molaKaldir(mola);
      simdi = simdi.add(const Duration(seconds: 120));
      await tester.pump(const Duration(seconds: 121));
      expect(duyurular, isEmpty);
    });

    testWidgets('yeniden açılışta süren mola yine izlenir', (tester) async {
      final m = _mac();
      m.molaEkle(0, 'a1');
      await tester.pump();
      final ham = (await SharedPreferences.getInstance()).getString('aktif_mac_uid_1')!;
      await MacDurumu.tamTemizlik();
      SharedPreferences.setMockInitialValues({'aktif_mac_uid_1': ham});
      MacDurumu.ogrenciKaynagi = (uid, sinifId) async => [_ayse, _ali];
      simdi = simdi.add(const Duration(seconds: 30));
      expect(await MacDurumu().yukle('uid_1'), isTrue);
      expect(duyurular, isEmpty);
      simdi = simdi.add(const Duration(seconds: 90));
      await tester.pump(const Duration(seconds: 91));
      expect(duyurular, ['Kırmızı:Ayşe']);
    });
  });
}
