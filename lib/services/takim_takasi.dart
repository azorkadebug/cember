import '../models/ogrenci.dart';

/// Takımlar kurulduktan sonra çatışan elementleri (ateş–su, toprak–hava)
/// aynı cinsiyetten iki öğrenciyi takas ederek ayırır.
///
/// Dağıtım kızları ve erkekleri ayrı ayrı yerleştiriyor; sular kız,
/// ateşler erkekse sular önce iki takıma bölünüyor ve ateşin gidecek
/// çatışmasız takımı kalmıyordu (denetim #4: 2 ateş + 2 su, 6/6 çatışma).
/// Takas kişi sayısını ve kız/erkek dağılımını değiştirmez; eşli
/// öğrencilere dokunmaz. Aynı çatışma azalışını veren takaslardan puan
/// dengesini en az bozanı seçilir.
void catismalariTakasla(List<List<Ogrenci>> takimlar, Map<String, int> puan) {
  int catisma(Iterable<Ogrenci> t) {
    final l = t.where((o) => o.element != null).toList();
    var c = 0;
    for (var i = 0; i < l.length; i++) {
      for (var j = i + 1; j < l.length; j++) {
        if (ElementSistemi.catisir(l[i].element, l[j].element)) c++;
      }
    }
    return c;
  }

  int toplam(List<Ogrenci> t) => t.fold(0, (s, o) => s + (puan[o.id] ?? o.puan));

  for (var tur = 0; tur < 200; tur++) {
    (int, int, int, int)? enIyi; // a, i, b, j
    var enIyiKazanc = 0;
    var enIyiFark = 1 << 30;
    for (var a = 0; a < takimlar.length; a++) {
      final ca = catisma(takimlar[a]);
      if (ca == 0) continue;
      for (var i = 0; i < takimlar[a].length; i++) {
        final x = takimlar[a][i];
        if (x.element == null || x.eslesenIdler.isNotEmpty) continue;
        for (var b = 0; b < takimlar.length; b++) {
          if (b == a) continue;
          final cb = catisma(takimlar[b]);
          for (var j = 0; j < takimlar[b].length; j++) {
            final y = takimlar[b][j];
            if (y.isMale != x.isMale || y.eslesenIdler.isNotEmpty) continue;
            final yeniA = [...takimlar[a]]..[i] = y;
            final yeniB = [...takimlar[b]]..[j] = x;
            final kazanc = ca + cb - catisma(yeniA) - catisma(yeniB);
            if (kazanc <= 0) continue;
            final fark = (toplam(yeniA) - toplam(yeniB)).abs();
            if (kazanc > enIyiKazanc || (kazanc == enIyiKazanc && fark < enIyiFark)) {
              enIyi = (a, i, b, j);
              enIyiKazanc = kazanc;
              enIyiFark = fark;
            }
          }
        }
      }
    }
    if (enIyi == null) return;
    final (a, i, b, j) = enIyi;
    final x = takimlar[a][i];
    takimlar[a][i] = takimlar[b][j];
    takimlar[b][j] = x;
  }
}
