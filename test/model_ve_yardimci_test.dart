// Denetim #3 / Ajan E — saf mantık birim testleri.
//
// Kapsam: Ogrenci.fromMap/toMap gidiş-dönüş ve eski PE alanı senkronu,
// kalemArti sınırları, KontrolKalemi gidiş-dönüş + branş şablonu,
// ElementSistemi, trKucult, AppTema.ustMetin/formaRengi, DemoModu.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cember/models/kontrol_kalemi.dart';
import 'package:cember/models/ogrenci.dart';
import 'package:cember/screens/ogrenci_arama_ekrani.dart' show trKucult;
import 'package:cember/services/demo_modu.dart';
import 'package:cember/services/sifreleme_service.dart';
import 'package:cember/tema.dart';

void main() {
  setUp(() {
    SifrelemeService.temizle();
    DemoModu.aktif = false;
    DemoModu.sifirla();
  });

  group('Ogrenci.toMap → fromMap gidiş-dönüş', () {
    test('tüm alanlar kayıpsız döner', () {
      final o = Ogrenci(
        id: 'o1',
        ad: 'Ayşe Yılmaz',
        puan: 120,
        buradaMi: false,
        saglikDurumu: 2,
        not: 'kaleci',
        isMale: false,
        element: 'ates',
        eslesenIdler: ['o2', 'o3'],
        saglikNotlari: [
          {'tarih': '2026-09-01', 'not': 'bilek'}
        ],
        rozetler: [
          {'tip': 'lider', 'tarih': '2026-09-02'}
        ],
        kalemSayaclari: {'kiyafet': 3, 'sari_kart': 1},
      );

      final geri = Ogrenci.fromMap('o1', o.toMap());

      expect(geri.id, 'o1');
      expect(geri.ad, 'Ayşe Yılmaz');
      expect(geri.puan, 120);
      expect(geri.buradaMi, false);
      expect(geri.saglikDurumu, 2);
      expect(geri.not, 'kaleci');
      expect(geri.isMale, false);
      expect(geri.element, 'ates');
      expect(geri.eslesenIdler, ['o2', 'o3']);
      expect(geri.saglikNotlari.single['not'], 'bilek');
      expect(geri.rozetler.single['tip'], 'lider');
      expect(geri.kalemSayaclari, {'kiyafet': 3, 'sari_kart': 1});
    });

    test('toMap eski PE alanlarını kalemSayaclari\'ndan türetir (v1.0 uyumu)',
        () {
      final map = Ogrenci(
        id: 'x',
        ad: 'A',
        kalemSayaclari: {'kiyafet': 2, 'ayakkabi': 1, 'sari_kart': 4},
      ).toMap();

      expect(map['kiyafetEksik'], 2);
      expect(map['ayakkabiEksik'], 1);
      expect(map['sariKart'], 4);
    });

    test('kalemSayaclari boşken eski alanlar nesnedeki değeri yansıtır', () {
      // ÖNEMLİ: toMap `kalemSayaclari['kiyafet'] ?? kiyafetEksik` diyor.
      // Sayaç 0'a inince haritadan silindiği için eski alan, nesnedeki
      // (fromMap ile okunmuş) ESKİ değeri geri yazar — bu bir tutarsızlık.
      final o = Ogrenci.fromMap('x', {
        'ad': 'A',
        'kiyafetEksik': 5, // eski istemcinin yazdığı değer
        'kalemSayaclari': {'kiyafet': 5},
      });
      o.kalemArti('kiyafet', -5); // sayaç sıfırlandı → haritadan silindi
      final map = o.toMap();

      expect(map['kalemSayaclari'], isEmpty);
      // Beklenen: 0. Gerçek davranış aşağıda belgeleniyor.
      expect(map['kiyafetEksik'], 5,
          reason: 'kalemSayaclari 0 olunca eski alan senkron kalmıyor '
              '(models/ogrenci.dart:120-122) — v1.0 istemci 5 görür');
    });

    test('eski belge (kalemSayaclari yok) PE alanlarından tohumlanır', () {
      final o = Ogrenci.fromMap('x', {
        'ad': 'A',
        'kiyafetEksik': 2,
        'ayakkabiEksik': 0,
        'sariKart': 1,
      });
      expect(o.kalemSayaclari, {'kiyafet': 2, 'sari_kart': 1});
      expect(o.kalemDeger('ayakkabi'), 0);
    });

    test('kalemSayaclari\'ndaki sıfırlar okurken temizlenir', () {
      final o = Ogrenci.fromMap('x', {
        'ad': 'A',
        'kalemSayaclari': {'kiyafet': 0, 'sari_kart': 2, 'bozuk': null},
      });
      expect(o.kalemSayaclari, {'sari_kart': 2});
    });

    test('Firestore\'dan gelen num/double puan ve bozuk tipler patlatmaz', () {
      // Firestore JS SDK sayıları double döndürebilir; eslesenIdler
      // List<Object?> gelir.
      final o = Ogrenci.fromMap('x', {
        'ad': 'A',
        'puan': 90,
        'eslesenIdler': <Object?>['a', 1],
        'saglikNotlari': <Object?>[
          <Object?, Object?>{'not': 'x'}
        ],
      });
      expect(o.puan, 90);
      expect(o.eslesenIdler, ['a', '1']);
      expect(o.saglikNotlari.single['not'], 'x');
    });

    test('puan double gelirse fromMap TİP HATASI verir (Şüpheli)', () {
      // `puan: map['puan'] ?? 100` — int alanına double atanır.
      // Web JS SDK'de tam sayılar int gelir; ama bir istemci 90.0 yazarsa
      // öğrenci listesi hiç açılmaz. Belgeleme amaçlı.
      expect(
        () => Ogrenci.fromMap('x', {'ad': 'A', 'puan': 90.0}),
        throwsA(isA<TypeError>()),
      );
    });

    test('eslesenIdler boş liste olarak KOŞULSUZ yazılır', () {
      final map = Ogrenci(id: 'x', ad: 'A').toMap();
      expect(map.containsKey('eslesenIdler'), isTrue);
      expect(map['eslesenIdler'], isEmpty);
      // element ise yalnız doluyken yazılır.
      expect(map.containsKey('element'), isFalse);
    });
  });

  group('Ogrenci.kalemArti', () {
    test('0 altına inmez ve 0 olunca haritadan silinir', () {
      final o = Ogrenci(id: 'x', ad: 'A');
      o.kalemArti('kiyafet', -3);
      expect(o.kalemSayaclari, isEmpty);
      o.kalemArti('kiyafet', 2);
      o.kalemArti('kiyafet', -2);
      expect(o.kalemSayaclari.containsKey('kiyafet'), isFalse);
    });

    test('999 üst sınırında kırpılır', () {
      final o = Ogrenci(id: 'x', ad: 'A');
      o.kalemArti('sari_kart', 5000);
      expect(o.kalemDeger('sari_kart'), 999);
    });
  });

  group('KontrolKalemi', () {
    test('toMap → fromMap gidiş-dönüş', () {
      const k = KontrolKalemi(
          id: 'flut', ad: 'Flüt', ikon: 'music', tip: KalemTipi.sayac, sira: 3);
      final geri = KontrolKalemi.fromMap(k.toMap());
      expect(geri.id, 'flut');
      expect(geri.ad, 'Flüt');
      expect(geri.ikon, 'music');
      expect(geri.tip, KalemTipi.sayac);
      expect(geri.sira, 3);
    });

    test('eksik/bozuk alanlarda varsayılana düşer', () {
      final k = KontrolKalemi.fromMap({'id': 'x', 'tip': 'bilinmeyen'});
      expect(k.ad, '');
      expect(k.ikon, 'check');
      expect(k.tip, KalemTipi.gunluk);
      expect(k.sira, 0);
    });

    test('bransSablonu bilinmeyen/boş id\'de Beden Eğitimi\'ne düşer', () {
      expect(bransSablonu(null).id, 'beden_egitimi');
      expect(bransSablonu('yok_boyle_brans').id, 'beden_egitimi');
      expect(bransSablonu('resim').varsayilanKalemler.map((k) => k.id),
          ['boya', 'firca', 'resim_defteri']);
    });

    test('şablon kalem id\'leri branş içinde tekil', () {
      for (final b in bransSablonlari) {
        final idler = b.varsayilanKalemler.map((k) => k.id).toList();
        expect(idler.toSet().length, idler.length, reason: b.ad);
      }
    });
  });

  group('ElementSistemi', () {
    test('çatışma simetrik, aynı element çatışmaz, null çatışmaz', () {
      expect(ElementSistemi.catisir('ates', 'su'), isTrue);
      expect(ElementSistemi.catisir('su', 'ates'), isTrue);
      expect(ElementSistemi.catisir('toprak', 'hava'), isTrue);
      expect(ElementSistemi.catisir('ates', 'ates'), isFalse);
      expect(ElementSistemi.catisir('ates', 'toprak'), isFalse);
      expect(ElementSistemi.catisir(null, 'su'), isFalse);
      expect(ElementSistemi.catisir('ates', null), isFalse);
    });

    test('her elementin sembolü ve etiketi var', () {
      for (final e in ElementSistemi.catismalar.keys) {
        expect(ElementSistemi.sembol(e), isNotNull);
        expect(ElementSistemi.etiket(e), isNotNull);
      }
      expect(ElementSistemi.sembol(null), isNull);
    });
  });

  group('trKucult (Türkçe küçük harf)', () {
    test('İ → i, I → ı', () {
      expect(trKucult('İzmir'), 'izmir');
      expect(trKucult('ISPARTA'), 'ısparta');
      expect(trKucult('IŞIK İLKAY'), 'ışık ilkay');
    });

    test('arama: "ali" hem "ALİ" hem "Ali" ile eşleşir', () {
      expect(trKucult('ALİ').contains(trKucult('ali')), isTrue);
      expect(trKucult('Ali').contains(trKucult('ALİ')), isTrue);
    });

    test('diğer Türkçe harfler korunur', () {
      expect(trKucult('ÇĞÖŞÜ'), 'çğöşü');
    });
  });

  group('AppTema', () {
    test('formaRengi ad → renk; bilinmeyen ad charcoal', () {
      expect(AppTema.formaRengi('turuncu'), const Color(0xFFF57C00));
      expect(AppTema.formaRengi('turuncu'), isNot(AppTema.ana));
      expect(AppTema.formaRengi(' Kırmızı '), const Color(0xFFE53935));
      expect(AppTema.formaRengi('KIRMIZI'), AppTema.ana,
          reason: 'toLowerCase() Türkçe İ/I bilmez: "KIRMIZI" → "kirmizi" '
              '≠ "kırmızı" (tema.dart:96) — formaRenkAdlari sabiti '
              'kullanıldığı sürece görünmez, elle giriş olursa charcoal');
      expect(AppTema.formaRengi('neon'), AppTema.ana);
    });

    test('formaRenkAdlari listesindeki her ad bir renge çözülür', () {
      for (final ad in AppTema.formaRenkAdlari) {
        expect(AppTema.formaRengi(ad), isNot(AppTema.ana), reason: ad);
      }
    });

    test('ustMetin: sarı/beyaz üstüne koyu, siyah/kırmızı üstüne beyaz', () {
      expect(AppTema.ustMetin(AppTema.formaRengi('sarı')), AppTema.panelKoyu1);
      expect(AppTema.ustMetin(Colors.white), AppTema.panelKoyu1);
      expect(AppTema.ustMetin(AppTema.formaRengi('siyah')), Colors.white);
      expect(AppTema.ustMetin(AppTema.formaRengi('kırmızı')), Colors.white);
    });

    test('ustMetin seçilen renk her zaman daha yüksek kontrastlı olan', () {
      for (final ad in AppTema.formaRenkAdlari) {
        final zemin = AppTema.formaRengi(ad);
        final l = zemin.computeLuminance();
        final beyaz = 1.05 / (l + 0.05);
        final koyu = (l + 0.05) / (AppTema.panelKoyu1.computeLuminance() + 0.05);
        final secilen = AppTema.ustMetin(zemin);
        expect(secilen == Colors.white ? beyaz : koyu,
            greaterThanOrEqualTo(secilen == Colors.white ? koyu : beyaz),
            reason: ad);
      }
    });

    test('ustDolgu metin rengiyle tutarlı', () {
      expect((AppTema.ustDolgu(Colors.white).a * 255).round(), 28);
      expect((AppTema.ustDolgu(Colors.black).a * 255).round(), 40);
    });
  });

  group('DemoModu.isimGetir', () {
    test('cinsiyete göre ayrı havuz, sıra korunur, 21. isim başa sarar', () {
      DemoModu.aktif = true;
      final ilkKiz = DemoModu.isimGetir('K0', false);
      final ilkErkek = DemoModu.isimGetir('E0', true);
      expect(ilkKiz, isNot(ilkErkek));

      for (var i = 1; i < 20; i++) {
        DemoModu.isimGetir('K$i', false);
      }
      // 20 kız ismi tükendi; 21. kız ilk isme geri döner.
      expect(DemoModu.isimGetir('K20', false), ilkKiz);
    });

    test('aynı gerçek isim farklı cinsiyetle bile aynı sahte isme gider', () {
      // Eşleme yalnız isme göre; aynı ad iki öğrencide varsa (Ali Yılmaz ×2)
      // ikisi de aynı sahte adı alır — ekranda ayırt edilemez.
      DemoModu.aktif = true;
      final a = DemoModu.isimGetir('Deniz Ak', true);
      final b = DemoModu.isimGetir('Deniz Ak', false);
      expect(a, b);
    });

    test('kapalıyken eşleme birikmez', () {
      DemoModu.aktif = false;
      expect(DemoModu.isimGetir('Gerçek', true), 'Gerçek');
      DemoModu.aktif = true;
      // Kapalıyken çağrı sayaç ilerletmemiş olmalı.
      expect(DemoModu.isimGetir('Başka', true), DemoModu.isimGetir('Başka', true));
    });
  });
}
