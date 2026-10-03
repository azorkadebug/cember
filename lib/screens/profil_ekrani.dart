import '../tema.dart';
import '../tema_renkleri.dart';
import '../utils/metin.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/girdi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/yardim_diyalogu.dart';

class ProfilEkrani extends StatefulWidget {
  /// true ise ilk kayıt akışı (geri tuşu yok, zorunlu doldurma)
  final bool ilkKayit;

  /// ilkKayit=true iken kaydet tamamlandığında çağrılır. main.dart'taki
  /// _ProfilKontrol bu callback ile state'i günceller — nested Navigator
  /// kullanmamıza gerek kalmaz (iPad'de siyah ekran bug'ı bu yüzdendi).
  final VoidCallback? onIlkKayitTamamlandi;

  const ProfilEkrani({super.key, this.ilkKayit = false, this.onIlkKayitTamamlandi});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  // late: alan başlatıcısı olarak çalışırsa, hesap silme/çıkış sırasında
  // oturum kapanmışken bu widget yeniden kurulduğunda hata fırlatır.
  late final _db = FirestoreService(uid: AuthService().uid);
  final _adCtrl = TextEditingController();
  final _okulCtrl = TextEditingController();
  final _sehirCtrl = TextEditingController();
  String _brans = 'Beden Eğitimi';
  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  /// Kaydedilmemiş değişiklik var mı — geri tuşunda uyarmak için.
  /// Eskiden PopScope yalnızca ilk kayıt akışını koruyordu.
  bool _kirli = false;

  static const _branslar = [
    'Beden Eğitimi',
    'Matematik',
    'Fen Bilimleri',
    'Türkçe',
    'Sosyal Bilgiler',
    'İngilizce',
    'Müzik',
    'Görsel Sanatlar',
    'Teknoloji ve Tasarım',
    'Din Kültürü',
    'Rehberlik',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _profilYukle();
  }

  Future<void> _profilYukle() async {
    final data = await _db.profilGetir();
    if (data != null && mounted) {
      _adCtrl.text = data['ad'] ?? '';
      _okulCtrl.text = data['okul'] ?? '';
      _sehirCtrl.text = data['sehir'] ?? '';
      _brans = data['brans'] ?? 'Beden Eğitimi';
    }
    _ilkMetinler = [_adCtrl.text, _okulCtrl.text, _sehirCtrl.text];
    // Ön doldurma bittikten SONRA dinle, yoksa açılışta kirli görünür.
    for (final c in [_adCtrl, _okulCtrl, _sehirCtrl]) {
      c.addListener(_kirliIsaretle);
    }
    // İlk kayıt akışında Ad Soyad'ı sırayla şu kaynaklardan pre-fill et.
    // Apple Guideline 4: Sign in with Apple sonrası bu bilgi REQUIRED olamaz —
    // alan tamamen boş bırakılabilir, _kaydet "Öğretmen" varsayılanı atar.
    if (widget.ilkKayit && _adCtrl.text.isEmpty) {
      final user = AuthService().currentUser;
      final displayName = user?.displayName;
      if (displayName != null && displayName.isNotEmpty) {
        // 1. Auth'tan gelen ad-soyad (Apple ilk eşleşmede + Google her zaman)
        _adCtrl.text = displayName;
      } else if (user?.email != null && user!.email!.contains('@')) {
        // 2. Apple ad göndermediyse e-posta prefix'i (örn. demo@cember.org → "demo")
        _adCtrl.text = user.email!.split('@').first;
      }
      // 3. Hiçbiri yoksa boş kalır — kullanıcı isterse doldurur, _kaydet
      //    boş ise "Öğretmen" atar (Apple'ın REQUIRED yasağına uygun)
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _kaydet() async {
    // Apple Guideline 4: Sign in with Apple sonrası ad/email REQUIRED
    // yapamayız. Boş bırakırsa varsayılan değer atıyoruz, kullanıcı sonra
    // Profilim ekranından düzenleyebilir.
    final ad = _adCtrl.text.trim().isEmpty ? "Öğretmen" : _adCtrl.text.trim();

    setState(() => _kaydediliyor = true);
    await _db.profilKaydet({
      'ad': ad,
      'okul': _okulCtrl.text.trim(),
      'sehir': _sehirCtrl.text.trim(),
      'brans': _brans,
      'email': AuthService().currentUser?.email ?? '',
    });

    if (widget.ilkKayit) {
      unawaited(AnalyticsService.profilTamamlandi(sehir: _sehirCtrl.text.trim(), brans: _brans));
    }

    if (mounted) {
      setState(() { _kaydediliyor = false; _kirli = false; });
      if (widget.ilkKayit) {
        // Callback varsa onu kullan (main.dart'tan çağrı, nested Navigator yok)
        // Yoksa eski davranış: pop ile sinyal ver (backward compat)
        if (widget.onIlkKayitTamamlandi != null) {
          widget.onIlkKayitTamamlandi!();
        } else {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Profil kaydedildi."),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context);
      }
    }
  }

  List<String> _ilkMetinler = const ['', '', ''];

  void _kirliIsaretle() {
    // Alana yalnız dokunmak (seçim değişimi) da kirli sayılıyordu (denetim #4 O6).
    final degisti = [_adCtrl.text, _okulCtrl.text, _sehirCtrl.text]
        .asMap().entries.any((e) => e.value != _ilkMetinler[e.key]);
    if (degisti != _kirli && mounted) setState(() => _kirli = degisti);
  }

  /// Kaydedilmemiş değişiklikle çıkmadan önce sorar.
  Future<bool> _cikisOnayi() async {
    final cikilsin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kaydedilmemiş değişiklikler'),
        content: const Text('Profilinde yaptığın değişiklikler kaydedilmedi. Çıkarsan kaybolacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Kaydetmeden çık',
                style: TextStyle(color: ctx.renk.tehlike, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return cikilsin ?? false;
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _okulCtrl.dispose();
    _sehirCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    return PopScope(
      // İlk kayıt akışında geri tuşu zaten kapalı; normal düzenlemede ise
      // yalnızca kaydedilmemiş değişiklik varsa araya giriyoruz.
      canPop: !widget.ilkKayit && !_kirli,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || widget.ilkKayit) return;
        if (await _cikisOnayi() && mounted) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: r.sayfa,
        appBar: AppBar(
          backgroundColor: r.bar,
          foregroundColor: r.barMetin,
          title: Text(widget.ilkKayit ? "Profilini Tamamla" : "Profilim",
              style: const TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          automaticallyImplyLeading: !widget.ilkKayit,
          actions: widget.ilkKayit ? null : [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              tooltip: 'Yardım',
              onPressed: () => YardimDiyalogu.goster(
                context,
                baslik: 'Profilim — Yardım',
                bolumler: const [
                  YardimBolumu(
                    ikon: Icons.person_rounded,
                    baslik: 'Profil bilgileri',
                    aciklama: 'Ad, okul, şehir ve branş bilgileri. Apple/Google ile giriş yaptıysan Ad Soyad otomatik dolar — istersen değiştirebilirsin. Branş listede yoksa "Diğer" seç.',
                    renk: Color(0xFF1976D2),
                  ),
                  YardimBolumu(
                    ikon: Icons.email_outlined,
                    baslik: 'E-posta',
                    aciklama: 'Hangi hesapla giriş yaptığını gösterir. Değiştirilemez — yeni e-posta için yeni hesap açman lazım.',
                    renk: Color(0xFF43A047),
                  ),
                  YardimBolumu(
                    ikon: Icons.delete_forever_rounded,
                    baslik: 'Hesabımı sil (Tehlikeli Bölge)',
                    aciklama: 'Tüm sınıfların, öğrencilerin, kayıtların ve profilin kalıcı olarak silinir. İki aşamalı onay var (SIL yazman gerek). İşlem geri ALINAMAZ — silinince Çember\'i yeniden indirip yeni hesap açman gerekir.',
                    renk: Color(0xFFE53935),
                  ),
                  YardimBolumu(
                    ikon: Icons.privacy_tip_rounded,
                    baslik: 'Gizlilik politikası',
                    aciklama: 'KVKK uyumlu. Verilerin Google Firebase altyapısında, şifreli bağlantı üzerinden saklanır; güvenlik kuralları sayesinde sınıflarını yalnızca sen görebilirsin. Detay: cemberapp-2a101.web.app/privacy.html',
                    renk: Color(0xFF8E24AA),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _yukleniyor
            ? Center(child: CircularProgressIndicator(color: r.vurgu))
            : SafeArea(
                bottom: true,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  // Center yerine Align.topCenter: SingleChildScrollView unbounded
                  // height verdiği için Center vertical olarak deli davranıyor,
                  // tall içerik ekran dışına taşıyor ve scroll bozuluyor (iPad bug).
                  child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.ilkKayit) ...[
                          const Text("Hoş geldin!",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text("Seni daha iyi tanıyalım.",
                              style: TextStyle(color: r.koyuMu ? r.metinIkincil : Colors.grey.shade600, fontSize: 14)),
                          const SizedBox(height: 28),
                        ],
                        _buildField("Ad Soyad", _adCtrl, Icons.person_rounded),
                        const SizedBox(height: 16),
                        _buildField("Okul", _okulCtrl, Icons.school_rounded),
                        const SizedBox(height: 16),
                        _buildField("Şehir", _sehirCtrl, Icons.location_city_rounded),
                        const SizedBox(height: 16),
                        Text("Branş", style: TextStyle(color: r.koyuMu ? r.metinGovde : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        // Çıplak DropdownButton, diğer alanların prefixIcon +
                        // OutlineInputBorder desenine uymuyordu; odak durumu
                        // da yoktu. Artık _buildField ile aynı görünüyor.
                        DropdownButtonFormField<String>(
                          initialValue: _brans,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(14),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.school_rounded, color: r.ikonAna, size: 20),
                            filled: true,
                            fillColor: r.kart,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: r.cizgiAcik),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: r.cizgiAcik),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: r.koyuMu ? r.vurgu : r.ikonAna, width: 2),
                            ),
                          ),
                          items: _branslar.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (val) => setState(() {
                            _brans = val!;
                            _kirli = true;
                          }),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: r.vurgu,
                              foregroundColor: r.vurguMetin,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 2,
                            ),
                            onPressed: _kaydediliyor ? null : _kaydet,
                            child: _kaydediliyor
                                ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: r.vurguMetin, strokeWidth: 2.5))
                                : const Text("Kaydet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        // Görünüm cihaz ayarı: hemen uygulanır, form verisi
                        // değil — "kaydedilmemiş değişiklik" sayılmaz.
                        const SizedBox(height: 28),
                        Text("Görünüm", style: TextStyle(color: r.koyuMu ? r.metinGovde : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: TemaTercihi.mod,
                          builder: (context, mod, _) => SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<ThemeMode>(
                              segments: const [
                                ButtonSegment(
                                  value: ThemeMode.system,
                                  icon: Icon(Icons.brightness_auto_rounded),
                                  label: Text("Sistem"),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.light,
                                  icon: Icon(Icons.light_mode_rounded),
                                  label: Text("Açık"),
                                ),
                                ButtonSegment(
                                  value: ThemeMode.dark,
                                  icon: Icon(Icons.dark_mode_rounded),
                                  label: Text("Koyu"),
                                ),
                              ],
                              selected: {mod},
                              showSelectedIcon: false,
                              onSelectionChanged: (secim) => TemaTercihi.ayarla(secim.first),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Sistem: telefonunun açık/koyu ayarına uyar. Bu cihazda saklanır.",
                            style: TextStyle(color: r.metinUcuncul, fontSize: 12)),
                        if (!widget.ilkKayit) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: Text(
                              AuthService().currentUser?.email ?? '',
                              // grey.shade400 üzerinde 1,7:1'di (denetim Y7).
                              style: TextStyle(color: r.metinIkincil, fontSize: 13),
                            ),
                          ),
                          // Uygulama içinde politikaya tıklanabilir bağlantı yoktu (denetim #4 Y7).
                          Center(
                            child: TextButton.icon(
                              onPressed: () => launchUrl(Uri.parse(gizlilikPolitikasiUrl), mode: LaunchMode.externalApplication),
                              icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                              label: const Text('Gizlilik Politikası ve Aydınlatma Metni'),
                            ),
                          ),
                          const SizedBox(height: 48),
                          Divider(color: r.cizgi, height: 1),
                          const SizedBox(height: 20),
                          Text(
                            "Tehlikeli Bölge",
                            style: TextStyle(
                              color: r.yokMetin,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hesabını silmek tüm sınıflarını, öğrenci kayıtlarını, profil bilgilerini ve giriş hesabını kalıcı olarak siler. Bu işlem geri alınamaz.",
                            style: TextStyle(color: r.koyuMu ? r.metinIkincil : Colors.grey.shade600, fontSize: 13, height: 1.5),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: r.yokMetin,
                                side: BorderSide(color: r.yokSerit),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.delete_forever_rounded, size: 20),
                              label: const Text("Hesabımı Sil", style: TextStyle(fontWeight: FontWeight.w700)),
                              onPressed: _hesapSilmeBaslat,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // Hesap silme akışı
  // ============================================================

  Future<void> _hesapSilmeBaslat() async {
    final onay1 = await _ilkUyariGoster();
    if (onay1 != true || !mounted) return;

    final onay2 = await _silOnayiGoster();
    if (onay2 != true || !mounted) return;

    await _hesapSilmeYurut();
  }

  Future<bool?> _ilkUyariGoster() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.warning_amber_rounded, color: ctx.renk.yokMetin, size: 28),
          const SizedBox(width: 10),
          const Expanded(child: Text("Hesabını silmek üzeresin")),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Şunlar kalıcı olarak silinecek:"),
            const SizedBox(height: 10),
            _silinecekItem("Tüm sınıfların"),
            _silinecekItem("Tüm öğrenci kayıtların"),
            _silinecekItem("Profil bilgilerin"),
            _silinecekItem("Giriş hesabın (Google/Apple/e-posta)"),
            const SizedBox(height: 14),
            Text(
              "Bu işlem geri alınamaz.",
              style: TextStyle(fontWeight: FontWeight.w800, color: ctx.renk.yokMetin),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Vazgeç"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.renk.yokMetin),
            child: const Text("Devam"),
          ),
        ],
      ),
    );
  }

  Widget _silinecekItem(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Icon(Icons.close_rounded, size: 18, color: context.renk.yokMetin),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ]),
      );

  Future<bool?> _silOnayiGoster() {
    final ctrl = TextEditingController();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          // Türkçe klavye "sil"i "SİL" yapar; Türkçe dışı klavyede "SIL" de kabul.
          final yazilan = trBuyut(ctrl.text.trim());
          final canConfirm = yazilan == 'SİL' || yazilan == 'SIL';
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Son onay"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Onaylamak için aşağıdaki kutuya SİL yaz:",
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: GirdiSiniri.onayKelimesi,
                  buildCounter: gizliSayac,
                  onChanged: (_) => setLocalState(() {}),
                  decoration: InputDecoration(
                    hintText: 'SİL',
                    filled: true,
                    fillColor: ctx.renk.yuzeyGri,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Vazgeç"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canConfirm
                      ? (ctx.renk.koyuMu ? ctx.renk.silDolgu : Colors.red.shade700)
                      : ctx.renk.cizgi,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: canConfirm ? () => Navigator.pop(ctx, true) : null,
                child: const Text("Hesabımı Sil"),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Silme yetkisini HİÇBİR VERİ SİLMEDEN önce tazeler.
  ///
  /// Eski akış önce Firestore verisini siliyor, sonra `deleteAccount()`
  /// çağırıyordu. Firebase, son girişin üzerinden ~5 dakika geçmişse
  /// `requires-recent-login` fırlatır — ki kullanıcı uygulamayı açıp
  /// profile gidip iki onay diyaloğunu geçtiğinde oturum neredeyse her
  /// zaman eskidir. Sonuç: veri gidiyor, hesap kalıyordu.
  Future<bool> _silmeYetkisiniTazele() async {
    final auth = AuthService();
    try {
      await auth.yenidenDogrula();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code != 'reauth-password-required') {
        if (mounted) _hataGoster(AuthService.hataMesaji(e));
        return false;
      }
    } catch (e) {
      if (AuthService.iptalMi(e)) return false;
      if (mounted) _hataGoster(AuthService.hataMesaji(e));
      return false;
    }

    // E-posta/şifre hesabı: şifreyi sor.
    if (!mounted) return false;
    final sifre = await _sifreSor();
    if (sifre == null || !mounted) return false;
    try {
      await auth.yenidenDogrulaSifreIle(sifre);
      return true;
    } catch (e) {
      if (mounted) _hataGoster(AuthService.hataMesaji(e));
      return false;
    }
  }

  Future<String?> _sifreSor() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Şifreni doğrula"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Güvenlik için hesabını silmeden önce şifreni bir kez daha girmen gerekiyor.",
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              obscureText: true,
              maxLength: 128,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              decoration: InputDecoration(
                hintText: 'Şifren',
                filled: true,
                fillColor: ctx.renk.yuzeyGri,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.renk.koyuMu ? ctx.renk.silDolgu : Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text("Doğrula"),
          ),
        ],
      ),
    ).then((v) {
      ctrl.dispose();
      return (v == null || v.isEmpty) ? null : v;
    });
  }

  Future<void> _hesapSilmeYurut() async {
    // 1) Önce yetkiyi tazele — bu aşamada hiçbir veri silinmedi, kullanıcı
    //    vazgeçer veya doğrulama başarısız olursa kayıpsız çıkılır.
    final yetki = await _silmeYetkisiniTazele();
    if (!yetki || !mounted) return;

    // Yükleme göstergesi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: ctx.renk.vurgu),
                  const SizedBox(height: 16),
                  const Text("Verilerin siliniyor...",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ),
    ).ignore();

    try {
      // 2) Firestore verileri (sınıflar, öğrenciler, yoklamalar, profil).
      //    Oturum hâlâ açık olmalı — kurallar `request.auth` istiyor.
      await _db.tumVerileriSil();
      await AnalyticsService.sifirla();
      // 3) Auth hesabı. Oturum az önce tazelendiği için
      //    `requires-recent-login` beklenmiyor.
      await AuthService().deleteAccount();
      // Yerel maç kaydı, demo eşlemesi ve Firestore önbelleğini de temizle.
      await AuthService().signOut();

      if (mounted) {
        // Loader'ı kapat + navigation stack'ini temizle (siniflar > profil > dialog).
        // popUntil((r) => r.isFirst) tüm pushed route'ları temizler, AuthWrapper
        // root'unda kalırız. Firebase auth state değişimi de bu sırada algılanıp
        // GirisEkrani gösterir. (Önceki kod sadece loader'ı pop ediyordu, profil
        // ekranı stack'te kalıyor ve login'e dönmüyordu — özellikle iPad'de bug.)
        Navigator.of(context, rootNavigator: true)
            .popUntil((route) => route.isFirst);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        // Yetki adımı geçildiği için buraya normalde düşülmez.
        _yenidenGirisHatasiGoster();
      } else {
        _hataGoster(AuthService.hataMesaji(e));
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) _hataGoster(AuthService.hataMesaji(e));
    }
  }

  void _yenidenGirisHatasiGoster() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Yeniden giriş yap"),
        content: const Text(
          "Güvenlik nedeniyle hesabını silmek için yakın zamanda giriş yapmış olman gerekiyor. Çıkış yapıp tekrar giriş yaptıktan sonra silme işlemini yeniden dene.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tamam"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.renk.vurgu,
              foregroundColor: ctx.renk.vurguMetin,
            ),
            child: const Text("Çıkış Yap"),
          ),
        ],
      ),
    );
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    final r = context.renk;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: r.koyuMu ? r.metinGovde : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        // Görsel etiket ayrı bir Text; ekran okuyucu alanı boş "input" diye
        // okuyordu (denetim Y8). Satır içi label/hint alan doluyken
        // semantikten düşüyor; Semantics sarmalı her durumda adı verir.
        Semantics(
          label: label,
          child: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          maxLength: GirdiSiniri.profilAlani,
          buildCounter: gizliSayac,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: r.koyuMu ? r.ikonAna : AppTema.anaAcik, size: 20),
            filled: true,
            fillColor: r.kart,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: r.cizgiAcik)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: r.cizgiAcik)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: r.vurgu, width: 2)),
          ),
          ),
        ),
      ],
    );
  }
}
