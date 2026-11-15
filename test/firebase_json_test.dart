import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// firebase.json Hosting önbellek kuralları (denetim #5 O2).
/// build/web'de adı içerik hash'i taşıyan dosya yok; "immutable" ya da
/// uzun max-age verilen bir dosya aynı adla değişirse tarayıcı eskisini
/// aylarca gösterir (3 Eki 2026 yeni logo → eski ikon 2027'ye kadar).
void main() {
  final hosting = (jsonDecode(File('firebase.json').readAsStringSync())
      as Map<String, dynamic>)['hosting'] as Map<String, dynamic>;
  final kurallar = (hosting['headers'] as List).cast<Map<String, dynamic>>();

  test('hiçbir kural immutable ya da 1 haftadan uzun önbellek vermiyor', () {
    for (final kural in kurallar) {
      for (final b in (kural['headers'] as List).cast<Map<String, dynamic>>()) {
        if (b['key'] != 'Cache-Control') continue;
        final deger = b['value'] as String;
        expect(deger.contains('immutable'), isFalse,
            reason: '${kural['source']}: $deger');
        final maxAge = RegExp(r'max-age=(\d+)').firstMatch(deger);
        if (maxAge != null) {
          expect(int.parse(maxAge.group(1)!), lessThanOrEqualTo(604800),
              reason: '${kural['source']}: $deger');
        }
      }
    }
  });

  test('manifest ikonları sürüm parametresiyle anılıyor', () {
    final manifest = jsonDecode(File('web/manifest.json').readAsStringSync())
        as Map<String, dynamic>;
    for (final ikon in (manifest['icons'] as List).cast<Map<String, dynamic>>()) {
      expect(ikon['src'] as String, contains('?v='));
    }
  });
}
