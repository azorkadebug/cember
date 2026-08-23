import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cember/models/ogrenci.dart';
import 'package:cember/services/auth_service.dart';
import 'package:cember/services/demo_modu.dart';
import 'package:cember/services/sifreleme_service.dart';

/// v1.1.1 öncesi biçimde şifreli bir alan üretir — eski kayıtların hâlâ
/// okunabildiğini doğrulamak için.
String eskiBicimdeSifrele(String uid, String metin) {
  final key = Key(Uint8List.fromList(
      utf8.encode(uid.padRight(32, '#').substring(0, 32))));
  final iv = IV(Uint8List.fromList(utf8.encode(
      uid.split('').reversed.join().padRight(16, '*').substring(0, 16))));
  return Encrypter(AES(key, mode: AESMode.cbc)).encrypt(metin, iv: iv).base64;
}

void main() {
  const uid = 'A1Xyb80fR7NQ6KuwBt6NUa5p2743';

  setUp(() {
    SifrelemeService.initialize(uid);
    DemoModu.aktif = false;
    DemoModu.sifirla();
  });

  group('Öğrenci verisi — şifrelemeden düz metne göç', () {
    test('yeni kayıtlar düz metin yazılır ve sifrelendi:false taşır', () {
      final o = Ogrenci(id: 'x', ad: 'Ayşe Yılmaz', not: 'kaleci');
      final map = o.toMap();

      expect(map['ad'], 'Ayşe Yılmaz');
      expect(map['not'], 'kaleci');
      // Eski istemciler bu bayrağa bakıp çözmeye çalışmasın.
      expect(map['sifrelendi'], false);
    });

    test('eski şifreli kayıtlar hâlâ doğru çözülür', () {
      final eskiKayit = {
        'ad': eskiBicimdeSifrele(uid, 'Mehmet Demir'),
        'not': eskiBicimdeSifrele(uid, 'sakat'),
        'sifrelendi': true,
        'puan': 120,
      };

      final o = Ogrenci.fromMap('id1', eskiKayit);
      expect(o.ad, 'Mehmet Demir');
      expect(o.not, 'sakat');
      expect(o.puan, 120);
    });

    test('okunan eski kayıt tekrar yazıldığında düz metne göç eder', () {
      final eskiKayit = {
        'ad': eskiBicimdeSifrele(uid, 'Zeynep Kaya'),
        'sifrelendi': true,
      };

      final yeniMap = Ogrenci.fromMap('id2', eskiKayit).toMap();
      expect(yeniMap['ad'], 'Zeynep Kaya');
      expect(yeniMap['sifrelendi'], false);
    });

    test('düz metin kayıtlar bayrak olmadan da okunur', () {
      final o = Ogrenci.fromMap('id3', {'ad': 'Ali Vural', 'not': ''});
      expect(o.ad, 'Ali Vural');
      expect(o.not, '');
    });
  });

  group('Girdi sınırları', () {
    test('ad ve not üst sınırda kırpılır', () {
      final o = Ogrenci(
        id: 'x',
        ad: 'A' * 500,
        not: 'B' * 5000,
      );
      final map = o.toMap();
      expect((map['ad'] as String).length, Ogrenci.adMaxUzunluk);
      expect((map['not'] as String).length, Ogrenci.notMaxUzunluk);
    });

    test('sağlık notları sınırsız birikmez', () {
      final o = Ogrenci(
        id: 'x',
        ad: 'Test',
        saglikNotlari: List.generate(
            200, (i) => {'tarih': '2026-01-01', 'not': 'kayıt $i'}),
      );
      final notlar = o.toMap()['saglikNotlari'] as List;
      expect(notlar.length, Ogrenci.saglikNotuMaxAdet);
      // En yeni kayıtlar korunmalı.
      expect((notlar.last as Map)['not'], 'kayıt 199');
    });

    test('puan üst sınırı aşamaz', () {
      final map = Ogrenci(id: 'x', ad: 'Test', puan: 999999).toMap();
      expect(map['puan'], 9999);
    });
  });

  group('Kimlik doğrulama hataları — kullanıcı numaralandırma', () {
    test('user-not-found ile wrong-password AYNI mesajı verir', () {
      final a = AuthService.hataMesaji(
          FirebaseAuthException(code: 'user-not-found'));
      final b = AuthService.hataMesaji(
          FirebaseAuthException(code: 'wrong-password'));
      final c = AuthService.hataMesaji(
          FirebaseAuthException(code: 'invalid-credential'));

      expect(a, b);
      expect(b, c);
      expect(a, 'E-posta veya şifre hatalı.');
    });

    test('ham hata metni kullanıcıya sızmaz', () {
      final mesaj = AuthService.hataMesaji(
        FirebaseAuthException(
          code: 'internal-error',
          message: 'PlatformException(sign_in_failed, com.google.android.gms...)',
        ),
      );
      expect(mesaj.contains('PlatformException'), isFalse);
      expect(mesaj.contains('com.google'), isFalse);
    });

    test('Firebase dışı istisnalar da genel mesaja düşer', () {
      expect(AuthService.hataMesaji(StateError('boom')),
          'İşlem tamamlanamadı. Lütfen tekrar dene.');
    });
  });

  group('Şifre politikası', () {
    test('zayıf şifreler reddedilir', () {
      expect(AuthService.sifreHatasi('123456'), isNotNull); // kısa
      expect(AuthService.sifreHatasi('1234567890'), isNotNull); // harf yok
      expect(AuthService.sifreHatasi('abcdefghij'), isNotNull); // rakam yok
      expect(AuthService.sifreHatasi('Abc1'), isNotNull); // kısa
    });

    test('kurala uyan şifre kabul edilir', () {
      expect(AuthService.sifreHatasi('Cember2026abc'), isNull);
      expect(AuthService.sifreHatasi('sifre12345'), isNull);
    });

    test('Türkçe karakterli şifre harf sayılır', () {
      expect(AuthService.sifreHatasi('çğıöşü1234'), isNull);
    });
  });

  group('Demo modu maskelemesi', () {
    test('kapalıyken gerçek adı döndürür', () {
      final o = Ogrenci(id: '1', ad: 'Gerçek İsim');
      expect(o.gorunenAd, 'Gerçek İsim');
    });

    test('açıkken gerçek ad sızmaz ve eşleme kararlıdır', () {
      final o = Ogrenci(id: '1', ad: 'Gerçek İsim', isMale: true);
      DemoModu.aktif = true;

      final ilk = o.gorunenAd;
      expect(ilk, isNot('Gerçek İsim'));
      // Aynı öğrenci her seferinde aynı sahte adı almalı (ekran tutarlılığı).
      expect(o.gorunenAd, ilk);

      DemoModu.aktif = false;
      expect(o.gorunenAd, 'Gerçek İsim');
    });

    test('sifirla eşlemeyi temizler — çıkışta veri taşınmaz', () {
      DemoModu.aktif = true;
      final o = Ogrenci(id: '1', ad: 'Bir Öğrenci', isMale: false);
      final ilk = o.gorunenAd;

      DemoModu.sifirla();
      final ikinci = Ogrenci(id: '2', ad: 'Başka Öğrenci', isMale: false).gorunenAd;
      // Sayaç sıfırlandığı için ilk sahte isim yeniden kullanılabilir olmalı.
      expect(ikinci, ilk);
    });
  });

  group('SifrelemeService', () {
    test('temizle sonrası eski anahtar bellekte kalmaz', () {
      SifrelemeService.temizle();
      expect(SifrelemeService.instanceOrNull, isNull);
      expect(() => SifrelemeService.instance, throwsStateError);
    });

    test('initialize edilmemişken alanCoz düz metin varsayar', () {
      SifrelemeService.temizle();
      final deger = SifrelemeService.alanCoz(
          {'ad': 'düz metin', 'sifrelendi': true}, 'ad');
      expect(deger, 'düz metin');
    });

    test('başka bir hesabın anahtarıyla çözülemeyen veri kaybolmaz', () {
      final baskaninKaydi = eskiBicimdeSifrele('BASKA_BIR_UID_123456', 'Ali');
      final sonuc = SifrelemeService.instance.coz(baskaninKaydi);
      // Çözülemedi ama sessizce boşaltılmadı — öğretmen düzeltebilsin.
      expect(sonuc, isNotEmpty);
    });
  });
}
