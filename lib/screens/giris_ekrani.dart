import 'dart:math' as math;
import '../tema.dart';
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> with TickerProviderStateMixin {
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
      AnalyticsService.girisYapildi('google');
    } catch (e) {
      if (mounted) _hataGoster("Google Hatası: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _emailGirisKayit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _hataGoster("Lütfen e-posta ve şifre girin.");
      return;
    }
    setState(() => _loading = true);
    try {
      if (_kayitModu) {
        await _authService.signUpWithEmail(_emailCtrl.text, _passCtrl.text);
        AnalyticsService.girisYapildi('email_kayit');
      } else {
        await _authService.signInWithEmail(_emailCtrl.text, _passCtrl.text);
        AnalyticsService.girisYapildi('email');
      }
    } catch (e) {
      if (mounted) _hataGoster(e.toString().split('] ').last);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                        decoration: _inputDeco("E-Posta", Icons.email_outlined),
                      ),
                      const SizedBox(height: 14),
                      // Password
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        decoration: _inputDeco("Şifre", Icons.lock_outline_rounded).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.grey.shade400, size: 20),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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

                      // Social Buttons
                      SizedBox(
                        width: double.infinity,
                        child: _socialBtn(Icons.g_mobiledata, "Google ile Giriş", Colors.red, _googleGiris),
                      ),
                      const SizedBox(height: 24),
                      Text("v1.0.0", style: TextStyle(color: Colors.grey.shade300, fontSize: 11)),
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
