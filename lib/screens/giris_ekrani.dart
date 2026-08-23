import 'dart:io' show Platform;
import 'dart:math' as math;
import '../tema.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> with TickerProviderStateMixin {
  /// pubspec.yaml'daki sürüm. `--dart-define=APP_VERSION=...` ile
  /// derleme sırasında geçilebilir; verilmezse buradaki değer kullanılır.
  static const String _surum =
      String.fromEnvironment('APP_VERSION', defaultValue: 'v1.1.1');

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscurePass = true;
  bool _kayitModu = false;
  late AnimationController _fadeCtrl;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _slideCtrl.forward());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleGiris() async {
    setState(() => _loading = true);
    try {
      await _authService.signInWithGoogle();
      unawaited(AnalyticsService.girisYapildi('google'));
    } catch (e) {
      // Ham hata metni gösterilmiyor: iç detay sızdırıyor ve Firebase'in
      // İngilizce mesajları kullanıcı numaralandırmaya izin veriyor.
      if (mounted && !AuthService.iptalMi(e)) {
        _hataGoster(AuthService.hataMesaji(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleGiris() async {
    setState(() => _loading = true);
    try {
      await _authService.signInWithApple();
      unawaited(AnalyticsService.girisYapildi('apple'));
    } catch (e) {
      if (mounted && !AuthService.iptalMi(e)) {
        _hataGoster(AuthService.hataMesaji(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Apple Sign-In sadece iOS ve macOS'ta gösterilir.
  /// - Android: Apple hesap altyapısı yok
  /// - Web: Firebase Apple provider'ı tek Services ID kabul ediyor, biz iOS
  ///   Bundle ID'sini set ettik (App Store şart). Web OAuth ayrı Service ID
  ///   gerektirdiği için web'de Apple Sign-In düğmesi gizli — Google + e-posta
  ///   web kullanıcıları için yeterli. (Future: Cloud Functions ile çözülebilir.)
  bool get _appleSignInDestekleniyor =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  Future<void> _emailGirisKayit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _hataGoster("Lütfen e-posta ve şifre girin.");
      return;
    }
    setState(() => _loading = true);
    try {
      if (_kayitModu) {
        await _authService.signUpWithEmail(_emailCtrl.text, _passCtrl.text);
        unawaited(AnalyticsService.girisYapildi('email_kayit'));
        if (mounted) {
          _bilgiGoster(
              "Hesabın oluşturuldu. E-posta adresine doğrulama bağlantısı gönderdik.");
        }
      } else {
        await _authService.signInWithEmail(_emailCtrl.text, _passCtrl.text);
        unawaited(AnalyticsService.girisYapildi('email'));
      }
    } catch (e) {
      if (mounted) _hataGoster(AuthService.hataMesaji(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sifremiUnuttum() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _hataGoster("Önce e-posta adresini yaz, sonra bağlantıya dokun.");
      return;
    }
    setState(() => _loading = true);
    await _authService.sifreSifirla(email);
    if (!mounted) return;
    setState(() => _loading = false);
    // Adresin kayıtlı olup olmadığına bakılmaksızın AYNI mesaj gösteriliyor —
    // aksi hâlde hangi e-postaların sistemde olduğu öğrenilebilir.
    _bilgiGoster(
        "Bu adres kayıtlıysa şifre sıfırlama bağlantısı gönderildi. Gelen kutunu kontrol et.");
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _bilgiGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: AppTema.ana,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Üst kısım: Charcoal gradient + logo
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTema.anaKoyu, AppTema.ana, AppTema.anaAcik],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 24, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(18),
                          child: _CemberLogo(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("ÇEMBER",
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6)),
                      const SizedBox(height: 6),
                      Text("Sınıf Yönetimi Asistanı",
                          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13, letterSpacing: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Alt kısım: Beyaz form
          Expanded(
            flex: 7,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _slideCtrl,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                      // Tab: Giriş / Kayıt
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _tabBtn("Giriş Yap", !_kayitModu, () => setState(() => _kayitModu = false)),
                            _tabBtn("Kayıt Ol", _kayitModu, () => setState(() => _kayitModu = true)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Email
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        maxLength: 254,
                        buildCounter: _sayacGizle,
                        decoration: _inputDeco("E-Posta", Icons.email_outlined),
                      ),
                      const SizedBox(height: 14),
                      // Password
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        maxLength: 128,
                        buildCounter: _sayacGizle,
                        autofillHints: _kayitModu
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        decoration: _inputDeco("Şifre", Icons.lock_outline_rounded).copyWith(
                          helperText: _kayitModu
                              ? "En az 10 karakter, harf ve rakam içermeli"
                              : null,
                          helperStyle: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11.5),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.grey.shade400, size: 20),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                      ),
                      if (!_kayitModu)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading ? null : _sifremiUnuttum,
                            style: TextButton.styleFrom(
                              foregroundColor: AppTema.ana,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text("Şifremi unuttum",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      const SizedBox(height: 18),
                      // Submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTema.ana,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                          onPressed: _loading ? null : _emailGirisKayit,
                          child: _loading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Text(_kayitModu ? "Hesap Oluştur" : "Hesabıma Gir",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text("veya devam et", style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ]),
                      const SizedBox(height: 24),

                      // Social Buttons — Apple HIG: Apple butonu Google'dan az
                      // göründüğünden değil, en az eşit prominence olmalı.
                      if (_appleSignInDestekleniyor) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: SignInWithAppleButton(
                            onPressed: _loading ? () {} : _appleGiris,
                            style: SignInWithAppleButtonStyle.black,
                            borderRadius: BorderRadius.circular(14),
                            text: 'Apple ile Giriş Yap',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: _socialBtn(Icons.g_mobiledata, "Google ile Giriş", Colors.red, _googleGiris),
                      ),
                      const SizedBox(height: 24),
                      // Elle yazılan sürüm numarası güncellenmeyi unutuyordu
                      // (pubspec 1.1.0 iken ekranda hâlâ v1.0.0 yazıyordu).
                      Text(_surum, style: TextStyle(color: Colors.grey.shade300, fontSize: 11)),
                    ],
                  ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTema.ana : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade500,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              )),
        ),
      ),
    );
  }

  /// maxLength sayacını gizler — sınır var ama ekranda "0/254" görünmesin.
  static Widget? _sayacGizle(BuildContext context,
          {required int currentLength,
          required bool isFocused,
          required int? maxLength}) =>
      null;

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: AppTema.anaAcik, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTema.ana, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _socialBtn(IconData icon, String label, Color iconColor, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withAlpha(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CemberLogo extends StatelessWidget {
  const _CemberLogo();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CemberLogoPainter(), size: const Size.square(74));
  }
}

class _CemberLogoPainter extends CustomPainter {
  static const _palette = [
    Color(0xFFFF6B35),
    Color(0xFF00C896),
    Color(0xFF4A90E2),
    Color(0xFFE94B6A),
    Color(0xFFF5C544),
    Color(0xFF9B59B6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;

    final ring = Paint()
      ..color = AppTema.ana
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, ring);

    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * math.pi - math.pi / 2;
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(pos, 6, Paint()..color = _palette[i]);
    }

    canvas.drawCircle(center, 5, Paint()..color = AppTema.anaKoyu);
  }

  @override
  bool shouldRepaint(covariant _CemberLogoPainter oldDelegate) => false;
}
