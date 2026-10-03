// Sınıf kartı yoklama halkası — saf mantık birim testleri.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:cember/utils/metin.dart';
import 'package:cember/utils/sinif_ozeti.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  group('sinifKisaltmasi', () {
    test('ayırıcılar atılır', () {
      expect(sinifKisaltmasi('7-A'), '7A');
      expect(sinifKisaltmasi('8/B'), '8B');
      expect(sinifKisaltmasi(' 5 C '), '5C');
      expect(sinifKisaltmasi('10-A'), '10A');
    });
    test('çok sözcükte baş harfler, sayılar bütün', () {
      expect(sinifKisaltmasi('Hazırlık B'), 'HB');
      expect(sinifKisaltmasi('10-A Fen'), '10A');
      expect(sinifKisaltmasi('Futbol Takımı'), 'FT');
    });
    test('tek uzun sözcük ilk 3 harf, Türkçe büyük harf', () {
      expect(sinifKisaltmasi('Futbol'), 'FUT');
      expect(sinifKisaltmasi('izci'), 'İZC');
      expect(sinifKisaltmasi('ışık'), 'IŞI');
    });
    test('boş ad', () => expect(sinifKisaltmasi('  '), '?'));
  });

  test('trBuyut', () => expect(trBuyut('iğdır ılgaz'), 'İĞDIR ILGAZ'));

  group('yoklamaOzeti', () {
    test('doküman yoksa null', () {
      expect(yoklamaOzeti(null, ['a']), isNull);
      expect(yoklamaOzeti({'kayitlar': {}}, ['a']), isNull);
    });
    test('kaydı olmayan geldi sayılır, silinen öğrenci sayılmaz', () {
      final o = yoklamaOzeti({
        'tarih': '2026-10-02',
        'kayitlar': {
          'a': {'geldi': true},
          'b': {'geldi': false},
          'silinen': {'geldi': false},
        },
      }, ['a', 'b', 'c', 'd'])!;
      expect(o.gelen, 3);
      expect(o.toplam, 4);
      expect(o.oran, 0.75);
      expect(o.tarih, DateTime(2026, 10, 2));
    });
    test('öğrencisiz sınıfta oran 0', () {
      final o = yoklamaOzeti({'tarih': '2026-10-02', 'kayitlar': {}}, const [])!;
      expect(o.oran, 0);
    });
  });

  group('yoklamaGunEtiketi', () {
    final simdi = DateTime(2026, 10, 2, 9, 30);
    test('bugün / dün', () {
      expect(yoklamaGunEtiketi(DateTime(2026, 10, 2), simdi), 'bugün');
      expect(yoklamaGunEtiketi(DateTime(2026, 10, 1), simdi), 'dün');
    });
    test('daha eski: tarih yazıyla', () {
      expect(yoklamaGunEtiketi(DateTime(2026, 9, 28), simdi), '28 Eylül');
      expect(yoklamaGunEtiketi(DateTime(2025, 12, 5), simdi), '5 Aralık 2025');
    });
  });
}
