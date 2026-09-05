// Denetim #3 / Ajan E — takım kurma algoritması özellik testleri.
//
// Algoritma lib/screens/ogrenci_listesi_ekrani.dart:_takimlariKur içinde
// State'e gömülü olduğu için doğrudan import edilemiyor; testler
// test/yardimci/takim_kurucu_taslak.dart'taki birebir kopya üzerinde
// çalışıyor. Algoritma lib/services/takim_kurucu.dart'a taşınınca
// aşağıdaki import değiştirilip taslak silinmeli.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:cember/models/ogrenci.dart';
import 'yardimci/takim_kurucu_taslak.dart';

Ogrenci _o(String id,
        {int puan = 100,
        bool kiz = false,
        String? element,
        List<String>? es}) =>
    Ogrenci(id: id, ad: id, puan: puan, isMale: !kiz, element: element, eslesenIdler: es);

List<Ogrenci> _sinif({int kiz = 0, int erkek = 0, Random? rnd}) {
  final r = rnd ?? Random(1);
  return [
    for (var i = 0; i < kiz; i++) _o('k$i', kiz: true, puan: 80 + r.nextInt(60)),
    for (var i = 0; i < erkek; i++) _o('e$i', puan: 80 + r.nextInt(60)),
  ];
}

int _maxFark(List<List<Ogrenci>> t) {
  final n = t.map((x) => x.length).toList();
  return n.reduce(max) - n.reduce(min);
}

void main() {
  group('Kişi sayısı dengesi (hard constraint)', () {
    test('eş yokken takımlar arası fark ≤ 1, kimse kaybolmaz/çoğalmaz', () {
      for (var seed = 0; seed < 200; seed++) {
        final rnd = Random(seed);
        final kiz = rnd.nextInt(15), erkek = rnd.nextInt(15);
        final takimSayisi = 2 + rnd.nextInt(5);
        final sinif = _sinif(kiz: kiz, erkek: erkek, rnd: rnd);
        if (sinif.length < takimSayisi) continue;

        final t = takimlariDagit(sinif, takimSayisi, random: rnd);
        expect(t.length, takimSayisi);
        expect(_maxFark(t), lessThanOrEqualTo(1), reason: 'seed $seed');
        final hepsi = t.expand((x) => x).map((o) => o.id).toList();
        expect(hepsi.toSet().length, hepsi.length, reason: 'seed $seed (çift)');
        expect(hepsi.length, sinif.length, reason: 'seed $seed (kayıp)');
      }
    });

    test('kız sayısı da takımlar arasında ≤ 1 fark', () {
      for (var seed = 0; seed < 100; seed++) {
        final rnd = Random(seed);
        final sinif = _sinif(kiz: 7, erkek: 9, rnd: rnd);
        final t = takimlariDagit(sinif, 3, random: rnd);
        final kizSayilari = t.map((x) => x.where((o) => !o.isMale).length).toList();
        expect(kizSayilari.reduce(max) - kizSayilari.reduce(min),
            lessThanOrEqualTo(1),
            reason: 'seed $seed');
      }
    });

    test('öğrenci sayısı takım sayısına eşitse her takıma 1 kişi', () {
      final t = takimlariDagit(_sinif(erkek: 4), 4, random: Random(0));
      expect(t.every((x) => x.length == 1), isTrue);
    });
  });

  group('Puan dengesi (tie-breaker)', () {
    test('aynı cinsiyet, 100/90/80/70 → toplamlar ±(2×4 gürültü) içinde eşit',
        () {
      final sinif = [
        _o('a', puan: 100),
        _o('b', puan: 90),
        _o('c', puan: 80),
        _o('d', puan: 70),
      ];
      for (var seed = 0; seed < 50; seed++) {
        final t = takimlariDagit(sinif, 2, random: Random(seed));
        final toplam = t.map((x) => x.fold(0, (s, o) => s + o.puan)).toList();
        // Gürültüsüz ideal 170/170; her oyuncuya ±4 gürültü sıralamayı
        // değiştirebilir → en kötü 20 fark.
        expect((toplam[0] - toplam[1]).abs(), lessThanOrEqualTo(20),
            reason: 'seed $seed → $toplam');
      }
    });

    test('bir yıldız (200) diğer takımın toplamıyla dengelenir', () {
      final sinif = [
        _o('yildiz', puan: 200),
        _o('b', puan: 100),
        _o('c', puan: 100),
        _o('d', puan: 100),
      ];
      final t = takimlariDagit(sinif, 2, random: Random(3));
      final yildizTakimi = t.firstWhere((x) => x.any((o) => o.id == 'yildiz'));
      // Yıldız ilk yerleşir, sonraki iki oyuncu düşük toplamlı takıma gider,
      // dördüncü yine kişi dengesi gereği yıldızın yanına.
      expect(yildizTakimi.length, 2);
    });
  });

  group('Element çatışması (soft constraint)', () {
    test('BULGU E-1: ateş ve su, yer varken bile ~%10–24 aynı takıma düşüyor', () {
      // Sebep: elementsiz bir öğrenci beraberlik bozduğunda "en az kişili
      // takım" kısıtı su'yu ateşin takımına ZORLUYOR (ileriye bakış yok).
      int catisma(List<Ogrenci> Function(Random) sinif, int takim,
          {bool duzeltme = false}) {
        var c = 0;
        for (var seed = 0; seed < 1000; seed++) {
          final r = Random(seed);
          final t = takimlariDagit(sinif(r), takim,
              random: r, kisitlilarOnce: duzeltme);
          for (final tk in t) {
            final e = tk.map((o) => o.element).toSet();
            if (e.contains('ates') && e.contains('su')) {
              c++;
              break;
            }
          }
        }
        return c;
      }

      List<Ogrenci> kucuk(Random r) => [
            _o('ates', element: 'ates'),
            _o('su', element: 'su'),
            _o('n1'),
            _o('n2'),
          ];
      List<Ogrenci> yirmi(Random r) {
        final s = _sinif(kiz: 10, erkek: 10, rnd: r);
        s[0].element = 'ates';
        s[1].element = 'su';
        return s;
      }

      // Mevcut davranış (ölçüm, 1000 tohum): 100/1000 ve 237/1000.
      expect(catisma(kucuk, 2), inInclusiveRange(50, 200));
      expect(catisma(yirmi, 2), inInclusiveRange(150, 350));
      // Önerilen düzeltme ile: 0.
      expect(catisma(kucuk, 2, duzeltme: true), 0);
      expect(catisma(yirmi, 2, duzeltme: true), 0);
    });

    test('kişi dengesi element uyumundan önce gelir (3 ateş + 1 su, 2 takım)',
        () {
      final sinif = [
        _o('a1', element: 'ates'),
        _o('a2', element: 'ates'),
        _o('a3', element: 'ates'),
        _o('su', element: 'su'),
      ];
      final t = takimlariDagit(sinif, 2, random: Random(0));
      expect(_maxFark(t), 0); // 2-2; su ister istemez bir ateşle
    });

    test('aynı element +10 bonusu: 2 ateş 2 su 2 takımda ateşler beraber', () {
      final sinif = [
        _o('a1', element: 'ates', puan: 100),
        _o('a2', element: 'ates', puan: 100),
        _o('s1', element: 'su', puan: 100),
        _o('s2', element: 'su', puan: 100),
      ];
      var beraber = 0;
      for (var seed = 0; seed < 100; seed++) {
        final t = takimlariDagit(sinif, 2, random: Random(seed));
        final ids = t.map((x) => x.map((o) => o.id).toSet()).toList();
        if (ids.any((s) => s.containsAll({'a1', 'a2'}))) beraber++;
      }
      // Sıralama gürültüye bağlı; ilk iki yerleşen kişi dengesi gereği
      // ayrılır. Sadece belgeleme: bonus her zaman uygulanamıyor.
      expect(beraber, greaterThan(0));
    });
  });

  group('Elle eşleştirme (eslesenIdler) — tek birim', () {
    test('karşılıklı eş her seferinde aynı takımda', () {
      for (var seed = 0; seed < 200; seed++) {
        final rnd = Random(seed);
        final sinif = _sinif(kiz: 6, erkek: 6, rnd: rnd);
        // k0↔e0 ve k1↔k2 eş.
        sinif[0].eslesenIdler.add('e0');
        sinif[6].eslesenIdler.add('k0');
        sinif[1].eslesenIdler.add('k2');
        sinif[2].eslesenIdler.add('k1');

        final t = takimlariDagit(sinif, 3, random: rnd);
        int takimi(String id) => t.indexWhere((x) => x.any((o) => o.id == id));
        expect(takimi('k0'), takimi('e0'), reason: 'seed $seed');
        expect(takimi('k1'), takimi('k2'), reason: 'seed $seed');
        // Birim yerleşimi kişi dengesini en fazla birim büyüklüğü kadar bozar.
        expect(_maxFark(t), lessThanOrEqualTo(2), reason: 'seed $seed');
      }
    });

    test('tek yönlü (bozuk) eş de aynı takıma çeker', () {
      // Firestore'da karşılıklılık bozulmuşsa (A→B var, B→A yok) A önce
      // yerleşirse B'yi çeker; B önce yerleşirse A çekilmez. Belgeleme.
      final sinif = [
        _o('a', puan: 100, es: ['b']),
        _o('b', puan: 100),
        _o('c', puan: 100),
        _o('d', puan: 100),
      ];
      var ayrildi = 0;
      for (var seed = 0; seed < 100; seed++) {
        final t = takimlariDagit(sinif, 2, random: Random(seed));
        int takimi(String id) => t.indexWhere((x) => x.any((o) => o.id == id));
        if (takimi('a') != takimi('b')) ayrildi++;
      }
      expect(ayrildi, greaterThan(0),
          reason: 'tek yönlü eş bazen ayrılıyor — karşılıklılık şart');
    });

    test('gelmeyen (listede olmayan) eş yerleşimi bozmaz', () {
      final sinif = [
        _o('a', es: ['yok']),
        _o('b'),
      ];
      final t = takimlariDagit(sinif, 2, random: Random(0));
      expect(_maxFark(t), 0);
    });

    test('eş zinciri (a↔b, b↔c) üçünü de tek takıma alır', () {
      final sinif = [
        _o('a', es: ['b']),
        _o('b', es: ['a', 'c']),
        _o('c', es: ['b']),
        _o('d'),
        _o('e'),
        _o('f'),
      ];
      final t = takimlariDagit(sinif, 2, random: Random(0));
      int takimi(String id) => t.indexWhere((x) => x.any((o) => o.id == id));
      expect(takimi('a'), takimi('b'));
      expect(takimi('b'), takimi('c'));
    });

    test('BULGU E-1b: 3\'lü zincir + 3 tekil, 2 takım → ~%20 4-2 dağılıyor', () {
      // 3-3 mümkünken tekiller önce yerleşip beraberliği bozunca zincir
      // "en az kişili" takıma 3 kişi olarak iner. Kısıtlılar önce
      // yerleşirse her seferinde 3-3.
      int dortIki({bool duzeltme = false}) {
        var c = 0;
        for (var seed = 0; seed < 1000; seed++) {
          final r = Random(seed);
          final sinif = [
            _o('a', es: ['b'], puan: 80 + r.nextInt(60)),
            _o('b', es: ['a', 'c'], puan: 80 + r.nextInt(60)),
            _o('c', es: ['b'], puan: 80 + r.nextInt(60)),
            _o('d', puan: 80 + r.nextInt(60)),
            _o('e', puan: 80 + r.nextInt(60)),
            _o('f', puan: 80 + r.nextInt(60)),
          ];
          final t = takimlariDagit(sinif, 2, random: r, kisitlilarOnce: duzeltme);
          if (_maxFark(t) == 2) c++;
        }
        return c;
      }

      expect(dortIki(), inInclusiveRange(100, 300)); // ölçüm: 196/1000
      expect(dortIki(duzeltme: true), 0);
    });

    test('BÜYÜK eş birimi kişi dengesini bozar (4 kişilik zincir, 3 takım)', () {
      final sinif = [
        _o('a', es: ['b', 'c', 'd']),
        _o('b', es: ['a']),
        _o('c', es: ['a']),
        _o('d', es: ['a']),
        _o('e'),
        _o('f'),
      ];
      final t = takimlariDagit(sinif, 3, random: Random(0));
      // 4-1-1 kaçınılmaz; algoritma bunu engellemiyor, UI da uyarmıyor.
      expect(_maxFark(t), 3);
    });
  });
}
