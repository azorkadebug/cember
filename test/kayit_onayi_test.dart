import 'dart:async';
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cember/utils/kayit_onayi.dart';

/// Çevrimdışı kart kaydı geri bildirimi (denetim #5 ek).
void main() {
  late Completer<int> yazim;
  late List<String> olaylar;
  bool aktif = true;

  // Completer fakeAsync bölgesinin İÇİNDE kurulmalı; yoksa mikro görevler
  // sahte saatle akmaz.
  KayitOnayi<int> kur() {
    yazim = Completer<int>();
    return KayitOnayi<int>(
        yazim: yazim.future,
        aktif: () => aktif,
        onay: (v, gec) => olaylar.add(gec ? 'gec-onay' : 'onay'),
        bekliyor: () => olaylar.add('bekliyor'),
        hata: (e) => olaylar.add('hata'),
      );
  }

  setUp(() {
    yazim = Completer<int>();
    olaylar = [];
    aktif = true;
  });

  test('hızlı onay: yalnız onay', () {
    fakeAsync((a) {
      kur();
      a.elapse(const Duration(milliseconds: 500));
      yazim.complete(1);
      a.elapse(const Duration(seconds: 10));
      expect(olaylar, ['onay']);
    });
  });

  test('geç onay: önce bekliyor, sonra gec onay', () {
    fakeAsync((a) {
      kur();
      a.elapse(const Duration(seconds: 3));
      expect(olaylar, ['bekliyor']);
      yazim.complete(1);
      a.flushMicrotasks();
      expect(olaylar, ['bekliyor', 'gec-onay']);
    });
  });

  test('geç ret: bekliyor sonra hata', () {
    fakeAsync((a) {
      kur();
      a.elapse(const Duration(seconds: 3));
      yazim.completeError(StateError('x'));
      a.flushMicrotasks();
      expect(olaylar, ['bekliyor', 'hata']);
    });
  });

  test('hızlı ret: yalnız hata', () {
    fakeAsync((a) {
      kur();
      yazim.completeError(StateError('x'));
      a.elapse(const Duration(seconds: 10));
      expect(olaylar, ['hata']);
    });
  });

  test('hiç onay yok: bekliyor bir kez', () {
    fakeAsync((a) {
      kur();
      a.elapse(const Duration(minutes: 5));
      expect(olaylar, ['bekliyor']);
    });
  });

  test('ekran kapanınca (iptal / mounted yok) bekliyor çıkmaz', () {
    fakeAsync((a) {
      kur().iptal();
      a.elapse(const Duration(seconds: 5));
      expect(olaylar, isEmpty);
    });
    fakeAsync((a) {
      aktif = false;
      kur();
      a.elapse(const Duration(seconds: 5));
      yazim.complete(1);
      a.flushMicrotasks();
      expect(olaylar, isEmpty);
    });
  });
}
