import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});
  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleGiris() async {
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Hatası: $e")),
        );
      }
    }
  }

  Future<void> _appleGiris() async {
    try {
      await _authService.signInWithApple();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Apple Hatası: $e")),
        );
      }
    }
  }

  Future<void> _emailGirisKayit(bool kayitMi) async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen e-posta ve şifre girin.")),
        );
      }
      return;
    }
    try {
      if (kayitMi) {
        await _authService.signUpWithEmail(_emailCtrl.text, _passCtrl.text);
      } else {
        await _authService.signInWithEmail(_emailCtrl.text, _passCtrl.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString().split('] ').last}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png',
                  height: 180,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.groups, size: 100, color: Colors.orange)),
              const SizedBox(height: 20),
              const Text("ÇEMBER",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
              const Text("Sınıf Yönetimi Asistanı",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 50),
              TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                      labelText: "E-Posta", prefixIcon: Icon(Icons.email))),
              TextField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(
                      labelText: "Şifre", prefixIcon: Icon(Icons.lock)),
                  obscureText: true),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                      onPressed: () => _emailGirisKayit(true),
                      child: const Text("Kayıt Ol")),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white),
                      onPressed: () => _emailGirisKayit(false),
                      child: const Text("Giriş Yap")),
                ],
              ),
              const SizedBox(height: 30),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("VEYA")),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50)),
                icon: const Icon(Icons.g_mobiledata, size: 30),
                label: const Text("Google ile Giriş Yap"),
                onPressed: _googleGiris,
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50)),
                icon: const Icon(Icons.apple),
                label: const Text("Apple ile Giriş Yap"),
                onPressed: _appleGiris,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
