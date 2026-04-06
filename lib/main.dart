import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/giris_ekrani.dart';
import 'screens/profil_ekrani.dart';
import 'screens/siniflar_ekrani.dart';
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
        return const GirisEkrani();
      },
    );
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
      return _IlkProfilSarmalayici(
        onTamamlandi: () => setState(() => _profilTamam = true),
      );
    }
    return const SiniflarEkrani();
  }
}

class _IlkProfilSarmalayici extends StatelessWidget {
  final VoidCallback onTamamlandi;
  const _IlkProfilSarmalayici({required this.onTamamlandi});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => ProfilEkrani(ilkKayit: true),
      ),
      onPopPage: (route, result) {
        if (result == true) onTamamlandi();
        return route.didPop(result);
      },
    );
  }
}
