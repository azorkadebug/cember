/// Çıkıştan önce çevrimdışı kuyruktaki yazmaların gitmesini bekleme mantığı
/// (arayüzden ayrık, test edilir).
library;

import 'dart:async';

/// `bekle` (Firestore `waitForPendingWrites`) [sure] içinde biterse true:
/// bekleyen kayıt kalmadı, çıkış güvenli. Süre dolarsa false: kayıtlar hâlâ
/// kuyrukta, çıkış önbelleği temizleyince silinecekler. `bekle` hata
/// verirse (istemci zaten kapalı) bekleyecek bir şey yok sayılır, true.
Future<bool> bekleyenYazmalarGitti(
  Future<void> Function() bekle, {
  Duration sure = const Duration(seconds: 4),
}) async {
  try {
    await bekle().timeout(sure);
    return true;
  } on TimeoutException {
    return false;
  } catch (_) {
    return true;
  }
}
