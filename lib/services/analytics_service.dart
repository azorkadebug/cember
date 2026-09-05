import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  static Future<void> girisYapildi(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  static Future<void> sinifOlusturuldu() async {
    await _analytics.logEvent(name: 'sinif_olusturuldu');
  }

  static Future<void> macBasladi({required int takimSayisi, required int oyuncuSayisi}) async {
    await _analytics.logEvent(name: 'mac_basladi', parameters: {
      'takim_sayisi': takimSayisi,
      'oyuncu_sayisi': oyuncuSayisi,
    });
  }

  static Future<void> takimKuruldu({required int takimSayisi, required int oyuncuSayisi}) async {
    await _analytics.logEvent(name: 'takim_kuruldu', parameters: {
      'takim_sayisi': takimSayisi,
      'oyuncu_sayisi': oyuncuSayisi,
    });
  }

  static Future<void> profilTamamlandi({String? sehir, String? brans}) async {
    await _analytics.logEvent(name: 'profil_tamamlandi', parameters: {
      if (sehir != null && sehir.isNotEmpty) 'sehir': sehir,
      'brans': ?brans,
    });
  }

  static Future<void> ogrenciEklendi({required int toplamOgrenci}) async {
    await _analytics.logEvent(name: 'ogrenci_eklendi', parameters: {
      'toplam_ogrenci': toplamOgrenci,
    });
  }

  static Future<void> setUserId(String? uid) async {
    await _analytics.setUserId(id: uid);
  }

  /// Hesap silinince Analytics'teki kullanıcı kimliğine bağlı veri de
  /// sıfırlanır (denetim #4 O12).
  static Future<void> sifirla() async {
    try { await _analytics.resetAnalyticsData(); } catch (_) {}
  }
}
