import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ogrenci.dart';
import '../screens/skor_ekrani.dart';
import 'firestore_service.dart';

/// Yarım kalan maçın cihazda saklanması.
///
/// GÜVENLİK NOTU: Buraya öğrenci ADI veya NOTU yazılmaz — yalnızca öğrenci
/// id'si ve maça özgü alanlar (puan, takım, skor, süre). İsimler yüklerken
/// Firestore'dan tazelenir.
///
/// Nedeni: SharedPreferences web'de `localStorage`'dır ve aynı origin'de
/// çalışan her JS onu düz metin okuyabilir; Android'de ise cihaz yedeğine
/// çıkar. Ayrıca kayıt kullanıcı bazlı anahtarda tutulur ve çıkışta
/// silinir — yoksa okulda paylaşılan bir tablette sonraki öğretmen
/// öncekinin öğrencilerini görür.
class MacDurumu extends ChangeNotifier {
  static final MacDurumu _instance = MacDurumu._();
  factory MacDurumu() => _instance;
  MacDurumu._();

  static const String _anahtarOnEki = 'aktif_mac';

  /// v1.1.1 öncesi kullanılan, kullanıcıya göre ayrılmamış ve öğrenci
  /// adlarını düz metin tutan anahtar.
  static const String _eskiAnahtar = 'aktif_mac';

  static String? _aktifUid;

  static String? get _anahtar =>
      _aktifUid == null ? null : '${_anahtarOnEki}_$_aktifUid';

  List<TakimBilgi>? _takimlar;
  String? _sinifId;
  bool _duraklatildi = false;

  // Timer & skor durumu
  int kalanSaniye = 0;
  int toplamSaniye = 0;
  bool timerCalisiyor = false;
  bool timerBitti = false;

  /// Timer'ın duraklatıldığı (ekrandan çıkıldığı) zaman
  DateTime? _timerCikisZamani;

  List<TakimBilgi>? get takimlar => _takimlar;
  String? get sinifId => _sinifId;
  bool get aktif => _takimlar != null;
  bool get duraklatildi => _duraklatildi;

  void macBaslat(String sinifId, List<TakimBilgi> takimlar) {
    _sinifId = sinifId;
    _takimlar = takimlar;
    _duraklatildi = false;
    kalanSaniye = 0;
    toplamSaniye = 0;
    timerCalisiyor = false;
    timerBitti = false;
    _timerCikisZamani = null;
    kaydet();
    notifyListeners();
  }

  void duraklat() {
    _duraklatildi = true;
    notifyListeners();
  }

  void devamEt() {
    _duraklatildi = false;
    notifyListeners();
  }

  /// Skor ekranından çıkarken durumu kaydet
  void durumKaydet({
    required int kalanSn,
    required int toplamSn,
    required bool calisiyor,
    required bool bitti,
  }) {
    kalanSaniye = kalanSn;
    toplamSaniye = toplamSn;
    timerBitti = bitti;
    // Timer çalışıyorsa çıkış zamanını kaydet, geri dönünce farkı hesaplayalım
    if (calisiyor && !bitti) {
      timerCalisiyor = true;
      _timerCikisZamani = DateTime.now();
    } else {
      timerCalisiyor = false;
      _timerCikisZamani = null;
    }
    kaydet();
  }

  /// Skor ekranına dönerken geçen süreyi hesapla
  int kalanSaniyeHesapla() {
    if (_timerCikisZamani != null && timerCalisiyor) {
      final gecenSaniye = DateTime.now().difference(_timerCikisZamani!).inSeconds;
      final yeniKalan = kalanSaniye - gecenSaniye;
      kalanSaniye = yeniKalan > 0 ? yeniKalan : 0;
      if (kalanSaniye <= 0) {
        timerCalisiyor = false;
        timerBitti = true;
      }
      _timerCikisZamani = null;
    }
    return kalanSaniye;
  }

  void macBitir() {
    _bellegiSifirla();
    _temizle();
    notifyListeners();
  }

  void _bellegiSifirla() {
    _takimlar = null;
    _sinifId = null;
    _duraklatildi = false;
    kalanSaniye = 0;
    toplamSaniye = 0;
    timerCalisiyor = false;
    timerBitti = false;
    _timerCikisZamani = null;
  }

  // --- Yerel depolama ---

  /// Giriş yapan kullanıcıyı bildirir. `yukle()` bunu kendisi yapar;
  /// ayrıca çağırmak gerekmez.
  static void kullaniciAyarla(String uid) => _aktifUid = uid;

  Future<void> kaydet() async {
    final anahtar = _anahtar;
    if (_takimlar == null || anahtar == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'uid': _aktifUid,
      'sinifId': _sinifId,
      'toplamSaniye': toplamSaniye,
      'kalanSaniye': kalanSaniye,
      'timerCalisiyor': timerCalisiyor,
      'timerBitti': timerBitti,
      'cikisZamani': _timerCikisZamani?.millisecondsSinceEpoch,
      'takimlar': _takimlar!
          .map((t) => {
                'isim': t.isim,
                'renkAdi': t.renkAdi,
                'renk': t.renk.toARGB32(),
                'skor': t.skor,
                'kaptanId': t.kaptan?.id,
                // Öğrenci adı ve notu BİLEREK yazılmıyor — yüklerken
                // Firestore'dan tazeleniyor.
                'oyuncular': t.oyuncular
                    .map((o) => {
                          'id': o.id,
                          'puan': o.puan,
                          'isMale': o.isMale,
                          'buradaMi': o.buradaMi,
                          if (o.element != null) 'element': o.element,
                        })
                    .toList(),
              })
          .toList(),
    };
    await prefs.setString(anahtar, jsonEncode(data));
  }

  Future<void> _temizle() async {
    final prefs = await SharedPreferences.getInstance();
    final anahtar = _anahtar;
    if (anahtar != null) await prefs.remove(anahtar);
  }

  /// Çıkışta çağrılır: bellek + diskteki TÜM maç kayıtlarını siler.
  /// Eski sürümden kalan, kullanıcıya göre ayrılmamış kaydı da temizler.
  static Future<void> tamTemizlik([String? uid]) async {
    _instance._bellegiSifirla();
    try {
      final prefs = await SharedPreferences.getInstance();
      final silinecek = prefs
          .getKeys()
          .where((k) => k == _eskiAnahtar || k.startsWith('${_anahtarOnEki}_'))
          .toList();
      for (final k in silinecek) {
        await prefs.remove(k);
      }
    } catch (_) {
      // Depolama erişilemezse çıkışın kendisi engellenmemeli.
    }
    _aktifUid = null;
    _instance.notifyListeners();
  }

  /// Giriş sonrası yarım kalan maçı geri yükler.
  ///
  /// Öğrenci adları yerelde tutulmadığı için Firestore'dan tazelenir;
  /// silinmiş öğrenciler maç kadrosundan düşer.
  Future<bool> yukle(String uid) async {
    _aktifUid = uid;
    final prefs = await SharedPreferences.getInstance();

    var json = prefs.getString(_anahtar!);

    // v1.1.1 öncesi kayıt: içinde düz metin öğrenci adları var.
    // Maçı kaybettirmemek için id'lerinden geri kuruyoruz, ardından
    // eski anahtarı siliyoruz.
    if (json == null) {
      final eski = prefs.getString(_eskiAnahtar);
      if (eski != null) {
        json = eski;
        await prefs.remove(_eskiAnahtar);
      }
    }
    if (json == null) return false;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      // Başka bir hesaba ait kayıt: yükleme, sil.
      final kayitUid = data['uid'];
      if (kayitUid != null && kayitUid != uid) {
        await prefs.remove(_anahtar!);
        return false;
      }

      final sinifId = data['sinifId'] as String?;
      if (sinifId == null) {
        await _temizle();
        return false;
      }

      // Adları Firestore'dan getir.
      final ogrenciler = await FirestoreService(uid: uid).ogrencileriGetir(sinifId);
      final adaGore = {for (final o in ogrenciler) o.id: o};

      _sinifId = sinifId;
      toplamSaniye = data['toplamSaniye'] ?? 0;
      kalanSaniye = data['kalanSaniye'] ?? 0;
      timerCalisiyor = data['timerCalisiyor'] ?? false;
      timerBitti = data['timerBitti'] ?? false;
      if (data['cikisZamani'] != null) {
        _timerCikisZamani =
            DateTime.fromMillisecondsSinceEpoch(data['cikisZamani']);
      }

      final takimlarData = (data['takimlar'] as List).cast<Map<String, dynamic>>();
      _takimlar = takimlarData.map((t) {
        final oyuncularData =
            (t['oyuncular'] as List).cast<Map<String, dynamic>>();
        final oyuncular = oyuncularData
            .map((o) {
              final kayit = adaGore[o['id']];
              if (kayit == null) return null; // öğrenci silinmiş
              return Ogrenci(
                id: kayit.id,
                // Ad ve not yerelde tutulmuyor — Firestore'dan tazelendi.
                ad: kayit.ad,
                not: kayit.not,
                puan: (o['puan'] as num?)?.toInt() ?? kayit.puan,
                isMale: o['isMale'] as bool? ?? kayit.isMale,
                buradaMi: o['buradaMi'] as bool? ?? true,
                element: o['element'] as String? ?? kayit.element,
              );
            })
            .whereType<Ogrenci>()
            .toList();

        final kaptanId = t['kaptanId'] as String?;
        Ogrenci? kaptan;
        if (kaptanId != null) {
          kaptan = oyuncular.where((o) => o.id == kaptanId).firstOrNull;
        }

        return TakimBilgi(
          isim: t['isim'] as String? ?? '',
          renkAdi: t['renkAdi'] as String? ?? '',
          renk: Color((t['renk'] as num?)?.toInt() ?? 0xFF9E9E9E),
          oyuncular: oyuncular,
          kaptan: kaptan,
          skor: (t['skor'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      // Kadro tamamen boşaldıysa (sınıf silinmiş vb.) maçı kapat.
      if (_takimlar!.every((t) => t.oyuncular.isEmpty)) {
        macBitir();
        return false;
      }

      // Yeni biçimde ve doğru anahtarla tekrar yaz (eski kayıttan geldiyse).
      await kaydet();

      kalanSaniyeHesapla();
      notifyListeners();
      return true;
    } catch (_) {
      await _temizle();
      return false;
    }
  }
}
