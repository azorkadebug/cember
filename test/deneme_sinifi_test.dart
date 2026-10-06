import 'package:cember/models/kontrol_kalemi.dart';
import 'package:cember/services/deneme_sinifi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final idler = [for (var i = 0; i < 12; i++) 'id$i'];
  final ogr = DenemeSinifi.ogrenciler(idler);

  test('12 öğrenci, 6 kız 6 erkek, kimlikler benzersiz', () {
    expect(ogr.length, 12);
    expect(ogr.where((o) => o.isMale).length, 6);
    expect(ogr.map((o) => o.id).toSet().length, 12);
  });

  test('her özelliğin örneği var ve geçerli', () {
    expect(ogr.where((o) => o.element == 'ates').length, 2);
    expect(ogr.where((o) => o.element == 'su').length, 2);
    final esli = ogr.where((o) => o.eslesenIdler.isNotEmpty).toList();
    expect(esli.length, 2);
    expect(esli[0].eslesenIdler, [esli[1].id]);
    expect(esli[1].eslesenIdler, [esli[0].id]);
    expect(ogr.where((o) => o.not.isNotEmpty).length, 1);
    expect(ogr.where((o) => o.rozetler.isNotEmpty).length, 1);
    // Sayaç anahtarları beden eğitimi şablonundaki kalemlerle aynı.
    final kalemIdleri = bransSablonu('beden_egitimi').varsayilanKalemler.map((k) => k.id).toSet();
    for (final o in ogr) {
      expect(kalemIdleri.containsAll(o.kalemSayaclari.keys), isTrue, reason: o.ad);
      expect(o.toMap()['ad'], o.ad);
    }
  });

  test('dünkü yoklama: 11 geldi, 1 kıyafet eksik', () {
    final y = DenemeSinifi.dunkuYoklama(idler);
    expect(y.length, 12);
    expect(y.values.where((k) => (k as Map)['geldi'] == true).length, 11);
    expect(y.values.where((k) => ((k as Map)['kalemler'] as Map?)?['kiyafet'] == false).length, 1);
  });
}
