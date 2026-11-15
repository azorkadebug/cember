import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cember/models/ogrenci.dart';
import 'package:cember/services/demo_modu.dart';
import 'package:cember/services/firestore_service.dart';
import 'package:cember/services/sifreleme_service.dart';
import 'package:cember/utils/kart_saglik.dart';

/// Denetim #5: öğrenci kartında sessiz veri kayıpları.
void main() {
  setUp(() {
    SifrelemeService.initialize('uid-test');
    DemoModu.aktif = false;
  });

  group('Eski şemalı öğrenci (3-O2)', () {
    final eski = {'ad': 'Ali', 'sariKart': 2, 'kiyafetEksik': 3, 'ayakkabiEksik': 1};

    test('haritasız belge işaretlenir, sayaçlar eski alanlardan tohumlanır', () {
      final o = Ogrenci.fromMap('a', eski);
      expect(o.kalemHaritasiVar, isFalse);
      expect(o.kalemSayaclari, {'kiyafet': 3, 'ayakkabi': 1, 'sari_kart': 2});
    });

    test('gidiş-dönüş: toMap tohumlanmış haritayı ve eski alanları korur', () {
      final o = Ogrenci.fromMap('a', eski);
      final m = o.toMap();
      expect(m['kalemSayaclari'], {'kiyafet': 3, 'ayakkabi': 1, 'sari_kart': 2});
      final geri = Ogrenci.fromMap('a', m);
      expect(geri.kalemHaritasiVar, isTrue);
      expect(geri.kalemSayaclari, o.kalemSayaclari);
      expect(geri.sariKart, 2);
      expect(geri.kiyafetEksik, 3);
      expect(geri.ayakkabiEksik, 1);
    });

    test('ilk artımda bütün harita yazılır, noktalı artım yazılmaz', () {
      final o = Ogrenci.fromMap('a', eski);
      o.kalemArti('sari_kart', 1);
      final alan = FirestoreService.kalemGuncellemeAlanlari(
          {'sari_kart': 1}, tamHarita: o.kalemSayaclari);
      expect(alan['kalemSayaclari'], {'kiyafet': 3, 'ayakkabi': 1, 'sari_kart': 3});
      expect(alan.containsKey('kalemSayaclari.sari_kart'), isFalse);
      expect(alan['sariKart'], isA<FieldValue>());
    });

    test('PE dışı kalem de haritayı bütün yazar', () {
      final alan = FirestoreService.kalemGuncellemeAlanlari(
          {'forma': 1}, tamHarita: {'sari_kart': 2, 'forma': 1});
      expect(alan['kalemSayaclari'], {'sari_kart': 2, 'forma': 1});
    });

    test('haritalı belgede noktalı artım (iki cihaz toplamı) korunur', () {
      final o = Ogrenci.fromMap('a', {'kalemSayaclari': {'sari_kart': 2}});
      expect(o.kalemHaritasiVar, isTrue);
      final alan = FirestoreService.kalemGuncellemeAlanlari({'sari_kart': 1});
      expect(alan.containsKey('kalemSayaclari'), isFalse);
      expect(alan['kalemSayaclari.sari_kart'], isA<FieldValue>());
    });
  });

  group('Sağlık notu izi (3-O1, 2-O7)', () {
    Ogrenci ogrenci() => Ogrenci(id: 'a', ad: 'Ali', saglikDurumu: 2, saglikNotlari: [
          {'tarih': '01.01.2026', 'not': 'eski1'},
          {'tarih': '02.01.2026', 'not': 'eski2'},
        ]);

    test('not ekle + eski notu sil: yeni not eklenenlerde, sayaç tutarlı', () {
      final o = ogrenci();
      final iz = KartSaglikIzi(o);
      final yeni = {'tarih': '03.01.2026', 'not': 'yeni'};
      iz.ekle(o, yeni);
      final eski = o.saglikNotlari.first;
      final sonuc = iz.sil(o, eski);
      expect(sonuc.sunucudan, isTrue);
      expect(sonuc.sayaciAzalt, isTrue);
      // Uzunluk açılıştakiyle aynı (2) ama yeni not yine de bulunur.
      expect(o.saglikNotlari.length, 2);
      expect(iz.eklenen, [yeni]);
      // Silme sunucuya sayaçla birlikte gitti, Kaydet'te yalnız +1 (yeni not).
      expect(o.saglikDurumu - iz.ilkSayac, 1);
      expect(o.saglikDurumu, o.saglikNotlari.length);
    });

    test('önce sil sonra ekle de aynı sonucu verir', () {
      final o = ogrenci();
      final iz = KartSaglikIzi(o);
      iz.sil(o, o.saglikNotlari.first);
      final yeni = {'tarih': '03.01.2026', 'not': 'yeni'};
      iz.ekle(o, yeni);
      expect(iz.eklenen, [yeni]);
      expect(o.saglikDurumu - iz.ilkSayac, 1);
    });

    test('bu oturumda eklenen notu silmek sunucuya gitmez, sayaç eski haline döner', () {
      final o = ogrenci();
      final iz = KartSaglikIzi(o);
      final yeni = {'tarih': '03.01.2026', 'not': 'yeni'};
      iz.ekle(o, yeni);
      final sonuc = iz.sil(o, yeni);
      expect(sonuc.sunucudan, isFalse);
      expect(iz.eklenen, isEmpty);
      expect(o.saglikDurumu, 2);
    });

    test('sayaç 0 altına inmez', () {
      final o = Ogrenci(id: 'a', ad: 'Ali', saglikDurumu: 0, saglikNotlari: [
        {'tarih': 'x', 'not': 'n'}
      ]);
      final iz = KartSaglikIzi(o);
      final sonuc = iz.sil(o, o.saglikNotlari.first);
      expect(o.saglikDurumu, 0);
      expect(sonuc.sayaciAzalt, isFalse);
      iz.yetimSayaciDusur(o);
      expect(o.saglikDurumu, 0);
    });

    test('yetim sayaç: not sayısından büyük sayaç "−" ile düşer', () {
      final o = Ogrenci(id: 'a', ad: 'Ali', saglikDurumu: 2);
      expect(KartSaglikIzi.yetimSayac(o), isTrue);
      KartSaglikIzi(o).yetimSayaciDusur(o);
      expect(o.saglikDurumu, 1);
    });

    test('iptalde silinmiş eski not geri gelmez, eklenen geri alınır', () {
      final o = ogrenci();
      final iz = KartSaglikIzi(o);
      iz.sil(o, o.saglikNotlari.first); // sunucudan silindi
      iz.ekle(o, {'tarih': '03.01.2026', 'not': 'yeni'});
      iz.geriAl(o);
      expect(o.saglikNotlari.map((n) => n['not']), ['eski2']);
      expect(o.saglikDurumu, 1);
    });

    test('50 not dolu sayılır, 49 değil', () {
      final o = Ogrenci(id: 'a', ad: 'Ali', saglikNotlari: [
        for (var i = 0; i < 49; i++) {'tarih': 't', 'not': '$i'}
      ]);
      expect(KartSaglikIzi.dolu(o), isFalse);
      o.saglikNotlari.add({'tarih': 't', 'not': 'son'});
      expect(KartSaglikIzi.dolu(o), isTrue);
    });
  });

  test('yeni yıl kopyasında sağlık işareti notlarla tutarlı (4-O2)', () {
    final o = Ogrenci(id: 'a', ad: 'Ali', saglikDurumu: 5, saglikNotlari: [
      {'tarih': 't', 'not': 'n1'},
      {'tarih': 't', 'not': 'n2'},
    ]);
    final k = o.yeniYilKopyasi(sinifId: 's', sinifAd: '6A', egitimYili: '2025-2026');
    expect(k.saglikNotlari.length, 2);
    expect(k.saglikDurumu, 2);
    final notsuz = Ogrenci(id: 'b', ad: 'Veli', saglikDurumu: 3)
        .yeniYilKopyasi(sinifId: 's', sinifAd: '6A', egitimYili: '2025-2026');
    expect(notsuz.saglikDurumu, 0);
  });

  test('kart kaydı reddi gerçek nedeni söyler (1-O3)', () {
    final m = FirestoreService.kartKaydiHataMesaji('[cloud_firestore/permission-denied] x');
    expect(m, contains('50 sağlık notu'));
    expect(m, isNot(contains('silinmiş')));
    expect(FirestoreService.kartKaydiHataMesaji('[cloud_firestore/not-found] x'), contains('silinmiş'));
    expect(FirestoreService.kartKaydiHataMesaji('[cloud_firestore/unavailable] x'), contains('bağlantı'));
  });
}
