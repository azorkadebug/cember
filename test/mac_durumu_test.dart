// Denetim #3 / Ajan E — MacDurumu (yerel maç kaydı) birim testleri.
//
// SharedPreferences sahte depo ile çalışır; Firestore'a dokunmaz (öğrenci
// kaynağı sahte). Saat enjekte edilir: zaman gerçek bekleme olmadan ileri
// alınır (denetim #5 Y2/Y3/O3/O2/D7).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cember/models/ogrenci.dart';
import 'package:cember/screens/skor_ekrani.dart' show TakimBilgi;
import 'package:cember/services/mac_durumu.dart';

TakimBilgi _takim(String isim, List<Ogrenci> oyuncular) => TakimBilgi(
      isim: isim,
      renkAdi: 'Kırmızı',
      renk: Colors.red,
      oyuncular: oyuncular,
      kaptan: oyuncular.firstOrNull,
    );

late DateTime simdi;
var alarmSayisi = 0;

void _ileri(int saniye) => simdi = simdi.add(Duration(seconds: saniye));

/// kaydet() bekletilmeden çağrılıyor; sahte depoya yazmasının bitmesini bekle.
Future<void> _bekle() => Future<void>.delayed(Duration.zero);

Future<String?> _ham() async =>
    (await SharedPreferences.getInstance()).getString('aktif_mac_uid_1');

final _siniflar = {
  's1': [Ogrenci(id: 'a1', ad: 'Ayşe', isMale: false), Ogrenci(id: 'a2', ad: 'Ali')],
  's2': [Ogrenci(id: 'b1', ad: 'Zeynep', isMale: false), Ogrenci(id: 'b2', ad: 'Mert')],
};

MacDurumu _aktifMac({bool yarisma = false}) {
  MacDurumu.kullaniciAyarla('uid_1');
  final m = MacDurumu();
  if (yarisma) {
    m.macBaslat('s1', [_takim('7-A', [..._siniflar['s1']!]), _takim('7-B', [..._siniflar['s2']!])],
        ekSinifIdler: ['s2']);
  } else {
    m.macBaslat('s1', [_takim('A', [..._siniflar['s1']!])]);
  }
  return m;
}

/// Sayfa yenileme / uygulamanın kapanıp açılması: bellek silinir, yalnız
/// diskteki kayıt kalır; [sonra] saniye geçer, kayıt yeniden yüklenir.
Future<void> _yenidenAc({required int sonra}) async {
  await _bekle();
  final ham = await _ham();
  await MacDurumu.tamTemizlik();
  SharedPreferences.setMockInitialValues({'aktif_mac_uid_1': ?ham});
  _ileri(sonra);
  expect(await MacDurumu().yukle('uid_1'), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MacDurumu.tamTemizlik();
    simdi = DateTime(2026, 11, 15, 10);
    MacDurumu.saat = () => simdi;
    alarmSayisi = 0;
    MacDurumu.alarmCal = () => alarmSayisi++;
    MacDurumu.ogrenciKaynagi = (uid, sinifId) async => [..._siniflar[sinifId] ?? const <Ogrenci>[]];
  });

  tearDown(() => MacDurumu().macBitir());

  group('Süre (bitiş anına bağlı)', () {
    test('çalışırken kalan = bitiş − şimdi; diske her saniye yazılmaz', () async {
      final m = _aktifMac();
      m.sureAyarla(300);
      m.baslat();
      await _bekle();
      final yazilan = await _ham();
      _ileri(10);
      expect(m.kalanSaniye, 290);
      expect(m.timerCalisiyor, isTrue);
      await _bekle();
      expect(await _ham(), yazilan); // zaman geçti ama yazma yok
    });

    test('Y2: bant ⏸ süreyi gerçekten durdurur, ▶ kaldığı yerden sürdürür', () async {
      final m = _aktifMac();
      m.sureAyarla(300);
      m.baslat();
      _ileri(3);
      m.duraklat();
      expect(m.duraklatildi, isTrue);
      expect(m.timerCalisiyor, isFalse, reason: 'skor ekranında BAŞLAT görünmeli');
      expect(m.kalanSaniye, 297);
      _ileri(10);
      expect(m.kalanSaniye, 297, reason: 'duraklatılmışken süre akmamalı');
      m.devamEt();
      expect(m.duraklatildi, isFalse);
      expect(m.timerCalisiyor, isTrue);
      _ileri(5);
      expect(m.kalanSaniye, 292);
    });

    test('Y2: süre zaten durmuşken ⏸/▶ süreyi kendiliğinden başlatmaz', () {
      final m = _aktifMac();
      m.sureAyarla(120);
      m.duraklat();
      m.devamEt();
      expect(m.timerCalisiyor, isFalse);
      expect(m.kalanSaniye, 120);
    });

    test('Y2: duraklatma diske yazılır, yeniden açılışta da duraklatılmış', () async {
      final m = _aktifMac();
      m.sureAyarla(300);
      m.baslat();
      _ileri(20);
      m.duraklat();
      await _yenidenAc(sonra: 60);
      expect(m.duraklatildi, isTrue);
      expect(m.timerCalisiyor, isFalse);
      expect(m.kalanSaniye, 280);
      m.devamEt();
      expect(m.timerCalisiyor, isTrue);
    });

    test('Y3: skor ekranı açıkken yenilenirse süre gerçek geçen zamana göre devam eder', () async {
      final m = _aktifMac();
      m.sureAyarla(300);
      m.baslat();
      _ileri(42);
      m.takimlar!.first.skor = 2;
      await m.kaydet(); // skor değişimi: süre alanları bayat olmamalı
      await _yenidenAc(sonra: 20);
      expect(m.takimlar!.first.skor, 2);
      expect(m.timerCalisiyor, isTrue);
      expect(m.kalanSaniye, 300 - 42 - 20);
      expect(alarmSayisi, 0);
    });

    test('Y3: her değişim anında yazılır (süre seçimi, başlat, durdur, sıfırla)', () async {
      final m = _aktifMac();
      Future<Map<String, dynamic>> kayit() async {
        await _bekle();
        return jsonDecode((await _ham())!) as Map<String, dynamic>;
      }

      m.sureAyarla(180);
      expect((await kayit())['toplamSaniye'], 180);
      m.baslat();
      expect((await kayit())['bitis'], isNotNull);
      _ileri(30);
      m.durdur();
      final d = await kayit();
      expect(d['timerCalisiyor'], isFalse);
      expect(d['kalanSaniye'], 150);
      m.sifirla();
      expect((await kayit())['kalanSaniye'], 180);
    });

    test('Y3: çalışırken kapanıp süre dolduktan sonra açılırsa "süre bitti", alarm çalmaz', () async {
      final m = _aktifMac();
      m.sureAyarla(60);
      m.baslat();
      await _yenidenAc(sonra: 600);
      expect(m.timerBitti, isTrue);
      expect(m.timerCalisiyor, isFalse);
      expect(m.kalanSaniye, 0);
      expect(alarmSayisi, 0);
    });

    test('O3: süre ekran dışında dolunca alarm bir kez çalar, bitti durumuna geçer', () {
      final m = _aktifMac();
      var bildirim = 0;
      void dinle() => bildirim++;
      m.addListener(dinle);
      addTearDown(() => m.removeListener(dinle));
      m.sureAyarla(30);
      m.baslat();
      _ileri(29);
      expect(m.kontrolEt(), isFalse);
      expect(alarmSayisi, 0);
      _ileri(1);
      bildirim = 0;
      expect(m.kontrolEt(), isTrue);
      expect(alarmSayisi, 1);
      expect(m.timerBitti, isTrue);
      expect(bildirim, greaterThan(0), reason: 'bant yeniden çizilmeli');
      expect(m.kontrolEt(), isFalse);
      expect(alarmSayisi, 1, reason: 'alarm yalnız bir kez');
    });

    test('O3: arka planda dolan süre öne gelince bir kez alarm çalar', () {
      final m = _aktifMac();
      m.sureAyarla(60);
      m.baslat();
      _ileri(90);
      m.didChangeAppLifecycleState(AppLifecycleState.resumed);
      m.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(alarmSayisi, 1);
      expect(m.timerBitti, isTrue);
    });

    test('dolmuş süre durdurulmaya çalışılırsa bitmiş sayılır', () {
      final m = _aktifMac();
      m.sureAyarla(10);
      m.baslat();
      _ileri(11);
      m.durdur();
      expect(m.timerBitti, isTrue);
      expect(alarmSayisi, 1);
    });

    test('süre seçilmeden BAŞLAT 1 dakikayla başlar; bitince BAŞLAT işlemez', () {
      final m = _aktifMac();
      m.baslat();
      expect(m.toplamSaniye, 60);
      expect(m.kalanSaniye, 60);
      _ileri(60);
      m.kontrolEt();
      m.baslat();
      expect(m.timerCalisiyor, isFalse);
      m.sifirla();
      expect(m.timerBitti, isFalse);
      expect(m.kalanSaniye, 60);
    });
  });

  group('Eski kayıt biçimi (2.0.1 ve öncesi)', () {
    Map<String, dynamic> eskiKayit(Map<String, dynamic> sure) => {
          'uid': 'uid_1',
          'sinifId': 's1',
          ...sure,
          'takimlar': [
            {
              'isim': 'A',
              'renkAdi': 'Kırmızı',
              'renk': 0xFFE53935,
              'skor': 3,
              'kaptanId': 'a1',
              'oyuncular': [
                {'id': 'a1', 'puan': 50, 'isMale': true, 'buradaMi': true},
              ],
            },
          ],
        };

    Future<bool> eskiyiYukle(Map<String, dynamic> sure) async {
      await MacDurumu.tamTemizlik();
      SharedPreferences.setMockInitialValues({'aktif_mac_uid_1': jsonEncode(eskiKayit(sure))});
      return MacDurumu().yukle('uid_1');
    }

    test('çalışan süre (kalan + çıkış anı) bitiş anına çevrilir', () async {
      final cikis = simdi.subtract(const Duration(seconds: 40));
      expect(
          await eskiyiYukle({
            'toplamSaniye': 300,
            'kalanSaniye': 200,
            'timerCalisiyor': true,
            'timerBitti': false,
            'cikisZamani': cikis.millisecondsSinceEpoch,
          }),
          isTrue);
      final m = MacDurumu();
      expect(m.timerCalisiyor, isTrue);
      expect(m.kalanSaniye, 160);
      expect(m.takimlar!.first.skor, 3);
      expect(m.takimlar!.first.oyuncular.single.ad, 'Ayşe');
      // Yeni biçimde yeniden yazıldı.
      final d = jsonDecode((await _ham())!) as Map<String, dynamic>;
      expect(d['bitis'], isNotNull);
    });

    test('çıkış anı olmayan bayat "çalışıyor" kaydı durmuş sayılır', () async {
      expect(
          await eskiyiYukle({
            'toplamSaniye': 300,
            'kalanSaniye': 120,
            'timerCalisiyor': true,
            'timerBitti': false,
            'cikisZamani': null,
          }),
          isTrue);
      expect(MacDurumu().timerCalisiyor, isFalse);
      expect(MacDurumu().kalanSaniye, 120);
    });

    test('kapalıyken dolmuş eski kayıt "süre bitti" açılır, alarm çalmaz', () async {
      await eskiyiYukle({
        'toplamSaniye': 300,
        'kalanSaniye': 30,
        'timerCalisiyor': true,
        'timerBitti': false,
        'cikisZamani': simdi.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      });
      expect(MacDurumu().timerBitti, isTrue);
      expect(alarmSayisi, 0);
    });

    test('bozuk kayıt çökertmez; güvenle yok sayılır ve silinir', () async {
      expect(await eskiyiYukle({'kalanSaniye': 'yarım', 'timerCalisiyor': 'evet'}), isFalse);
      expect(MacDurumu().aktif, isFalse);
      expect(await _ham(), isNull);
    });
  });

  group('Sınıflar Arası Yarışma geri yükleme (O2)', () {
    test('deplasman sınıfının oyuncuları da geri gelir; adlar diske yazılmaz', () async {
      final m = _aktifMac(yarisma: true);
      m.takimlar![1].skor = 1;
      await m.kaydet();
      final ham = (await _ham())!;
      expect(ham, isNot(contains('Ayşe')));
      expect(ham, isNot(contains('Zeynep')));

      await _yenidenAc(sonra: 5);
      expect(m.ekSinifIdler, ['s2']);
      expect(m.takimlar![0].oyuncular.map((o) => o.ad), ['Ayşe', 'Ali']);
      expect(m.takimlar![1].oyuncular.map((o) => o.ad), ['Zeynep', 'Mert']);
      expect(m.takimlar![1].kaptan?.id, 'b1');
      expect(m.takimlar![1].skor, 1);
    });
  });

  group('Mola (D7)', () {
    test('mola ekrandan çıkınca ve yeniden açılışta kalır; dolmuşu düşer', () async {
      final m = _aktifMac();
      final mola = m.molaEkle(0, 'a2');
      expect(mola.bitis, simdi.add(const Duration(seconds: 120)));
      m.molaEkle(0, 'a1');
      await _yenidenAc(sonra: 30);
      expect(m.molalar.length, 2);
      expect(m.molalar.first.oyuncuId, 'a2');
      expect(m.molalar.first.bitis, simdi.add(const Duration(seconds: 90)));
      m.molaKaldir(m.molalar.last);
      await _yenidenAc(sonra: 100);
      expect(m.molalar, isEmpty);
    });
  });

  group('Yerel kayıt gizliliği', () {
    final ogr = Ogrenci(id: 'ogr1', ad: 'Gizli Öğrenci', not: 'sakat', puan: 90);

    test('kullanıcı belli değilken diske hiçbir şey yazılmaz', () async {
      final m = MacDurumu();
      m.macBaslat('sinif1', [_takim('A', [ogr])]);
      await m.kaydet();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      expect(m.aktif, isTrue); // bellekte maç var
    });

    test('kayıt kullanıcı anahtarında; öğrenci adı ve notu diske ÇIKMAZ', () async {
      MacDurumu.kullaniciAyarla('uid_1');
      final m = MacDurumu();
      m.macBaslat('sinif1', [_takim('A', [ogr])]);
      await m.kaydet();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'aktif_mac_uid_1'});
      final ham = prefs.getString('aktif_mac_uid_1')!;
      expect(ham, isNot(contains('Gizli Öğrenci')));
      expect(ham, isNot(contains('sakat')));

      final json = jsonDecode(ham) as Map<String, dynamic>;
      expect(json['uid'], 'uid_1');
      expect(json['sinifId'], 'sinif1');
      final takim = (json['takimlar'] as List).first as Map;
      final oyuncu = (takim['oyuncular'] as List).first as Map;
      expect(oyuncu.keys, isNot(contains('ad')));
      expect(oyuncu.keys, isNot(contains('not')));
      expect(oyuncu['id'], 'ogr1');
      expect(oyuncu['puan'], 90);
    });

    test('tamTemizlik eski (v1.1.1 öncesi) anahtarı ve kullanıcı anahtarlarını siler',
        () async {
      SharedPreferences.setMockInitialValues({
        'aktif_mac': '{"sinifId":"eski"}',
        'aktif_mac_uid_1': '{"sinifId":"x"}',
        'aktif_mac_uid_2': '{"sinifId":"y"}',
        'baska_ayar': 'kalsin',
      });
      await MacDurumu.tamTemizlik();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'baska_ayar'});
      expect(MacDurumu().aktif, isFalse);
    });

    test('macBitir bellekteki ve diskteki kaydı siler', () async {
      MacDurumu.kullaniciAyarla('uid_1');
      final m = MacDurumu();
      m.macBaslat('sinif1', [_takim('A', [ogr])]);
      await m.kaydet();
      m.macBitir();
      await Future<void>.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('aktif_mac_uid_1'), isNull);
      expect(m.aktif, isFalse);
      expect(m.kalanSaniye, 0);
    });

    test('macBaslat sayaç durumunu sıfırlar', () {
      MacDurumu.kullaniciAyarla('uid_1');
      final m = MacDurumu();
      m.sureAyarla(300);
      m.baslat();
      m.duraklat();
      m.molaEkle(0, 'ogr1');
      m.macBaslat('sinif1', [_takim('A', [ogr])]);
      expect(m.kalanSaniye, 0);
      expect(m.timerCalisiyor, isFalse);
      expect(m.duraklatildi, isFalse);
      expect(m.molalar, isEmpty);
    });
  });
}
