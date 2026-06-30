import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static const String _adminUid = 'A1Xyb80fR7NQ6KuwBt6NUa5p2743';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String get uid => _auth.currentUser!.uid;
  bool get isAdmin => _auth.currentUser?.uid == _adminUid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: popup ile giriş
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      await _auth.signInWithPopup(googleProvider);
    } else {
      // Mobil/Desktop: google_sign_in paketi
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        clientId: '73438566042-j4s7hrbqavmf51a5m40o0535m9frqfnj.apps.googleusercontent.com',
      );

      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      final clientAuth = await account.authorizationClient.authorizeScopes(['email', 'profile']);
      final accessToken = clientAuth.accessToken;

      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken, accessToken: accessToken),
      );
    }
  }

  Future<void> signInWithApple() async {
    if (kIsWeb) {
      final appleProvider = OAuthProvider('apple.com');
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      await _auth.signInWithPopup(appleProvider);
    } else {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Firebase Auth hesabını siler. Firestore verileri ayrıca temizlenmeli.
  /// `requires-recent-login` fırlatabilir — çağıran taraf yakalayıp yeniden
  /// giriş akışına yönlendirmeli.
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
}
