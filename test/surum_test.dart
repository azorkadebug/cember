import 'dart:io';

import 'package:cember/screens/giris_ekrani.dart';
import 'package:flutter_test/flutter_test.dart';

/// Denetim #5 D2: iOS 2.0.1 giriş ekranında "v2.0.0" yazıyordu, çünkü
/// gösterilen sürüm elle tutulan bir sabit. Paket eklemeden pubspec'i
/// çalışma anında okuyamıyoruz; bu test sabitin pubspec ile aynı kalmasını
/// zorunlu kılar: sürüm yükseltilip sabit unutulursa burası kırılır.
void main() {
  test('giriş ekranındaki sürüm pubspec.yaml ile aynı', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final eslesme =
        RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
            .firstMatch(pubspec);
    expect(eslesme, isNotNull, reason: 'pubspec.yaml version satırı yok');
    expect(GirisEkrani.surum, 'v${eslesme!.group(1)}',
        reason: 'pubspec sürümü değişti: lib/screens/giris_ekrani.dart '
            'içindeki GirisEkrani.surum varsayılanını da güncelle');
  });
}
