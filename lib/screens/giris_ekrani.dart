import '../tema.dart';
import 'package:flutter/material.dart';
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
    } catch (e) {
      if (mounted) _hataGoster("Google Hatası: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appleGiris() async {
    setState(() => _loading = true);
    try {
      await _authService.signInWithApple();
    } catch (e) {
      if (mounted) _hataGoster("Apple Hatası: $e");
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
      } else {
        await _authService.signInWithEmail(_emailCtrl.text, _passCtrl.text);
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Branding
                  FadeTransition(
                    opacity: _fadeCtrl,
                    child: Column(
                      children: [
                        // Animated logo container
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppTema.anaAcik.withAlpha(60), AppTema.ana.withAlpha(40)],
                            ),
                            border: Border.all(color: Colors.white.withAlpha(20), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset('assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Icon(Icons.groups_rounded, size: 50, color: Colors.white.withAlpha(200))),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text("ÇEMBER",
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text("Sınıf Yönetimi Asistanı",
                              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 13, letterSpacing: 2)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form Card
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _slideCtrl,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withAlpha(15)),
                        ),
                        child: Column(
                          children: [
                            // Tab: Giriş / Kayıt
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
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
                            _inputField(
                              controller: _emailCtrl,
                              hint: "E-Posta",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),
                            // Password
                            _inputField(
                              controller: _passCtrl,
                              hint: "Şifre",
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePass,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: Colors.white.withAlpha(100), size: 20),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
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
                                  elevation: 0,
                                ),
                                onPressed: _loading ? null : _emailGirisKayit,
                                child: _loading
                                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Text(_kayitModu ? "Hesap Oluştur" : "Giriş Yap",
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: Colors.white.withAlpha(40))),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text("veya devam et", style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 12))),
                    Expanded(child: Divider(color: Colors.white.withAlpha(40))),
                  ]),
                  const SizedBox(height: 28),

                  // Social Buttons
                  Row(
                    children: [
                      Expanded(child: _socialBtn(Icons.g_mobiledata, "Google", Colors.white, Colors.red, _googleGiris)),
                      const SizedBox(width: 14),
                      Expanded(child: _socialBtn(Icons.apple_rounded, "Apple", Colors.white, Colors.white, _appleGiris)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Footer
                  Text("v1.0.0", style: TextStyle(color: Colors.white.withAlpha(40), fontSize: 11)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
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
                color: active ? Colors.white : Colors.white.withAlpha(100),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              )),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withAlpha(60)),
        prefixIcon: Icon(icon, color: Colors.white.withAlpha(80), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withAlpha(8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withAlpha(20))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withAlpha(20))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTema.ana, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _socialBtn(IconData icon, String label, Color bg, Color iconColor, VoidCallback onTap) {
    return Material(
      color: bg.withAlpha(12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _loading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor.withAlpha(200), size: 24),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
