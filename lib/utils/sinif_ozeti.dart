/// Sınıf kartındaki yoklama halkasının saf hesapları (Flutter'a bağlı değil,
/// birim testi kolay olsun diye ayrı).
library;

import 'package:intl/intl.dart';

import 'metin.dart';

/// Halkanın ortasındaki kısaltma: ayırıcılar atılır, en çok 3 karakter.
/// "7-A" → "7A", "8/B" → "8B", "Hazırlık B" → "HB", "Futbol" → "FUT".
String sinifKisaltmasi(String ad) {
  final parcalar = ad
      .trim()
      .split(RegExp(r'[\s\-/._]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parcalar.isEmpty) return '?';
  final birlesik = parcalar.join();
  String sonuc;
  if (birlesik.runes.length <= 3) {
    sonuc = birlesik;
  } else if (parcalar.length > 1) {
    // Sayılar bütün kalır ("10-A Fen" → "10AF" → "10A"), sözcüklerin baş harfi.
    sonuc = parcalar
        .map((p) => RegExp(r'^\d+$').hasMatch(p)
            ? p
            : String.fromCharCodes(p.runes.take(1)))
        .join();
  } else {
    sonuc = birlesik;
  }
  return trBuyut(String.fromCharCodes(sonuc.runes.take(3)));
}

/// Bir sınıfın son yoklamasının özeti.
class YoklamaOzeti {
  final int gelen;
  final int toplam;
  final DateTime tarih;
  const YoklamaOzeti({required this.gelen, required this.toplam, required this.tarih});

  double get oran => toplam == 0 ? 0 : (gelen / toplam).clamp(0.0, 1.0);
}

/// Son yoklama dokümanından özet çıkarır; doküman yoksa ya da tarihi
/// okunamıyorsa null ("yoklama alınmadı").
///
/// Sayım yalnız sınıfın ŞU ANKİ öğrencileri üzerinden yapılır (silinen
/// öğrencinin eski kaydı sayılmaz). Kaydı olmayan öğrenci "geldi" sayılır —
/// Yoklama ekranı da varsayılanı böyle kurar; tek öğrenciye "Yok yaz"
/// kaydırması da yalnız o öğrenciyi yazar.
YoklamaOzeti? yoklamaOzeti(Map<String, dynamic>? yoklama, Iterable<String> ogrenciIdleri) {
  if (yoklama == null) return null;
  final tarih = DateTime.tryParse('${yoklama['tarih'] ?? ''}');
  if (tarih == null) return null;
  final kayitlar = (yoklama['kayitlar'] as Map?) ?? const {};
  var toplam = 0, gelen = 0;
  for (final id in ogrenciIdleri) {
    toplam++;
    final r = kayitlar[id];
    final geldi = r is Map ? r['geldi'] != false : true;
    if (geldi) gelen++;
  }
  return YoklamaOzeti(gelen: gelen, toplam: toplam, tarih: tarih);
}

/// "bugün", "dün", "28 Eylül", başka yılsa "28 Eylül 2025".
String yoklamaGunEtiketi(DateTime tarih, DateTime simdi) {
  // UTC gün farkı: yaz saati geçişinde 23 saatlik gün "0 gün" sayılmasın.
  final g = DateTime.utc(tarih.year, tarih.month, tarih.day);
  final b = DateTime.utc(simdi.year, simdi.month, simdi.day);
  final fark = b.difference(g).inDays;
  if (fark == 0) return 'bugün';
  if (fark == 1) return 'dün';
  final bicim = tarih.year == simdi.year ? 'd MMMM' : 'd MMMM yyyy';
  return DateFormat(bicim, 'tr').format(tarih);
}
