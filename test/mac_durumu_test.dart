// Denetim #3 / Ajan E — MacDurumu (yerel maç kaydı) birim testleri.
//
// SharedPreferences sahte depo ile çalışır; Firestore'a dokunmaz.
// NOT: kalanSaniyeHesapla() DateTime.now() kullandığı ve _timerCikisZamani
// özel olduğu için "5 dakika sonra geri dönüş" senaryosu bu sınıfa
// dokunmadan test EDİLEMİYOR — bkz. rapor (saat enjeksiyonu önerisi).
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MacDurumu.tamTemizlik();
  });

  group('kalanSaniyeHesapla', () {
    test('timer durmuşken süreyi olduğu gibi döndürür', () {
      final m = MacDurumu();
      m.durumKaydet(kalanSn: 120, toplamSn: 300, calisiyor: false, bitti: false);
      expect(m.kalanSaniyeHesapla(), 120);
      expect(m.timerCalisiyor, isFalse);
      expect(m.timerBitti, isFalse);
    });

    test('timer çalışırken hemen geri dönüşte süre (neredeyse) değişmez', () {
      final m = MacDurumu();
      m.durumKaydet(kalanSn: 120, toplamSn: 300, calisiyor: true, bitti: false);
      final kalan = m.kalanSaniyeHesapla();
      expect(kalan, inInclusiveRange(119, 120));
      expect(m.timerCalisiyor, isTrue);
      expect(m.timerBitti, isFalse);
      // Çıkış zamanı tüketildi: ikinci çağrı aynı değeri döndürür.
      expect(m.kalanSaniyeHesapla(), kalan);
    });

    test('0 saniye ile çalışır kaydedilirse geri dönüşte bitti sayılır', () {
      final m = MacDurumu();
      m.durumKaydet(kalanSn: 0, toplamSn: 300, calisiyor: true, bitti: false);
      expect(m.kalanSaniyeHesapla(), 0);
      expect(m.timerBitti, isTrue);
      expect(m.timerCalisiyor, isFalse);
    });

    test('bitti bayrağı çalışıyor bayrağını ezer', () {
      final m = MacDurumu();
      m.durumKaydet(kalanSn: 5, toplamSn: 300, calisiyor: true, bitti: true);
      expect(m.timerCalisiyor, isFalse);
      expect(m.kalanSaniyeHesapla(), 5);
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
      m.durumKaydet(kalanSn: 42, toplamSn: 300, calisiyor: true, bitti: false);
      m.macBaslat('sinif1', [_takim('A', [ogr])]);
      expect(m.kalanSaniye, 0);
      expect(m.timerCalisiyor, isFalse);
      expect(m.duraklatildi, isFalse);
    });
  });
}
