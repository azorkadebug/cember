import 'package:cloud_firestore/cloud_firestore.dart';

/// Eğitim yılı ("2026-2027") hesapları.
///
/// Sınıflar eskiden yıldan bağımsızdı: geçen yılın 6A'sı ile bu yılın 7E'si
/// aynı listede birikiyor, aynı öğrencinin kopyaları çoğalıyordu (Sabri,
/// 2026-10-02). Her sınıf artık bir eğitim yılına ait; ana listede yalnız
/// bu yılınkiler görünür, eskiler "Geçmiş Yıllar"a iner.
class EgitimYili {
  const EgitimYili._();

  /// Yeni yıl Ağustos'ta başlar: öğretmenler sınıflarını okul açılmadan
  /// önceki haftalarda kuruyor.
  static const int baslangicAyi = 8;

  static final RegExp _bicim = RegExp(r'^(\d{4})-(\d{4})$');

  static String tarihten(DateTime t) {
    final y = t.month >= baslangicAyi ? t.year : t.year - 1;
    return '$y-${y + 1}';
  }

  static String get simdiki => tarihten(DateTime.now());

  static bool gecerli(String? s) {
    if (s == null) return false;
    final m = _bicim.firstMatch(s);
    return m != null && int.parse(m.group(2)!) == int.parse(m.group(1)!) + 1;
  }

  static String onceki(String yil) {
    final bas = int.parse(yil.substring(0, 4)) - 1;
    return '$bas-${bas + 1}';
  }

  /// Sınıf dokümanının eğitim yılı. Alan yoksa (bu özellikten önce açılan
  /// sınıflar) oluşturulma tarihinden çıkarılır. Tarih de yoksa — eski
  /// kayıt ya da sunucu zaman damgası henüz yazılmamış yeni sınıf — bu
  /// yıla sayılır: bir sınıfı yanlışlıkla arşive saklamaktansa ana
  /// listede göstermek daha güvenli; öğretmen elle taşıyabilir.
  static String sinifin(Map<String, dynamic>? data) {
    final alan = data?['egitimYili'];
    if (alan is String && gecerli(alan)) return alan;
    final created = data?['created'];
    if (created is Timestamp) return tarihten(created.toDate());
    return simdiki;
  }
}
