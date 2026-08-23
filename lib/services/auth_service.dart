import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'demo_modu.dart';
import 'mac_durumu.dart';
import 'sifreleme_service.dart';

class AuthService {
  /// Admin yetkisi. Kalıcı çözüm Firebase custom claim (`token.admin`);
  /// UID sabiti claim atanana kadar geriye dönük uyumluluk için duruyor.
  static const String _adminUid = 'A1Xyb80fR7NQ6KuwBt6NUa5p2743';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Oturum yoksa null. Force-unwrap yapılmıyor: hesap silme ve çıkış
  /// sırasında `authStateChanges` null yayınlarken hâlâ ağaçta olan
  /// widget'lar bu getter'ı çağırabiliyor.
  String? get uidOrNull => _auth.currentUser?.uid;

  String get uid {
    final u = _auth.currentUser?.uid;
    if (u == null) throw StateError('Oturum açık değil');
    return u;
  }

  bool get isAdmin => _auth.currentUser?.uid == _adminUid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Custom claim tabanlı admin kontrolü — claim atandığında UID sabiti
  /// kaldırılabilir. Token önbellekten okunur, ağ isteği yapmaz.
  Future<bool> adminMi() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.uid == _adminUid) return true;
    try {
      final token = await user.getIdTokenResult();
      return token.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  // --- E-posta / şifre ---

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Şifre kuralı: en az 10 karakter, harf ve rakam.
  /// İstemci kontrolü atlatılabilir (Auth REST API'sine doğrudan istek
  /// atılabilir), bu yüzden Firebase Console → Authentication → Settings →
  /// Password policy ile sunucu tarafı da açılmalı.
  static String? sifreHatasi(String sifre) {
    if (sifre.length < 10) return 'Şifre en az 10 karakter olmalı.';
    if (!RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(sifre)) {
      return 'Şifre en az bir harf içermeli.';
    }
    if (!RegExp(r'[0-9]').hasMatch(sifre)) {
      return 'Şifre en az bir rakam içermeli.';
    }
    return null;
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final e = email.trim();
    if (!_emailRegex.hasMatch(e)) {
      throw FirebaseAuthException(code: 'invalid-email');
    }
    final hata = sifreHatasi(password);
    if (hata != null) {
      throw FirebaseAuthException(code: 'weak-password', message: hata);
    }
    final cred =
        await _auth.createUserWithEmailAndPassword(email: e, password: password);
    // Doğrulama e-postası gönderilemezse kayıt yine de geçerli — engelleme.
    try {
      await cred.user?.sendEmailVerification();
    } catch (_) {}
  }

  /// Şifre sıfırlama e-postası gönderir.
  ///
  /// Hata bilerek yutuluyor: `user-not-found` fırlatmak, bir e-postanın
  /// sistemde kayıtlı olup olmadığını doğrulamayı sağlar (kullanıcı
  /// numaralandırma). Çağıran taraf her durumda aynı mesajı göstermeli.
  Future<void> sifreSifirla(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (_) {
    } catch (_) {}
  }

  // --- Google ---

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: popup ile giriş
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      await _auth.signInWithPopup(googleProvider);
    } else {
      // Mobil/Desktop: google_sign_in paketi
      // iOS: clientId (iOS OAuth istemcisi) yeterli — canlıda böyle çalışıyor.
      // Android: Firebase'in kabul edeceği idToken almak için serverClientId
      // (web OAuth istemcisi) ŞART; ayrıca SHA-1'in Firebase'e kayıtlı olması gerek.
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: isIOS
            ? '73438566042-j4s7hrbqavmf51a5m40o0535m9frqfnj.apps.googleusercontent.com'
            : null,
        serverClientId: isIOS
            ? null
            : '73438566042-vh7qepftjj2ot3m3s4b55c3s22u8m4kv.apps.googleusercontent.com',
      );

      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      final clientAuth =
          await account.authorizationClient.authorizeScopes(['email', 'profile']);
      final accessToken = clientAuth.accessToken;

      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken, accessToken: accessToken),
      );
    }
  }

  // --- Apple ---

  /// Kriptografik olarak güvenli rastgele nonce. `Random()` DEĞİL —
  /// tahmin edilebilir nonce replay korumasını değersiz kılar.
  static String _rastgeleNonce([int uzunluk = 32]) {
    const karakterler =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final rnd = Random.secure();
    return List.generate(
        uzunluk, (_) => karakterler[rnd.nextInt(karakterler.length)]).join();
  }

  static String _sha256(String girdi) =>
      sha256.convert(utf8.encode(girdi)).toString();

  Future<void> signInWithApple() async {
    if (kIsWeb) {
      final appleProvider = OAuthProvider('apple.com');
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      await _auth.signInWithPopup(appleProvider);
    } else {
      // Nonce, Apple'ın döndürdüğü kimlik token'ını BU giriş denemesine
      // bağlar. Olmadığında başka bir oturumdan yakalanmış geçerli bir
      // token enjekte edilerek o hesaba girilebilir (replay).
      // Apple'a hash'i, Firebase'e ham hâli gider.
      final rawNonce = _rastgeleNonce();
      final hashedNonce = _sha256(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName
        ],
        nonce: hashedNonce,
      );
      // accessToken geçilmiyor: `authorizationCode` bir access token değil,
      // tek kullanımlık yetkilendirme kodudur ve Firebase bunu Apple için
      // kullanmaz. Token iptali gerekirse ayrıca sunucuya gönderilmeli.
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple yalnızca İLK sign-in'de fullName/email döndürür. Firebase
      // displayName'i otomatik doldurmuyor — biz manuel yapmazsak profil
      // formunda "Ad Soyad" boş kalır ve kullanıcıdan tekrar isteriz.
      // Apple Guideline 4 Design: zaten verilen bilgileri yeniden istemek yasak.
      final ad = [appleCredential.givenName, appleCredential.familyName]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .join(' ');
      if (ad.isNotEmpty && userCredential.user?.displayName == null) {
        await userCredential.user?.updateDisplayName(ad);
        await userCredential.user?.reload();
      }
    }
  }

  // --- Oturum ---

  /// Çıkış. Firebase oturumunu kapatmak YETMEZ: paylaşılan bir cihazda
  /// (okul tableti, ortak bilgisayar) sonraki öğretmen öncekinin verisini
  /// görebilir. Yerel durumun tamamı burada temizleniyor.
  Future<void> signOut() async {
    // Google oturumu kapatılmazsa cihazda hesap seçili kalır ve bir sonraki
    // "Google ile Giriş" hesap seçici göstermeden aynı hesaba geri girer.
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    final eskiUid = _auth.currentUser?.uid;
    await MacDurumu.tamTemizlik(eskiUid);
    DemoModu.aktif = false;
    DemoModu.sifirla();
    SifrelemeService.temizle();

    await _auth.signOut();

    // Firestore'un disk önbelleği çıkıştan sonra da cihazda kalır.
    // terminate() + clearPersistence() sırası önemli; hata olursa yutuluyor
    // çünkü çıkışın kendisi başarılı olmalı.
    try {
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.clearPersistence();
    } catch (_) {}
  }

  /// Hassas işlemler (hesap silme) öncesi oturumu tazeler.
  ///
  /// Firebase, son girişin üzerinden ~5 dakika geçmişse `user.delete()` için
  /// `requires-recent-login` fırlatır. Kullanıcı uygulamayı açıp profile
  /// gidip onay diyaloglarını geçtiğinde oturum neredeyse her zaman eskidir,
  /// yani bu istisna değil normal durumdur.
  Future<void> yenidenDogrula() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
          code: 'no-current-user', message: 'Oturum açık değil.');
    }
    final eskiUid = user.uid;
    final saglayici = user.providerData.isNotEmpty
        ? user.providerData.first.providerId
        : 'password';

    switch (saglayici) {
      case 'google.com':
        await signInWithGoogle();
        break;
      case 'apple.com':
        await signInWithApple();
        break;
      default:
        // E-posta/şifre: çağıran taraf şifreyi sorup
        // yenidenDogrulaSifreIle() çağırmalı.
        throw FirebaseAuthException(
          code: 'reauth-password-required',
          message: 'Devam etmek için şifreni girmen gerekiyor.',
        );
    }

    // KRİTİK KONTROL: sağlayıcı hesap seçici gösterdiğinde kullanıcı BAŞKA
    // bir hesap seçmiş olabilir. Bunu yakalamazsak, ardından çalışacak
    // silme işlemi yanlış hesabın verisini siler.
    if (_auth.currentUser?.uid != eskiUid) {
      throw FirebaseAuthException(
        code: 'reauth-farkli-hesap',
        message: 'Farklı bir hesapla giriş yapıldı. İşlem iptal edildi.',
      );
    }
  }

  /// E-posta/şifre hesapları için yeniden kimlik doğrulama.
  Future<void> yenidenDogrulaSifreIle(String sifre) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
          code: 'no-current-user', message: 'Oturum açık değil.');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: sifre),
    );
  }

  /// Firebase Auth hesabını siler.
  ///
  /// ÇAĞRI SIRASI ÖNEMLİ: bu metot Firestore verisi silinmeden ÖNCE
  /// denenmelidir. Tersi sırada `requires-recent-login` alındığında
  /// kullanıcının verisi çoktan silinmiş, hesabı ise duruyor olur.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Oturum açık değil.',
      );
    }
    await user.delete();
  }

  // --- Hata çevirisi ---

  /// Ham Firebase hatalarını kullanıcıya gösterilebilir Türkçe mesaja çevirir.
  ///
  /// `user-not-found` ve `wrong-password` bilerek AYNI mesajı döndürür:
  /// ayrı mesajlar bir e-postanın sistemde kayıtlı olup olmadığını
  /// doğrulamayı sağlar (kullanıcı numaralandırma) ve hedefli oltalamanın
  /// ilk adımıdır. Ham hata metni asla yüzeye çıkmamalı.
  static String hataMesaji(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Geçerli bir e-posta adresi gir.';
        case 'email-already-in-use':
          return 'Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.';
        case 'weak-password':
          return e.message ?? 'Şifre çok zayıf. En az 10 karakter kullan.';
        case 'too-many-requests':
          return 'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.';
        case 'network-request-failed':
          return 'İnternet bağlantısı kurulamadı.';
        case 'requires-recent-login':
          return 'Güvenlik için tekrar giriş yapman gerekiyor.';
        case 'reauth-password-required':
          return e.message ?? 'Devam etmek için şifreni gir.';
        case 'reauth-farkli-hesap':
          return e.message ??
              'Farklı bir hesapla giriş yapıldı. İşlem iptal edildi.';
        case 'user-disabled':
          return 'Bu hesap devre dışı bırakılmış.';
        case 'operation-not-allowed':
          return 'Bu giriş yöntemi şu anda kullanılamıyor.';
        case 'canceled':
        case 'web-context-canceled':
          return 'Giriş iptal edildi.';
        default:
          // user-not-found / wrong-password / invalid-credential dahil
          return 'E-posta veya şifre hatalı.';
      }
    }
    return 'İşlem tamamlanamadı. Lütfen tekrar dene.';
  }

  /// Kullanıcının giriş akışını kendi iptal etmesi hata değil — mesaj gösterme.
  static bool iptalMi(Object e) {
    if (e is SignInWithAppleAuthorizationException) {
      return e.code == AuthorizationErrorCode.canceled;
    }
    if (e is GoogleSignInException) {
      return e.code == GoogleSignInExceptionCode.canceled;
    }
    if (e is FirebaseAuthException) {
      return e.code == 'canceled' || e.code == 'web-context-canceled';
    }
    return false;
  }
}
