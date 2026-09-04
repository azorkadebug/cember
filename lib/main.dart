import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/giris_ekrani.dart';
import 'screens/profil_ekrani.dart';
import 'screens/siniflar_ekrani.dart';
import 'screens/tanitim_ekrani.dart';
import 'services/analytics_service.dart';
import 'services/firestore_service.dart';
import 'services/mac_durumu.dart';
import 'services/sifreleme_service.dart';
import 'tema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DateFormat('… MMMM …', 'tr') ay adlarını buradan alır; çağrılmazsa
  // intl yalnızca en_US tanır ve LocaleDataException atar.
  Intl.defaultLocale = 'tr';
  await initializeDateFormatting('tr');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const CemberApp());
}

class CemberApp extends StatelessWidget {
  const CemberApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Çember',
      debugShowCheckedModeBanner: false,
      // Bunlar olmadan Material'ın yerleşik metinleri İngilizce kalıyordu:
      // geri tuşu ipucu "Back", tarih seçici, kopyala/yapıştır menüsü.
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppTema.ana, primary: AppTema.ana),
        useMaterial3: true,
        textTheme: AppTema.textTheme,
        // Web/masaüstünde varsayılan "compact" yoğunluk düğmeleri 4-8 px
        // kısaltıyordu; diyalog düğmeleri 32 px'te kalıyordu (denetim O11).
        visualDensity: VisualDensity.standard,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(minimumSize: const Size(64, 44))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(minimumSize: const Size(64, 44))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44))),
        snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)))),
        cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)))),
      ),
      // Uygulama bilinçli olarak tek temada: skor tablosu kendi koyu
      // paletini kuruyor, geri kalanı açık. Sistem karanlık moddayken
      // yarısı dönüp yarısı kalmasın diye açıkça sabitlendi.
      themeMode: ThemeMode.light,
      // iOS "Daha Büyük Metin" 2x'e kadar çıkıyor; sabit yükseklikli kartlar
      // ve 44 px'lik düğmeler 1,5 üstünde kırpılıyor (denetim D8).
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.5)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      navigatorObservers: [AnalyticsService.observer],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final uid = snapshot.data!.uid;
          // Eski (sifrelendi:true) kayıtları çözebilmek için — yeni
          // yazmalar düz metin.
          SifrelemeService.initialize(uid);
          AnalyticsService.setUserId(uid);
          // Yarım kalan maç YALNIZCA bu kullanıcının kaydından yüklenir;
          // isimler yerelden değil Firestore'dan tazelenir.
          MacDurumu().yukle(uid);
          return _ProfilKontrol(uid: uid);
        }
        return const _TanitimVeyaGiris();
      },
    );
  }
}

/// Giriş yapılmamışsa: ilk açılışta tanıtım carousel'i, sonrasında giriş ekranı.
class _TanitimVeyaGiris extends StatefulWidget {
  const _TanitimVeyaGiris();

  @override
  State<_TanitimVeyaGiris> createState() => _TanitimVeyaGirisState();
}

class _TanitimVeyaGirisState extends State<_TanitimVeyaGiris> {
  bool? _goruldu; // null = kontrol ediliyor

  @override
  void initState() {
    super.initState();
    TanitimEkrani.goruldueMu().then((v) {
      if (mounted) setState(() => _goruldu = v);
    }).catchError((_) {
      // Depolama erişilemezse (ör. eklenti sorunu) tanıtımı atla — uygulama açılsın.
      if (mounted) setState(() => _goruldu = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_goruldu == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTema.ana)));
    }
    if (!_goruldu!) {
      return TanitimEkrani(onTamamlandi: () => setState(() => _goruldu = true));
    }
    return const GirisEkrani();
  }
}

class _ProfilKontrol extends StatefulWidget {
  final String uid;
  const _ProfilKontrol({required this.uid});

  @override
  State<_ProfilKontrol> createState() => _ProfilKontrolState();
}

class _ProfilKontrolState extends State<_ProfilKontrol> {
  bool _kontrol = true;
  bool _profilTamam = false;
  bool _hata = false;

  @override
  void initState() {
    super.initState();
    _kontrolEt();
  }

  Future<void> _kontrolEt() async {
    if (!_kontrol) setState(() { _kontrol = true; _hata = false; });
    try {
      final var_ = await FirestoreService(uid: widget.uid).profilVarMi();
      if (mounted) setState(() { _profilTamam = var_; _kontrol = false; });
    } catch (_) {
      // Hata durumunda profili "tamam" sayıp devam etmek fail-open bir
      // desendi: bağlantı yokken kullanıcı profilsiz ana ekrana düşüp boş
      // durumla karşılaşıyordu. Artık açıkça tekrar deneme sunuluyor.
      if (mounted) setState(() { _hata = true; _kontrol = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_kontrol) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTema.ana)));
    }
    if (_hata) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text("Bağlantı kurulamadı",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text("İnternet bağlantını kontrol edip tekrar dene.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppTema.ana),
                  onPressed: _kontrolEt,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Tekrar dene"),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (!_profilTamam) {
      // Direkt ProfilEkrani; callback ile profil tamamlanınca state güncellenir.
      // Eski sürümde nested Navigator vardı, iPad'de siyah ekran bug'ına sebep
      // oluyordu — bu yüzden kaldırıldı.
      return ProfilEkrani(
        ilkKayit: true,
        onIlkKayitTamamlandi: () => setState(() => _profilTamam = true),
      );
    }
    return const SiniflarEkrani();
  }
}
