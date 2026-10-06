import 'dart:io' show Platform;
import '../tema.dart';
import '../tema_renkleri.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/cikartma.dart';
import 'package:url_launcher/url_launcher.dart';
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
      String.fromEnvironment('APP_VERSION', defaultValue: 'v2.0.0');

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _obscurePass = true;
  bool _kayitModu = false;
  /// KVKK: kayıt olurken aydınlatma metni onayı zorunlu (denetim #4 Y7).
  bool _politikaOnay = false;
  // Boş alan uyarısı doğrudan alanın altında gösterilir (SnackBar kaybolup gidiyordu).
  String? _emailHata;
  String? _sifreHata;
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
    // Eskiden sadece geçici bir SnackBar çıkıyordu; hangi alanın eksik
    // olduğu alanın üzerinde görünmüyordu.
    final emailBos = _emailCtrl.text.trim().isEmpty;
    final sifreBos = _passCtrl.text.isEmpty;
    if (emailBos || sifreBos) {
      setState(() {
        _emailHata = emailBos ? "E-posta adresini yaz" : null;
        _sifreHata = sifreBos ? "Şifreni yaz" : null;
      });
      return;
    }
    setState(() {
      _emailHata = null;
      _sifreHata = null;
      _loading = true;
    });
    try {
      if (_kayitModu) {
        if (!_politikaOnay) {
          setState(() => _loading = false);
          _hataGoster('Kayıt için Gizlilik Politikası ve Aydınlatma Metni\'ni onaylaman gerekiyor.');
          return;
        }
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
      backgroundColor: AppTema.tehlike,
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
    final r = context.renk;
    return Scaffold(
      backgroundColor: r.sayfa,
      body: Column(
        children: [
          // Üst kısım: "Teneffüs" — limon sarısı, çıkartma logo.
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD84D),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                border: Border(bottom: BorderSide(color: AppTema.ana, width: 2.5)),
              ),
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeCtrl,
                  // Küçülme klavyeye (viewInsets) bakıyordu; web/PWA'da klavye
                  // viewInsets vermediği için hiç çalışmıyordu (denetim #3).
                  // Artık bölümün yüksekliğine bakıyor; sığmazsa ölçekleniyor
                  // (yatay telefonda yazı açık zemine taşıyordu).
                  child: LayoutBuilder(builder: (context, c) {
                    final kucuk = c.maxHeight < 230;
                    final logoBoyut = kucuk ? 64.0 : 104.0;
                    return Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Teneffüs logosu (2026-10-04, Sabri'nin Gemini çizimi);
                              // kenarı logonun kendi mürekkep çemberi.
                              Container(
                                width: logoBoyut,
                                height: logoBoyut,
                                decoration: const ShapeDecoration(
                                  color: Colors.white,
                                  shape: CircleBorder(),
                                  shadows: [BoxShadow(color: AppTema.ana, offset: Offset(5, 5))],
                                ),
                                child: SvgPicture.asset('assets/images/logo_simge.svg', fit: BoxFit.contain),
                              ),
                              SizedBox(height: kucuk ? 8 : 16),
                              Text("Çember",
                                  style: TextStyle(
                                      fontFamily: AppTema.baslikFontu,
                                      fontSize: kucuk ? 30 : 42,
                                      fontWeight: FontWeight.w700,
                                      color: AppTema.ana,
                                      height: 1)),
                              if (!kucuk) ...[
                                const SizedBox(height: 6),
                                const Text("Sınıf Yönetimi Asistanı",
                                    style: TextStyle(color: AppTema.ana, fontSize: 15, fontWeight: FontWeight.w700)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
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
                        decoration: ShapeDecoration(
                          color: r.kart,
                          shape: StadiumBorder(side: BorderSide(color: r.kenar, width: 2.5)),
                        ),
                        child: Row(
                          children: [
                            _tabBtn("Giriş Yap", !_kayitModu, () => setState(() => _kayitModu = false)),
                            _tabBtn("Kayıt Ol", _kayitModu, () => setState(() => _kayitModu = true)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Email — alan doluyken satır içi etiket semantikten
                      // düşüyor; Semantics sarmalı adı korur (denetim Y8).
                      Semantics(
                        label: 'E-Posta',
                        child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        maxLength: 254,
                        buildCounter: _sayacGizle,
                        decoration: _inputDeco("E-Posta", Icons.email_outlined).copyWith(errorText: _emailHata),
                      ),
                      ),
                      const SizedBox(height: 14),
                      // Password
                      Semantics(
                        label: 'Şifre',
                        child: TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        // Web'de Enter formu göndermiyordu (denetim D2).
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) { if (!_loading) _emailGirisKayit(); },
                        maxLength: 128,
                        buildCounter: _sayacGizle,
                        autofillHints: _kayitModu
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        decoration: _inputDeco("Şifre", Icons.lock_outline_rounded).copyWith(
                          errorText: _sifreHata,
                          helperText: _kayitModu
                              ? "En az 10 karakter, harf ve rakam içermeli"
                              : null,
                          helperStyle: TextStyle(
                              color: r.metinUcuncul, fontSize: 12),
                          suffixIcon: IconButton(
                            tooltip: _obscurePass ? 'Şifreyi göster' : 'Şifreyi gizle',
                            icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: r.metinUcuncul, size: 20),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                      ),
                      ),
                      if (!_kayitModu)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading ? null : _sifremiUnuttum,
                            style: TextButton.styleFrom(
                              foregroundColor: r.vurguKoyu,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              // 32px dokunma hedefi, şifre kurtarma gibi
                              // kritik bir işlev için fazla küçüktü.
                              minimumSize: const Size(0, 44),
                              tapTargetSize: MaterialTapTargetSize.padded,
                            ),
                            child: const Text("Şifremi unuttum",
                                style: TextStyle(fontFamily: AppTema.govdeFontu, fontSize: 14, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      if (_kayitModu)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: CheckboxListTile(
                            value: _politikaOnay,
                            onChanged: (v) => setState(() => _politikaOnay = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Wrap(children: [
                              const Text('Öğrenci verilerini okulum adına işlediğimi biliyorum; ', style: TextStyle(fontSize: 13)),
                              InkWell(
                                onTap: () => launchUrl(Uri.parse(gizlilikPolitikasiUrl), mode: LaunchMode.externalApplication),
                                child: Text('Gizlilik Politikası ve Aydınlatma Metni',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: r.vurgu, decoration: TextDecoration.underline)),
                              ),
                              const Text('\'ni okudum, kabul ediyorum.', style: TextStyle(fontSize: 13)),
                            ]),
                          ),
                        ),
                      const SizedBox(height: 18),
                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: SertGolgeli(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              // Sabit height büyütülmüş yazıda kırpıyordu (denetim D8).
                              minimumSize: const Size.fromHeight(54),
                            ),
                            onPressed: _loading ? null : _emailGirisKayit,
                            child: _loading
                                ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: r.vurguMetin, strokeWidth: 2.5))
                                : Text(_kayitModu ? "Hesap Oluştur" : "Hesabıma Gir", style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      Row(children: [
                        Expanded(child: Divider(color: r.cizgi)),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            // Zemin grey.shade100; metinUcuncul burada 4,36:1 kalıyordu.
                            child: Text("veya", style: TextStyle(color: r.metinIkincil, fontSize: 14, fontWeight: FontWeight.w700))),
                        Expanded(child: Divider(color: r.cizgi)),
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
                            // Koyu zeminde siyah düğme kayboluyor; Apple HIG koyuda beyazı önerir.
                            style: r.koyuMu ? SignInWithAppleButtonStyle.white : SignInWithAppleButtonStyle.black,
                            borderRadius: BorderRadius.circular(14),
                            text: 'Apple ile Giriş Yap',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(
                        width: double.infinity,
                        // Google'ın çok renkli G'si; g_mobiledata ikonu kırmızı tek renkti (denetim #3).
                        child: _socialBtn(SvgPicture.asset('assets/images/google_g.svg', width: 22, height: 22), "Google ile Giriş", _googleGiris),
                      ),
                      const SizedBox(height: 12),
                      // Sosyal girişte de politika görünür olsun.
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Devam ederek '),
                          WidgetSpan(
                            child: InkWell(
                              onTap: () => launchUrl(Uri.parse(gizlilikPolitikasiUrl), mode: LaunchMode.externalApplication),
                              child: Text('Gizlilik Politikası',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: r.vurgu, decoration: TextDecoration.underline)),
                            ),
                          ),
                          const TextSpan(text: "'nı kabul etmiş olursun."),
                        ]),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: r.metinIkincil),
                      ),
                      const SizedBox(height: 12),
                      // Elle yazılan sürüm numarası güncellenmeyi unutuyordu
                      // (pubspec 1.1.0 iken ekranda hâlâ v1.0.0 yazıyordu).
                      // grey.shade300 beyaz üzerinde 1,3:1 — pratikte görünmüyordu.
                      Text(_surum, style: TextStyle(color: r.metinIkincil, fontSize: 12)),
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
    final r = context.renk;
    // Seçili sekme limon sarısı çıkartma; 44 px, ekran okuyucuda seçili.
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: active ? const Color(0xFFFFD84D) : Colors.transparent,
              shape: StadiumBorder(side: BorderSide(color: active ? AppTema.ana : Colors.transparent, width: 2)),
            ),
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTema.baslikFontu,
                  color: active ? AppTema.ana : r.metinIkincil,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                )),
          ),
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
    final r = context.renk;
    return InputDecoration(
      // hintText yazmaya başlayınca kayboluyor ve semantik ad vermiyordu;
      // labelText + never aynı görünümü korur, ekran okuyucuya adı verir
      // (denetim Y8).
      labelText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      // Çerçeve ve dolgu temadan (mürekkep kenarlı çıkartma); eski gri 500
      // etiket 2,6:1'di (denetim #3).
      labelStyle: TextStyle(color: r.metinUcuncul, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: r.ikonAna, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _socialBtn(Widget ikon, String label, VoidCallback onTap) {
    final r = context.renk;
    final sekil = StadiumBorder(side: BorderSide(color: r.kenar, width: 2.5));
    return Material(
      // Google logosu beyaz zemin ister; koyu temada da beyaz hap.
      color: Colors.white,
      shape: sekil,
      child: InkWell(
        customBorder: sekil,
        onTap: _loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ikon,
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: AppTema.ana, fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
