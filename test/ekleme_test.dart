import 'package:flutter_test/flutter_test.dart';
import 'package:cember/utils/bekleyen_yazma.dart';
import 'package:cember/utils/toplu_ekleme.dart';

void main() {
  group('cinsiyetsizSatirlar', () {
    test('adı dolu ve cinsiyeti seçilmemiş satırları bulur, boşları saymaz', () {
      final r = cinsiyetsizSatirlar([
        (ad: 'Ali', cinsiyetSecildi: true),
        (ad: 'Veli', cinsiyetSecildi: false),
        (ad: '  ', cinsiyetSecildi: false),
        (ad: '', cinsiyetSecildi: false),
        (ad: 'Ayşe', cinsiyetSecildi: false),
      ]);
      expect(r, [1, 4]);
    });
    test('hepsi seçiliyse boş', () {
      expect(cinsiyetsizSatirlar([(ad: 'Ali', cinsiyetSecildi: true)]), isEmpty);
    });
  });

  group('cakisanSatirlar', () {
    test('Türkçe harfe duyarsız: İrem/irem, ISIL/ısıl', () {
      expect(cakisanSatirlar(['irem', 'ısıl', 'Can'], {'İrem', 'ISIL'}), {0, 1});
    });
    test('aynı partideki tekrarı ikinci satırda yakalar', () {
      expect(cakisanSatirlar(['Ali Veli', 'ali veli', 'Ayşe'], {}), {1});
    });
    test('boş adlar atlanır, fazla boşluk yok sayılır', () {
      expect(cakisanSatirlar(['', 'Ali  Veli', ' ali veli '], {}), {2});
    });
    test('farklı ad çakışmaz', () {
      expect(cakisanSatirlar(['Ali', 'Veli'], {'Ayşe'}), isEmpty);
    });
  });

  group('tekrarEdenAdlar', () {
    test('iki sınıftaki aynı ad bir kez raporlanır', () {
      expect(tekrarEdenAdlar(['Ali Veli', 'Ayşe', 'ali veli', 'AYŞE', 'Can']), ['Ali Veli', 'Ayşe']);
    });
    test('tekrar yoksa boş', () {
      expect(tekrarEdenAdlar(['Ali', 'Veli']), isEmpty);
    });
  });

  group('bekleyenYazmalarGitti', () {
    test('süresinde biterse true', () async {
      expect(await bekleyenYazmalarGitti(() async {}), isTrue);
    });
    test('süre dolarsa false', () async {
      final r = await bekleyenYazmalarGitti(
          () => Future<void>.delayed(const Duration(seconds: 5)),
          sure: const Duration(milliseconds: 50));
      expect(r, isFalse);
    });
    test('hata verirse (istemci kapalı) true', () async {
      expect(await bekleyenYazmalarGitti(() async => throw StateError('x')), isTrue);
    });
  });
}
