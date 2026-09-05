/// Türkçe'ye duyarlı metin yardımcıları.
///
/// Dart'ın `toLowerCase()`'i "İ"yi "i̇" (i + birleşik nokta), "I"yı "i"
/// yapar; "İrem" araması "irem" ile eşleşmez, sıralamada Ş ve Ç sona düşer.
library;

String trKucult(String s) => s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();

const _sira = 'aâbcçdefgğhıiîjklmnoöprsştuüûvyz';

/// Türk alfabesine göre karşılaştırma (a < b → negatif). Harf dışı
/// karakterler kod noktasıyla sıralanır.
int trKarsilastir(String a, String b) {
  final x = trKucult(a), y = trKucult(b);
  final n = x.length < y.length ? x.length : y.length;
  for (var i = 0; i < n; i++) {
    if (x[i] == y[i]) continue;
    final ix = _sira.indexOf(x[i]), iy = _sira.indexOf(y[i]);
    if (ix >= 0 && iy >= 0) return ix - iy;
    // Harf dışı (rakam, tire, boşluk) harften önce gelir: "5-A" < "5S".
    if (ix >= 0) return 1;
    if (iy >= 0) return -1;
    return x.codeUnitAt(i) - y.codeUnitAt(i);
  }
  return x.length - y.length;
}
