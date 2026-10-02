// Eğitim yılı hesapları ve geçen yıldan aktarma kopyası.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cember/models/ogrenci.dart';
import 'package:cember/utils/egitim_yili.dart';

void main() {
  group('EgitimYili', () {
    test('Ağustos yeni yılı başlatır', () {
      expect(EgitimYili.tarihten(DateTime(2026, 7, 31)), '2025-2026');
      expect(EgitimYili.tarihten(DateTime(2026, 8, 1)), '2026-2027');
      expect(EgitimYili.tarihten(DateTime(2027, 1, 15)), '2026-2027');
    });

    test('önceki yıl ve biçim denetimi', () {
      expect(EgitimYili.onceki('2026-2027'), '2025-2026');
      expect(EgitimYili.gecerli('2025-2026'), isTrue);
      expect(EgitimYili.gecerli('2025-2027'), isFalse);
      expect(EgitimYili.gecerli('6A'), isFalse);
      expect(EgitimYili.gecerli(null), isFalse);
    });

    test('alan yoksa oluşturulma tarihinden, o da yoksa bu yıl', () {
      expect(EgitimYili.sinifin({'egitimYili': '2024-2025'}), '2024-2025');
      expect(EgitimYili.sinifin({'created': Timestamp.fromDate(DateTime(2026, 5, 10))}), '2025-2026');
      expect(EgitimYili.sinifin({'egitimYili': 'bozuk', 'created': Timestamp.fromDate(DateTime(2026, 9, 1))}), '2026-2027');
      expect(EgitimYili.sinifin({}), EgitimYili.simdiki);
      expect(EgitimYili.sinifin(null), EgitimYili.simdiki);
    });

    test('yıl dizgeleri sözlük sırasıyla kronolojik sıralanır', () {
      expect('2025-2026'.compareTo('2026-2027') < 0, isTrue);
    });
  });

  group('Ogrenci.yeniYilKopyasi', () {
    final eski = Ogrenci(
      id: 'o1', ad: 'Alp Aksoy', puan: 140, isMale: true, element: 'ates',
      not: 'Geçen yılın notu', saglikDurumu: 2, buradaMi: false,
      kalemSayaclari: {'sari_kart': 2},
      eslesenIdler: ['o2'],
      rozetler: [{'id': 'lider'}],
      saglikNotlari: [{'metin': 'Astım', 'tarih': '2026-03-01'}],
    );
    final yeni = eski.yeniYilKopyasi(sinifId: 's6a', sinifAd: '6A', egitimYili: '2025-2026');

    test('kimlik ve sağlık notları taşınır', () {
      expect(yeni.ad, 'Alp Aksoy');
      expect(yeni.puan, 140);
      expect(yeni.isMale, isTrue);
      expect(yeni.element, 'ates');
      expect(yeni.saglikNotlari, [{'metin': 'Astım', 'tarih': '2026-03-01'}]);
    });

    test('yıl içi veriler sıfırdan başlar', () {
      expect(yeni.not, '');
      expect(yeni.rozetler, isEmpty);
      expect(yeni.eslesenIdler, isEmpty);
      expect(yeni.kalemSayaclari, isEmpty);
      expect(yeni.saglikDurumu, 0);
      expect(yeni.buradaMi, isTrue);
    });

    test('sağlık notları kopya, eski kayıtla paylaşılmaz', () {
      yeni.saglikNotlari.first['metin'] = 'değişti';
      expect(eski.saglikNotlari.first['metin'], 'Astım');
    });

    test('önceki kayıt gidiş-dönüşte korunur, yoksa alan yazılmaz', () {
      final map = yeni.toMap();
      expect(map['oncekiKayit'], {'sinifId': 's6a', 'sinifAd': '6A', 'egitimYili': '2025-2026', 'ogrenciId': 'o1'});
      expect(Ogrenci.fromMap('x', map).oncekiKayit?['sinifAd'], '6A');
      expect(eski.toMap().containsKey('oncekiKayit'), isFalse);
      expect(Ogrenci.fromMap('x', {'ad': 'A', 'oncekiKayit': 'bozuk'}).oncekiKayit, isNull);
    });
  });
}
