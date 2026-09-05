// Denetim #3 / Ajan E — TASLAK: takım kurma algoritmasının saf fonksiyon hâli.
//
// Bu dosya lib/screens/ogrenci_listesi_ekrani.dart `_takimlariKur`
// içindeki 2031–2131 satırlarının (efektif puan, kız/erkek ayrımı,
// elementUyumPuani, eslesUyumPuani, birimiYerlestir, dengeliDagit)
// BİREBİR kopyasıdır; yalnızca `secilenTakimSayisi`, `_random` ve
// `takimlar` closure değişkenleri parametre/yerel değişkene çevrildi.
//
// Amaç: algoritma bir State metoduna gömülü olduğu için lib/ değişmeden
// test edilemiyor. Bu kopya, "lib/services/takim_kurucu.dart" olarak
// taşındığında testlerin aynen çalışacağını gösterir. lib/ taşınınca bu
// dosya SİLİNMELİ ve test import'u lib'e çevrilmeli.
import 'dart:math';

import 'package:cember/models/ogrenci.dart';

List<List<Ogrenci>> takimlariDagit(
  List<Ogrenci> gelenler,
  int secilenTakimSayisi, {
  Random? random,
  /// ÖNERİLEN DÜZELTME (denetim #3, E-1): elementli ya da elle eşleştirilmiş
  /// öğrenciler kendi cinsiyet listelerinde ÖNE alınır (puan sırası
  /// korunarak). Böylece "en az kişili takım" kısıtı onları zorla
  /// çatışan takıma itmeden önce yerleşmiş olurlar. 1000 tohumluk
  /// ölçümde çatışma 237/1000 → 0/1000, ortalama puan farkı 11,04 → 11,08.
  bool kisitlilarOnce = false,
}) {
  final rnd = random ?? Random();

  // Efektif puan: gerçek puan + rastgele -4/+4
  final Map<String, int> efektifPuan = {};
  for (var o in gelenler) {
    efektifPuan[o.id] = o.puan + rnd.nextInt(9) - 4;
  }

  // Kız-erkek ayır
  final kizlar = gelenler.where((o) => !o.isMale).toList();
  final erkekler = gelenler.where((o) => o.isMale).toList();

  // Her grubu efektif puana göre sırala
  kizlar.sort((a, b) => efektifPuan[b.id]!.compareTo(efektifPuan[a.id]!));
  erkekler.sort((a, b) => efektifPuan[b.id]!.compareTo(efektifPuan[a.id]!));

  List<Ogrenci> kisitliOne(List<Ogrenci> l) {
    if (!kisitlilarOnce) return l;
    bool kisitli(Ogrenci o) => o.element != null || o.eslesenIdler.isNotEmpty;
    // List.sort kararlı değil; puan sırasını korumak için iki parça.
    return [...l.where(kisitli), ...l.where((o) => !kisitli(o))];
  }

  final kizlarSirali = kisitliOne(kizlar);
  final erkeklerSirali = kisitliOne(erkekler);

  List<List<Ogrenci>> takimlar = List.generate(secilenTakimSayisi, (_) => []);
  List<int> takimPuanlari = List.filled(secilenTakimSayisi, 0);

  int elementUyumPuani(int takimIdx, Ogrenci o) {
    if (o.element == null) return 0;
    int puan = 0;
    for (final m in takimlar[takimIdx]) {
      if (m.element == null) continue;
      if (m.element == o.element) {
        puan += 10;
      } else if (ElementSistemi.catisir(o.element, m.element)) {
        puan -= 100;
      }
    }
    return puan;
  }

  int eslesUyumPuani(int takimIdx, Ogrenci o) {
    if (o.eslesenIdler.isEmpty) return 0;
    int puan = 0;
    for (final m in takimlar[takimIdx]) {
      if (o.eslesenIdler.contains(m.id)) puan += 1000;
    }
    return puan;
  }

  final gelenIdler = {for (final o in gelenler) o.id: o};
  final yerlesti = <String>{};
  void birimiYerlestir(int hedef, Ogrenci o) {
    if (yerlesti.contains(o.id)) return;
    yerlesti.add(o.id);
    takimlar[hedef].add(o);
    takimPuanlari[hedef] += efektifPuan[o.id]!;
    for (final eid in o.eslesenIdler) {
      final es = gelenIdler[eid];
      if (es != null) birimiYerlestir(hedef, es);
    }
  }

  void dengeliDagit(List<Ogrenci> liste) {
    for (var o in liste) {
      if (yerlesti.contains(o.id)) continue;
      final minKisi = takimlar.map((t) => t.length).reduce((a, b) => a < b ? a : b);
      final enAzKisiTakimlar = <int>[
        for (var t = 0; t < secilenTakimSayisi; t++)
          if (takimlar[t].length == minKisi) t,
      ];
      final uyumPuanlari = {
        for (final t in enAzKisiTakimlar)
          t: eslesUyumPuani(t, o) + elementUyumPuani(t, o),
      };
      final maxUyum = uyumPuanlari.values.reduce((a, b) => a > b ? a : b);
      final adaylar =
          enAzKisiTakimlar.where((t) => uyumPuanlari[t] == maxUyum).toList();
      final hedef = adaylar.reduce(
        (a, b) => takimPuanlari[a] <= takimPuanlari[b] ? a : b,
      );
      birimiYerlestir(hedef, o);
    }
  }

  dengeliDagit(kizlarSirali);
  dengeliDagit(erkeklerSirali);
  return takimlar;
}
