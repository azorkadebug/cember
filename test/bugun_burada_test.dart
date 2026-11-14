// "Bugün burada mı" tek tanımı — denetim #5 Y1 (kalıcı "Yok" işareti).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cember/models/ogrenci.dart';
import 'package:cember/utils/bugun_burada.dart';
import 'package:cember/utils/sinif_ozeti.dart';

void main() {
  final pazartesi = DateTime(2026, 11, 16, 10, 30);
  final sali = DateTime(2026, 11, 17, 9, 0);

  List<Ogrenci> sinif() => [
        Ogrenci(id: 'arda', ad: 'Arda', isMale: true),
        Ogrenci(id: 'bera', ad: 'Bera', isMale: false),
        Ogrenci(id: 'can', ad: 'Can', isMale: true),
      ];

  Map<String, dynamic> yoklama(String tarih, Map<String, bool> geldi) => {
        'tarih': tarih,
        'kayitlar': {for (final e in geldi.entries) e.key: {'geldi': e.value}},
      };

  test('gün anahtarı ISO ve sıfır dolgulu', () {
    expect(gunAnahtari(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
  });

  test('dün yok yazıldı → bugün takım kurmaya giriyor', () {
    final dunku = yoklama('2026-11-16', {'arda': false});
    final gelmeyen = bugunGelmeyenler('2026-11-16', dunku, sali);
    expect(gelmeyen, isEmpty);
    expect(bugunGelenler(sinif(), gelmeyen).map((o) => o.id), contains('arda'));
  });

  test('bugün yok yazıldı → takım kurmaya girmiyor', () {
    final bugunku = yoklama('2026-11-16', {'arda': false, 'bera': true});
    final gelmeyen = bugunGelmeyenler('2026-11-16', bugunku, pazartesi);
    expect(gelmeyen, {'arda'});
    expect(bugunGelenler(sinif(), gelmeyen).map((o) => o.id), ['bera', 'can']);
  });

  test('tarihsiz eski buradaMi:false → yoklama yokken takım kurmaya giriyor', () {
    // Canlıda kalmış eski belge: tarih alanı yok, bayrak false.
    final eski = Ogrenci.fromMap('arda', {'ad': 'Arda', 'isMale': true, 'buradaMi': false});
    expect(eski.buradaMi, isFalse);
    final gelmeyen = bugunGelmeyenler(null, null, pazartesi);
    expect(bugunGelenler([eski], gelmeyen), hasLength(1));
  });

  test('yoklamada bugün yok → listede yok; başlık ve kart sayısı tutarlı', () {
    final ogrenciler = sinif();
    final bugunku = yoklama('2026-11-16', {'arda': false, 'can': true, 'silinen': false});
    final gelmeyen = bugunGelmeyenler('2026-11-16', bugunku, pazartesi);
    final listedeYok = ogrenciler.where((o) => gelmeyen.contains(o.id)).map((o) => o.id);
    expect(listedeYok, ['arda']);
    // Başlık ve halka yoklamaOzeti'nden sayar; liste ile aynı sonucu vermeli.
    final ozet = yoklamaOzeti(bugunku, ogrenciler.map((o) => o.id))!;
    expect(ozet.gelen, bugunGelenler(ogrenciler, gelmeyen).length);
    expect(ozet.toplam - ozet.gelen, listedeYok.length);
  });

  test('kayıt biçimi bozuksa geldi sayılır', () {
    expect(kayitGeldiMi(null, 'a'), isTrue);
    expect(kayitGeldiMi({'a': 'x'}, 'a'), isTrue);
    expect(kayitGeldiMi({'a': {'kalemler': {}}}, 'a'), isTrue);
    expect(kayitGeldiMi({'a': {'geldi': false}}, 'a'), isFalse);
    expect(bugunGelmeyenler('2026-11-16', {'kayitlar': 'bozuk'}, pazartesi), isEmpty);
  });

  test('gece yarısına kalan süre', () {
    expect(gunSonunaKalan(DateTime(2026, 11, 16, 23, 59, 30)), const Duration(seconds: 30));
    expect(gunSonunaKalan(DateTime(2026, 12, 31, 12)), const Duration(hours: 12));
  });

  group('gece yarısı geçişi', () {
    testWidgets('açık oturumda zamanlayıcı günü çevirir, dünkü "Yok" düşer', (tester) async {
      var saat = DateTime(2026, 11, 16, 23, 59, 0);
      final bugun = Bugun.test(() => saat);
      var uyari = 0;
      bugun.addListener(() => uyari++);
      final belge = yoklama('2026-11-16', {'arda': false});
      expect(bugun.value, '2026-11-16');
      expect(bugunGelmeyenler('2026-11-16', belge, bugun.simdi), {'arda'});

      // Bir dakika (+1 sn pay) sonra zamanlayıcı uyanır.
      saat = DateTime(2026, 11, 17, 0, 0, 1);
      await tester.pump(const Duration(seconds: 61));
      expect(bugun.value, '2026-11-17');
      expect(uyari, 1);
      expect(bugunGelmeyenler('2026-11-16', belge, bugun.simdi), isEmpty);
      bugun.dispose(); // bekleyen zamanlayıcı test sonunda kalmasın
    });

    testWidgets('uygulama ertesi gün öne gelince gün yeniden hesaplanır', (tester) async {
      var saat = DateTime(2026, 11, 16, 15, 0);
      final bugun = Bugun.test(() => saat);
      saat = DateTime(2026, 11, 17, 8, 0);
      // Arka planda zamanlayıcı çalışmadı varsayımı: yalnız öne gelme.
      bugun.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(bugun.value, '2026-11-17');
      bugun.dispose();
    });

    testWidgets('aynı gün içinde öne gelme dinleyenleri uyarmaz', (tester) async {
      final bugun = Bugun.test(() => DateTime(2026, 11, 16, 15, 0));
      var uyari = 0;
      bugun.addListener(() => uyari++);
      bugun.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(uyari, 0);
      bugun.dispose();
    });
  });
}
