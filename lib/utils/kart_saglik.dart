import '../models/ogrenci.dart';

/// Öğrenci kartı açıkken sağlık notu ekleme/silme izi.
///
/// Eskiden yeni notlar "liste açılıştakinden uzunsa sondakiler" diye
/// bulunuyordu: kartta not ekleyip geçmişten eski not silmek uzunluğu aynı
/// bırakıyor, yeni not sunucuya yazılmıyor, sayaç yine +1 gidiyordu
/// (denetim #5 3-O1). Burada eklenen notlar açıkça tutulur; sayaç ile not
/// listesi birlikte değişir ve sayaç 0'ın altına inmez.
class KartSaglikIzi {
  /// Kart açılışında sunucuda olan notlar. Kart açıkken geçmişten silinen
  /// not sunucudan da hemen silindiği için buradan da çıkar (iptalde geri
  /// gelmesin).
  final List<Map<String, dynamic>> ilkNotlar;
  int ilkSayac;
  /// Bu kart oturumunda eklenen, henüz kaydedilmemiş notlar.
  final List<Map<String, dynamic>> eklenen = [];

  KartSaglikIzi(Ogrenci o)
      : ilkNotlar = o.saglikNotlari.map((e) => Map<String, dynamic>.from(e)).toList(),
        ilkSayac = o.saglikDurumu;

  /// Bir öğrencide tutulabilecek en fazla not: firestore.rules
  /// `listeSiniri(..., 'saglikNotlari', 50)` ile aynı olmalı; aşılırsa
  /// sunucu kartın TÜM kaydını reddeder.
  static bool dolu(Ogrenci o) => o.saglikNotlari.length >= Ogrenci.saglikNotuMaxAdet;

  /// Sayaç not sayısından büyükse (eski hatadan kalan yetim sayaç) "−"
  /// yalnız sayacı düşürür; yoksa not silinir (sayaç notla birlikte iner).
  static bool yetimSayac(Ogrenci o) => o.saglikDurumu > o.saglikNotlari.length;

  void ekle(Ogrenci o, Map<String, dynamic> not) {
    o.saglikNotlari.add(not);
    eklenen.add(not);
    o.saglikDurumu += 1;
  }

  void yetimSayaciDusur(Ogrenci o) {
    if (o.saglikDurumu > 0) o.saglikDurumu -= 1;
  }

  /// Notu siler. Dönen değer: not sunucuda mıydı, yani sunucudan da
  /// silinmeli mi (ve sayaç o yazmada düşmeli mi).
  ({bool sunucudan, bool sayaciAzalt}) sil(Ogrenci o, Map<String, dynamic> kayit) {
    o.saglikNotlari.remove(kayit);
    if (eklenen.remove(kayit)) {
      if (o.saglikDurumu > 0) o.saglikDurumu -= 1;
      return (sunucudan: false, sayaciAzalt: false);
    }
    final i = ilkNotlar.indexWhere(
        (n) => n['tarih'] == kayit['tarih'] && n['not'] == kayit['not']);
    if (i >= 0) ilkNotlar.removeAt(i);
    final azalt = o.saglikDurumu > 0;
    if (azalt) {
      o.saglikDurumu -= 1;
      if (ilkSayac > 0) ilkSayac -= 1;
    }
    return (sunucudan: true, sayaciAzalt: azalt);
  }

  void geriAl(Ogrenci o) {
    o.saglikDurumu = ilkSayac;
    o.saglikNotlari
      ..clear()
      ..addAll(ilkNotlar.map((e) => Map<String, dynamic>.from(e)));
  }
}
