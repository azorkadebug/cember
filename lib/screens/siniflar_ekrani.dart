import '../tema.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/mac_durumu.dart';
import 'ogrenci_listesi_ekrani.dart';
import 'admin_ekrani.dart';
import 'profil_ekrani.dart';
import 'skor_ekrani.dart';
import '../services/demo_modu.dart';

class SiniflarEkrani extends StatefulWidget {
  const SiniflarEkrani({super.key});

  @override
  State<SiniflarEkrani> createState() => _SiniflarEkraniState();
}

class _SiniflarEkraniState extends State<SiniflarEkrani> {
  FirestoreService get _db => FirestoreService(uid: AuthService().uid);
  bool _migrationYapildi = false;

  @override
  void initState() {
    super.initState();
    _migrationKontrol();
  }

  Future<void> _migrationKontrol() async {
    if (_migrationYapildi) return;
    _migrationYapildi = true;
    final sayac = await _db.tumSiniflariMigrate();
    if (sayac > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$sayac öğrenci verisi şifrelendi."),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Sınıflarım', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (AuthService().uid == 'A1Xyb80fR7NQ6KuwBt6NUa5p2743') ...[
            IconButton(
              icon: Icon(DemoModu.aktif ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              tooltip: DemoModu.aktif ? 'Demo Kapat' : 'Demo Aç',
              onPressed: () {
                setState(() {
                  DemoModu.aktif = !DemoModu.aktif;
                  if (!DemoModu.aktif) DemoModu.sifirla();
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(DemoModu.aktif ? "Demo modu açık — isimler gizli" : "Demo modu kapalı"),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: DemoModu.aktif ? Colors.orange.shade700 : Colors.green.shade700,
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              tooltip: 'Admin',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminEkrani())),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'Profilim',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilEkrani())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTema.ana, AppTema.anaAcik],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hoş geldiniz!",
                    style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14)),
                const SizedBox(height: 4),
                Text(AuthService().currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Aktif maç banner'ı
          ListenableBuilder(
            listenable: MacDurumu(),
            builder: (context, _) {
              if (!MacDurumu().aktif) return const SizedBox.shrink();
              return _macBanner(context);
            },
          ),
          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.siniflarStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                          const SizedBox(height: 12),
                          Text("Hata: ${snapshot.error}", textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red.shade700)),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppTema.ana));
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.class_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Henüz sınıf eklenmedi",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        Text("Sağ alttaki + butonuyla başlayın",
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, i) => _sinifKarti(context, snapshot.data!.docs[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sinifEkle(context),
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Sınıf Ekle", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _sinifKarti(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final ad = data?['ad'] ?? doc.id;
    final docId = doc.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: Key(docId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            final result = await showModalBottomSheet<String>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    ListTile(
                      leading: Icon(Icons.edit_rounded, color: AppTema.ana),
                      title: const Text("İsmi Düzenle", style: TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.pop(ctx, 'duzenle'),
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                      title: Text("Sınıfı Sil", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade600)),
                      onTap: () => Navigator.pop(ctx, 'sil'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
            if (result == 'duzenle') {
              if (context.mounted) _sinifAdiniDuzenle(context, docId, ad);
            } else if (result == 'sil') {
              if (context.mounted) _sinifSilOnay(context, docId);
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade700, size: 28),
          ),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withAlpha(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OgrenciListesiEkrani(sinifId: docId)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTema.anaAcik, AppTema.anaKoyu],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ad, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirestoreService(uid: AuthService().uid)
                                .ogrencilerStream(docId),
                            builder: (context, snap) {
                              final count = snap.hasData ? snap.data!.docs.length : 0;
                              return Text("$count öğrenci",
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
                            },
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _macBanner(BuildContext context) {
    final mac = MacDurumu();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: mac.duraklatildi ? Colors.orange : Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (mac.takimlar != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => OgrenciListesiEkrani(sinifId: mac.sinifId!),
                  )).then((_) {
                    // SiniflarEkrani yeniden çizilsin
                    (context as Element).markNeedsBuild();
                  });
                }
              },
              child: Text(
                mac.duraklatildi ? "Maç duraklatıldı" : "Maç devam ediyor",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
          // Duraklat / Devam Et
          GestureDetector(
            onTap: () => mac.duraklatildi ? mac.devamEt() : mac.duraklat(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                mac.duraklatildi ? Icons.play_arrow_rounded : Icons.pause_rounded,
                color: Colors.orange, size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Durdur
          GestureDetector(
            onTap: () => _macBitirOnay(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.stop_rounded, color: Colors.red.shade400, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _macBitirOnay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.stop_rounded, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          const Text("Maçı Bitir", style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          "Maçı tamamen bitirmek istediğinize emin misiniz? Skorlar sıfırlanacak.",
          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              MacDurumu().macBitir();
              Navigator.pop(ctx);
            },
            child: const Text("Evet, Bitir", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _sinifAdiniDuzenle(BuildContext context, String sinifId, String mevcutAd) {
    final c = TextEditingController(text: mevcutAd);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTema.ana50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_rounded, color: AppTema.ana),
            ),
            const SizedBox(width: 12),
            const Text('Sınıf Adını Düzenle', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Örn: 8/B',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTema.ana, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTema.ana,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              final yeniAd = c.text.trim();
              if (yeniAd.isNotEmpty && yeniAd != mevcutAd) {
                _db.sinifAdiniGuncelle(sinifId, yeniAd);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).then((_) => c.dispose());
  }

  void _sinifEkle(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTema.ana50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_rounded, color: AppTema.ana),
            ),
            const SizedBox(width: 12),
            const Text('Yeni Sınıf', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Örn: 8/B',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppTema.ana, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTema.ana,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (c.text.isNotEmpty) {
                _db.sinifEkle(c.text.toUpperCase());
                AnalyticsService.sinifOlusturuldu();
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _sinifSilOnay(BuildContext context, String sinifId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Text("Sınıfı Sil", style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          "$sinifId sınıfını ve tüm öğrencilerini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.",
          style: TextStyle(color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              await _db.sinifSil(sinifId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Evet, Sil", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
