// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Web'de çıkış sonrası: Firestore önbelleği temizlendikten sonra
/// sonlandırılmış istemciyi yeniden kullanmamak için sayfa yenilenir.
void sayfayiYenile() => html.window.location.reload();
