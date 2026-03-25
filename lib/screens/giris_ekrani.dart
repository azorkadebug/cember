import '../tema.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void _telefonGirisi() {
    final telefonCtrl = TextEditingController(text: "+90");
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.phone_rounded, color: Colors.green.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Text("Telefon ile Giriş", style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          content: TextField(
            controller: telefonCtrl,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "+90 5XX XXX XXXX",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.green.shade700, width: 2)),
              prefixIcon: Icon(Icons.phone_rounded, color: Colors.green.shade700),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final tel = telefonCtrl.text.trim();
                if (tel.length < 10) {
                  _hataGoster("Geçerli bir telefon numarası girin.");
                  return;
                }
                Navigator.pop(ctx);
                _smsKoduGonder(tel);
              },
              child: const Text("SMS Gönder", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    ).then((_) => telefonCtrl.dispose());
  }

  void _smsKoduGonder(String telefon) {
    setState(() => _loading = true);
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: telefon,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Otomatik doğrulama (Android'de)
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) setState(() => _loading = false);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => _loading = false);
          _hataGoster("SMS gönderilemedi: ${e.message}");
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() => _loading = false);
          _smsKoduDogrulaDialog(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  void _smsKoduDogrulaDialog(String verificationId) {
    final kodCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.sms_rounded, color: Colors.green.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Text("SMS Kodu", style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Telefonunuza gelen 6 haneli kodu girin.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: kodCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.green.shade700, width: 2)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (kodCtrl.text.length != 6) return;
                try {
                  final credential = PhoneAuthProvider.credential(
                    verificationId: verificationId,
                    smsCode: kodCtrl.text.trim(),
                  );
                  await FirebaseAuth.instance.signInWithCredential(credential);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (mounted) _hataGoster("Kod hatalı, tekrar deneyin.");
                }
              },
              child: const Text("Doğrula", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    ).then((_) => kodCtrl.dispose());
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
                      // Logo — arka plansız, doğal
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset('assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                    color: Colors.white.withAlpha(20),
                                    child: const Icon(Icons.groups_rounded, size: 50, color: Colors.white),
                                  )),
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
                              : Text(_kayitModu ? "Hesap Oluştur" : "Giriş Yap",
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
                      Row(
                        children: [
                          Expanded(child: _socialBtn(Icons.g_mobiledata, "Google", Colors.red, _googleGiris)),
                          const SizedBox(width: 14),
                          Expanded(child: _socialBtn(Icons.apple_rounded, "Apple", Colors.black, _appleGiris)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Telefon girişi
                      SizedBox(
                        width: double.infinity,
                        child: _socialBtn(Icons.phone_rounded, "Telefon ile Giriş", Colors.green.shade700, _telefonGirisi),
                      ),
                      const SizedBox(height: 24),
                      Text("v1.0.0", style: TextStyle(color: Colors.grey.shade300, fontSize: 11)),
                    ],
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
