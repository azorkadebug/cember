import 'package:flutter/material.dart';
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppTema.ana, primary: AppTema.ana),
        useMaterial3: true,
        cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)))),
      ),
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
          SifrelemeService.initialize(snapshot.data!.uid);
          AnalyticsService.setUserId(snapshot.data!.uid);
          MacDurumu().yukle(); // localStorage'dan aktif maçı yükle
          return _ProfilKontrol(uid: snapshot.data!.uid);
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

  @override
  void initState() {
    super.initState();
    _kontrolEt();
  }

  Future<void> _kontrolEt() async {
    try {
      final var_ = await FirestoreService(uid: widget.uid).profilVarMi();
      if (mounted) setState(() { _profilTamam = var_; _kontrol = false; });
    } catch (_) {
      // Firestore erişim hatası olursa profil ekranını atla
      if (mounted) setState(() { _profilTamam = true; _kontrol = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_kontrol) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTema.ana)));
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
