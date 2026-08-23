import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

/// ESKİ kayıtları okumak için tutulan geriye dönük uyumluluk katmanı.
///
/// v1.1.1'e kadar öğrenci adı ve notu AES-CBC ile şifrelenip Firestore'a
/// öyle yazılıyordu. Bu koruma sağlamıyordu: AES anahtarı kullanıcının
/// Firebase UID'sinden türetiliyordu ve aynı UID her sınıf dokümanında
/// `ownerId` alanında düz metin duruyor — yani şifreli kaydı okuyabilen
/// herkes anahtarı da aynı sorguda elde ediyordu. IV de sabitti (UID'nin
/// tersi), dolayısıyla aynı isim her zaman aynı şifreli metni üretiyordu.
///
/// Gerçek koruma Firestore güvenlik kurallarından (sahiplik kontrolü)
/// geliyor. Şifreleme katmanı ayrıca sessizce zarar veriyordu: sunucu
/// tarafı `where('ad', ...)` sorguları şifreli metinle eşleşmediği için
/// toplu eklemedeki mükerrer kontrolü çalışmıyordu.
///
/// Bu yüzden YENİ yazmalar düz metin (`sifrelendi: false`). Bu sınıf
/// yalnızca `sifrelendi: true` bayrağı taşıyan eski dokümanları çözmek
/// için kullanılıyor; okunan kayıt bir sonraki yazmada düz metne göç eder.
/// Tüm kayıtlar göç ettiğinde bu dosya ve `encrypt` bağımlılığı silinebilir.
class SifrelemeService {
  static SifrelemeService? _instance;
  late final Key _key;
  late final IV _iv;

  SifrelemeService._();

  /// Eski kayıtları çözmek için UID'den anahtar/IV türetir.
  /// Giriş yapıldığında bir kez çağrılır.
  static void initialize(String uid) {
    _instance = SifrelemeService._();
    final keyBytes =
        Uint8List.fromList(utf8.encode(uid.padRight(32, '#').substring(0, 32)));
    _instance!._key = Key(keyBytes);
    final ivBytes = Uint8List.fromList(utf8.encode(
        uid.split('').reversed.join().padRight(16, '*').substring(0, 16)));
    _instance!._iv = IV(ivBytes);
  }

  /// Çıkışta çağrılır — eski kullanıcının anahtarı bellekte kalmasın.
  static void temizle() {
    _instance = null;
  }

  /// Oturum yoksa null döner; çağıran taraf düz metin varsayar.
  static SifrelemeService? get instanceOrNull => _instance;

  static SifrelemeService get instance {
    if (_instance == null) {
      throw StateError('SifrelemeService henüz initialize edilmedi');
    }
    return _instance!;
  }

  /// Eski (`sifrelendi: true`) bir alanı çözer.
  ///
  /// Çözülemezse metni olduğu gibi döndürür: kayıt zaten düz metin olabilir
  /// ya da başka bir hesapla şifrelenmiş olabilir. İkinci durumda öğretmen
  /// ekranda base64 görür — sessizce boş bırakmaktansa görünür olması iyi,
  /// çünkü kaydı düzeltebilir.
  String coz(String sifreliMetin) {
    if (sifreliMetin.isEmpty) return '';
    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      return encrypter.decrypt64(sifreliMetin, iv: _iv);
    } catch (_) {
      return sifreliMetin;
    }
  }

  /// Bir Firestore dokümanındaki alanı, `sifrelendi` bayrağına göre çözer.
  /// Servis initialize edilmemişse düz metin varsayar.
  static String alanCoz(Map<String, dynamic> map, String alan) {
    final deger = (map[alan] ?? '').toString();
    if (map['sifrelendi'] != true) return deger;
    return _instance?.coz(deger) ?? deger;
  }
}
