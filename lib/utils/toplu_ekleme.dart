/// "Hızlı Öğrenci Ekle" için saf karar mantığı (arayüzden ayrık, test edilir).
library;

import 'metin.dart';

/// Ad karşılaştırma anahtarı: Türkçe büyük/küçük harfe duyarsız, baştaki/
/// sondaki ve ardışık boşluklar yok sayılır ("Ali  VELİ" = "ali veli").
String adAnahtari(String ad) => trKucult(ad.trim().replaceAll(RegExp(r'\s+'), ' '));

/// Adı dolu olup cinsiyeti seçilmemiş satırların sırası. Boş (adsız) satırlar
/// sayılmaz. Seçilmemiş satır sessizce erkek kaydediliyordu; takım kurma
/// cinsiyet dengesine dayandığı için yanlış kayıt takımları bozuyordu.
List<int> cinsiyetsizSatirlar(List<({String ad, bool cinsiyetSecildi})> satirlar) => [
      for (var i = 0; i < satirlar.length; i++)
        if (satirlar[i].ad.trim().isNotEmpty && !satirlar[i].cinsiyetSecildi) i,
    ];

/// Çakışan (zaten kayıtlı ya da aynı partide daha önce geçen) satırların
/// sırası. Boş adlar atlanır. Aynı partide "Ali Veli" + "ali veli" ise
/// İKİNCİ satır çakışır; birincisi yeni sayılır.
Set<int> cakisanSatirlar(List<String> adlar, Set<String> mevcutAdlar) {
  final mevcut = mevcutAdlar.map(adAnahtari).toSet();
  final partide = <String>{};
  final sonuc = <int>{};
  for (var i = 0; i < adlar.length; i++) {
    if (adlar[i].trim().isEmpty) continue;
    final k = adAnahtari(adlar[i]);
    if (mevcut.contains(k) || !partide.add(k)) sonuc.add(i);
  }
  return sonuc;
}

/// Listede birden çok kez geçen adlar (ilk görünen yazımıyla, sıra korunur).
/// "Geçen Yıldan Ekle"de iki eski sınıftan seçilen aynı adlı öğrenciyi
/// yakalamak için.
List<String> tekrarEdenAdlar(Iterable<String> adlar) {
  final sayac = <String, int>{};
  final ilkYazim = <String, String>{};
  for (final ad in adlar) {
    final k = adAnahtari(ad);
    if (k.isEmpty) continue;
    sayac[k] = (sayac[k] ?? 0) + 1;
    ilkYazim.putIfAbsent(k, () => ad.trim());
  }
  return [for (final e in sayac.entries) if (e.value > 1) ilkYazim[e.key]!];
}
