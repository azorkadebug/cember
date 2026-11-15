import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Telefonun kendisinin çalacağı bir alarm: maç süresi ya da oyuncu molası.
@immutable
class PlanliAlarm {
  /// Uygulama içi kimlik: 'sure' ya da 'mola_' + oyuncu kimliği.
  final String id;
  final DateTime zaman;
  final String baslik;
  final String govde;
  const PlanliAlarm({required this.id, required this.zaman, required this.baslik, required this.govde});

  Map<String, Object> toMap() => {
        'id': id,
        'zaman': zaman.millisecondsSinceEpoch,
        'baslik': baslik,
        'govde': govde,
      };

  @override
  bool operator ==(Object other) =>
      other is PlanliAlarm &&
      other.id == id &&
      other.zaman.millisecondsSinceEpoch == zaman.millisecondsSinceEpoch &&
      other.baslik == baslik &&
      other.govde == govde;

  @override
  int get hashCode => Object.hash(id, zaman.millisecondsSinceEpoch, baslik, govde);
}

/// Alarmı telefon hangi yolla kurdu.
enum AlarmYolu {
  /// iOS 26+ AlarmKit: sessiz modu ve Odak'ı deler, Saat alarmı gibi çalar.
  alarmKit,
  /// Zamana duyarlı yerel bildirim (iOS 16–25 ya da AlarmKit izni yoksa).
  bildirim,
  /// Kurulamadı (web, Android, izin yok): yalnız uygulama içi uyarı.
  yok,
}

/// Mola ve süre bitişini uygulama arka plandayken / telefon kilitliyken de
/// duyurmak için iOS'a "şu anda çal" alarmları kurar.
///
/// Tek giriş noktası [esitle]: istenen alarmların TAM listesi verilir; yerel
/// taraf listede olmayanı iptal eder, eksik olanı kurar. Böylece duraklat,
/// sıfırla, mola iptali, maç bitişi ve çıkış ayrı ayrı iptal çağrısı
/// gerektirmez; uygulama yeniden açılınca kalan eski alarmlar da temizlenir.
///
/// MAHREMİYET: bildirim kilit ekranında görünür, öğrencilerin önünde
/// açılabilir. Bu yüzden metne öğrenci adı YAZILMAZ; yalnız takım rengi.
class AlarmServisi {
  AlarmServisi._();

  static const MethodChannel _kanal = MethodChannel('cember/alarm');

  /// Yerel tarafa gönderen işlev; testte sahtesi verilir. null dönerse
  /// platform desteklemiyor demektir.
  @visibleForTesting
  static Future<String?> Function(List<Map<String, Object>> alarmlar) gonder = _varsayilanGonder;

  /// Yalnız iOS uygulamasında yerel alarm var; web ve Android'de uygulama
  /// içi uyarı yeterli (Android mağazada yok).
  @visibleForTesting
  static bool Function() destekleniyor =
      () => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static List<PlanliAlarm> _sonGonderilen = const [];
  static AlarmYolu _yol = AlarmYolu.yok;
  static Future<void> _sira = Future.value();

  /// Son kurulumda kullanılan yol. AlarmKit ise uygulama içi düdük
  /// çalınmaz (telefon zaten çalıyor, iki ses üst üste binmesin).
  static AlarmYolu get yol => _yol;

  static Future<String?> _varsayilanGonder(List<Map<String, Object>> alarmlar) =>
      _kanal.invokeMethod<String>('esitle', {'alarmlar': alarmlar});

  /// İstenen alarm listesini telefona bildirir. Liste son gönderilenle
  /// aynıysa bir şey yapmaz. Çağrılar sırayla gider; hata uygulamayı
  /// durdurmaz (alarm kurulamazsa uygulama içi uyarı yine çalışır).
  static Future<void> esitle(List<PlanliAlarm> istenen) {
    if (!destekleniyor()) return Future.value();
    // Geçmiş zamanlı olanları yerel taraf atlar (saat burada değil orada).
    final liste = [...istenen]..sort((a, b) => a.id.compareTo(b.id));
    if (listEquals(liste, _sonGonderilen)) return _sira;
    _sonGonderilen = liste;
    _sira = _sira.then((_) async {
      try {
        final sonuc = await gonder(liste.map((a) => a.toMap()).toList());
        _yol = switch (sonuc) {
          'alarmkit' => AlarmYolu.alarmKit,
          'bildirim' => AlarmYolu.bildirim,
          _ => liste.isEmpty ? _yol : AlarmYolu.yok,
        };
      } catch (e) {
        debugPrint('AlarmServisi: $e');
        _sonGonderilen = const [];
        if (liste.isNotEmpty) _yol = AlarmYolu.yok;
      }
    });
    return _sira;
  }

  @visibleForTesting
  static void sifirla() {
    _sonGonderilen = const [];
    _yol = AlarmYolu.yok;
    _sira = Future.value();
    gonder = _varsayilanGonder;
    destekleniyor = () => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }
}
