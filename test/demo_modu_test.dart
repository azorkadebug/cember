import 'package:cember/services/demo_modu.dart';
import 'package:cember/tema.dart';
import 'package:cember/utils/metin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo modu tercihi yeniden yüklemede korunur (denetim #3)', () async {
    SharedPreferences.setMockInitialValues({});
    await DemoModu.yukle();
    expect(DemoModu.aktif, isFalse);

    DemoModu.aktif = true;
    await Future<void>.delayed(Duration.zero);
    DemoModu.durum.value = false; // "sayfa yenilendi"
    await DemoModu.yukle();
    expect(DemoModu.aktif, isTrue);

    DemoModu.aktif = false;
    await Future<void>.delayed(Duration.zero);
    await DemoModu.yukle();
    expect(DemoModu.aktif, isFalse);
  });

  test('demo modunda sahte ad gerçek adla aynı değil', () {
    DemoModu.durum.value = true;
    expect(DemoModu.isimGetir('Hasan İnce', true), isNot('Hasan İnce'));
    DemoModu.durum.value = false;
    DemoModu.sifirla();
    expect(DemoModu.isimGetir('Hasan İnce', true), 'Hasan İnce');
  });

  test('hesap silme onayı Türkçe klavyeyle yazılan "sil"i kabul eder', () {
    for (final yazilan in ['SİL', 'sil', 'Sil', ' sil ']) {
      expect(trBuyut(yazilan.trim()), 'SİL', reason: yazilan);
    }
    expect(trBuyut('SIL'), 'SIL'); // Türkçe dışı klavye — ekranda ayrıca kabul edilir
  });

  test('yan yana öğrenciler aynı rengi almaz, renk sınıf içinde sabit', () {
    final idler = [for (var i = 0; i < 30; i++) 'ogr$i'];
    final harita = AppTema.ogrenciRenkHaritasi(idler);
    for (var i = 1; i < idler.length; i++) {
      expect(harita[idler[i]], isNot(harita[idler[i - 1]]), reason: '$i');
    }
    expect(AppTema.ogrenciRengi('ogr3', harita), harita['ogr3']);
    // İlk 8 öğrencinin hepsi farklı renkte.
    expect(idler.take(8).map((id) => harita[id]).toSet().length, 8);
  });
}
