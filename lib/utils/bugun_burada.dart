/// "Bu öğrenci BUGÜN burada mı?" sorusunun tek tanımı (denetim #5 Y1).
///
/// Eskiden listedeki "Yok" öğrenci belgesindeki tarihsiz `buradaMi`
/// bayrağından okunuyordu: dün yok yazılan öğrenci haftalarca takım
/// kurmaya, kuraya ve yarışmaya giremiyor, yoklama ise onu "geldi"
/// gösteriyordu. Artık tek doğruluk kaynağı BUGÜNÜN yoklama belgesi:
/// kaydı olmayan öğrenci geldi sayılır, belge başka güne aitse herkes
/// geldi. "Yok" bir güne aittir, gece yarısı kendiliğinden düşer.
///
/// `buradaMi` alanı yalnız App Store'daki eski sürümler için yazılmaya
/// devam ediyor; yeni istemci onu OKUMAZ (eski belgelerde kalmış
/// `buradaMi:false` göç gerektirmeden etkisiz kalır).
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/ogrenci.dart';

/// Yoklama belgesinin kimliği: ISO "2026-11-15" (sıralanabilir).
String gunAnahtari(DateTime t) =>
    '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// Bir yoklama kaydında öğrenci geldi mi? Kaydı yoksa geldi — Yoklama
/// ekranı da varsayılanı böyle kurar. Halka, başlık ve liste aynı kuralı
/// kullanır.
bool kayitGeldiMi(Map? kayitlar, String ogrenciId) {
  final r = kayitlar?[ogrenciId];
  return r is Map ? r['geldi'] != false : true;
}

/// [tarihId] günündeki yoklama belgesinden BUGÜN gelmeyenlerin kimlikleri.
/// Belge yoksa ya da bugüne ait değilse (dünkü belge, gece yarısını geçen
/// açık oturum) boş küme: herkes geldi.
Set<String> bugunGelmeyenler(String? tarihId, Map<String, dynamic>? yoklama, DateTime simdi) {
  if (yoklama == null || tarihId != gunAnahtari(simdi)) return const {};
  final kayitlar = yoklama['kayitlar'];
  if (kayitlar is! Map) return const {};
  return {
    for (final id in kayitlar.keys)
      if (id is String && !kayitGeldiMi(kayitlar, id)) id,
  };
}

/// Takım kurma, kura ve yarışmaya girecek öğrenciler.
List<Ogrenci> bugunGelenler(Iterable<Ogrenci> ogrenciler, Set<String> gelmeyenler) =>
    ogrenciler.where((o) => !gelmeyenler.contains(o.id)).toList();

/// Bir sonraki gece yarısına kalan süre (yerel saat).
Duration gunSonunaKalan(DateTime simdi) =>
    DateTime(simdi.year, simdi.month, simdi.day + 1).difference(simdi);

/// Bugünün anahtarı; gün değişince (gece yarısı zamanlayıcısı ya da
/// uygulama öne gelince) dinleyenleri uyarır. Gece yarısını geçen açık
/// oturumda dünkü "Yok"lar böylece ekrandan düşer.
class Bugun extends ValueNotifier<String> with WidgetsBindingObserver {
  Bugun._(this._saat) : super(gunAnahtari(_saat())) {
    WidgetsBinding.instance.addObserver(this);
    _kur();
  }

  static Bugun? _ornek;
  factory Bugun() => _ornek ??= Bugun._(DateTime.now);

  /// Testler için: saat enjekte edilir, gerçek zamanlayıcı yine kurulur.
  @visibleForTesting
  factory Bugun.test(DateTime Function() saat) => Bugun._(saat);

  final DateTime Function() _saat;
  Timer? _zamanlayici;

  DateTime get simdi => _saat();

  void _kur() {
    _zamanlayici?.cancel();
    // Bir saniye pay: zamanlayıcı erken uyanırsa gün henüz değişmemiş olur.
    _zamanlayici = Timer(gunSonunaKalan(_saat()) + const Duration(seconds: 1), () {
      kontrolEt();
      _kur();
    });
  }

  /// Gün değiştiyse değeri güncelleyip dinleyenleri uyarır.
  void kontrolEt() {
    final yeni = gunAnahtari(_saat());
    if (yeni != value) value = yeni;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Arka planda zamanlayıcı durabilir (iOS); öne gelince gün yeniden
    // hesaplanır, zamanlayıcı da yeniden kurulur.
    if (state == AppLifecycleState.resumed) {
      kontrolEt();
      _kur();
    }
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (identical(_ornek, this)) _ornek = null;
    super.dispose();
  }
}
