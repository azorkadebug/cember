import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class SifrelemeService {
  static SifrelemeService? _instance;
  late final Key _key;
  late final IV _iv;

  SifrelemeService._();

  /// UID'den 32-byte AES anahtarı ve 16-byte IV türetir
  static void initialize(String uid) {
    _instance = SifrelemeService._();
    // UID'den sabit 32 byte key türet (SHA-256 benzeri padding)
    final keyBytes = Uint8List.fromList(utf8.encode(uid.padRight(32, '#').substring(0, 32)));
    _instance!._key = Key(keyBytes);
    // UID'nin tersi + padding ile 16 byte IV türet
    final ivBytes = Uint8List.fromList(utf8.encode(uid.split('').reversed.join().padRight(16, '*').substring(0, 16)));
    _instance!._iv = IV(ivBytes);
  }

  static SifrelemeService get instance {
    if (_instance == null) throw StateError('SifrelemeService henüz initialize edilmedi');
    return _instance!;
  }

  String sifrele(String metin) {
    if (metin.isEmpty) return '';
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    return encrypter.encrypt(metin, iv: _iv).base64;
  }

  String coz(String sifreliMetin) {
    if (sifreliMetin.isEmpty) return '';
    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      return encrypter.decrypt64(sifreliMetin, iv: _iv);
    } catch (_) {
      // Şifrelenmemiş (eski) veri — olduğu gibi döndür
      return sifreliMetin;
    }
  }

  /// Metnin şifreli olup olmadığını kontrol eder
  bool sifrelimi(String metin) {
    if (metin.isEmpty) return false;
    try {
      final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
      encrypter.decrypt64(metin, iv: _iv);
      return true;
    } catch (_) {
      return false;
    }
  }
}
