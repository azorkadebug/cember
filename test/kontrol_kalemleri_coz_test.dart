import 'package:cember/models/kontrol_kalemi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> k(String id, int sira) =>
      {'id': id, 'ad': id, 'ikon': 'check', 'tip': 'gunluk', 'sira': sira};

  test('alan yok -> branş varsayılanı', () {
    final r = kontrolKalemleriCoz(null, 'beden_egitimi');
    expect(r, isNotEmpty);
    expect(r.length, bransSablonu('beden_egitimi').varsayilanKalemler.length);
  });
  test('boş liste -> boş kalır (varsayılan geri gelmez)', () {
    expect(kontrolKalemleriCoz(<dynamic>[], 'beden_egitimi'), isEmpty);
  });
  test('dolu liste -> sira ile sıralı', () {
    final r = kontrolKalemleriCoz([k('b', 2), k('a', 1)], 'beden_egitimi');
    expect(r.map((e) => e.id), ['a', 'b']);
  });
  test('bozuk değer (liste değil) -> varsayılan', () {
    expect(kontrolKalemleriCoz('x', 'beden_egitimi'), isNotEmpty);
  });
}
