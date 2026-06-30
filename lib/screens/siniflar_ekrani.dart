import '../tema.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/mac_durumu.dart';
import '../widgets/yardim_diyalogu.dart';
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
          if (AuthService().isAdmin) ...[
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
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => YardimDiyalogu.goster(
              context,
              baslik: 'Sınıflarım — Yardım',
              bolumler: const [
                YardimBolumu(
                  ikon: Icons.add_circle_outline_rounded,
                  baslik: 'Yeni sınıf oluştur',
                  aciklama: 'Sağ alttaki "+" düğmesi → sınıf adı yaz (örn. 7-A, 6-B). Forma renkleri otomatik atanır, sınıf kartına dokunarak değiştirebilirsin.',
                  renk: Color(0xFF43A047),
                ),
                YardimBolumu(
                  ikon: Icons.touch_app_rounded,
                  baslik: 'Sınıfa giriş',
                  aciklama: 'Sınıf kartına dokun → o sınıfın öğrenci listesi açılır. Yoklama alabilir, öğrenci ekleyebilir, maç başlatabilirsin.',
                  renk: Color(0xFF1976D2),
                ),
                YardimBolumu(
                  ikon: Icons.sports_kabaddi_rounded,
                  baslik: 'Sınıflar Arası Maç',
                  aciklama: 'İki farklı sınıfı karşı karşıya getir (örn. 7-A vs 7-B). Her sınıf bir takım olur, skor tablosu açılır.',
                  renk: Color(0xFFC77B46),
                ),
                YardimBolumu(
                  ikon: Icons.edit_rounded,
                  baslik: 'Sınıf adı değiştir / sil',
                  aciklama: 'Sınıf kartına basılı tut → menüden "Yeniden adlandır" veya "Sil" seç. Silme geri alınamaz.',
                  renk: Color(0xFFE53935),
                ),
                YardimBolumu(
                  ikon: Icons.palette_rounded,
                  baslik: 'Forma renkleri',
                  aciklama: 'Her sınıfa 8 takım rengi atanır (kırmızı, mavi, sarı, yeşil, siyah, beyaz, turuncu, lacivert). Takım oluştururken bu renklerden seçilir. Renk paletini sınıfa dokunarak özelleştirebilirsin.',
                  renk: Color(0xFF8E24AA),
                ),
              ],
            ),
          ),
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
          // Header gradient — kompakt
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTema.ana, AppTema.anaAcik],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text("👋", style: TextStyle(fontSize: 16, color: Colors.white.withAlpha(220))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AuthService().currentUser?.email ?? '',
                    style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 180),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, i) => _sinifKarti(context, snapshot.data!.docs[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'mac',
            onPressed: () => _siniflarArasiMacDialog(context),
            backgroundColor: const Color(0xFF1A1A2E),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.sports_rounded),
            label: const Text("Sınıflar Arası Maç", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'ekle',
            onPressed: () => _sinifEkle(context),
            backgroundColor: AppTema.ana,
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add_rounded),
            label: const Text("Sınıf Ekle", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
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
                MaterialPageRoute(builder: (context) => OgrenciListesiEkrani(sinifId: docId, sinifAd: ad)),
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _sinifPaleti(ad),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _sinifPaleti(ad).first.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))],
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
            onPressed: () async {
              if (c.text.trim().isEmpty) return;
              final ad = c.text.toUpperCase().trim();
              Navigator.pop(context);
              try {
                await _db.sinifEkle(ad);
                AnalyticsService.sinifOlusturuldu();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Sınıf eklenemedi: $e"),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                }
              }
            },
            child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static const _sinifPaletleri = [
    [Color(0xFFE94B6A), Color(0xFFFF6B35)], // pembe → turuncu
    [Color(0xFF4A90E2), Color(0xFF50C9C3)], // mavi → turkuaz
    [Color(0xFF00C896), Color(0xFF7FE5C5)], // yeşil → mint
    [Color(0xFF9B59B6), Color(0xFFD16BA5)], // mor → pembe
    [Color(0xFFF5C544), Color(0xFFFF8C42)], // sarı → turuncu
    [Color(0xFF26A69A), Color(0xFF4DB6AC)], // teal
    [Color(0xFFEF5350), Color(0xFFEC407A)], // kırmızı
    [Color(0xFF5C6BC0), Color(0xFF7986CB)], // indigo
  ];

  List<Color> _sinifPaleti(String ad) {
    return _sinifPaletleri[ad.hashCode.abs() % _sinifPaletleri.length];
  }

  static const _renkSecenekleri = ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Turuncu', 'Mor', 'Lacivert'];

  Color _renkBul(String renkAdi) {
    switch (renkAdi.toLowerCase().trim()) {
      case 'kırmızı': return Colors.red;
      case 'mavi': return Colors.blue;
      case 'sarı': return Colors.amber.shade600;
      case 'yeşil': return Colors.green;
      case 'siyah': return Colors.black87;
      case 'turuncu': return AppTema.ana;
      case 'mor': return Colors.purple;
      case 'lacivert': return Colors.indigo;
      default: return AppTema.ana;
    }
  }

  void _siniflarArasiMacDialog(BuildContext context) async {
    final snapshot = await _db.siniflarGetir();
    if (snapshot.docs.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("En az 2 sınıf gerekli."),
          backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      return;
    }

    final siniflar = snapshot.docs.map((d) {
      final data = d.data() as Map<String, dynamic>?;
      return {'id': d.id, 'ad': data?['ad'] ?? d.id};
    }).toList();

    String? sinif1Id = siniflar[0]['id'] as String;
    String? sinif2Id = siniflar[1]['id'] as String;
    String renk1 = 'Kırmızı';
    String renk2 = 'Mavi';

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.sports_rounded, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            const Text("Sınıflar Arası Maç", style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Sınıf 1
            _macSinifSecici("Ev Sahibi", siniflar, sinif1Id!, renk1, (id) => setDialogState(() => sinif1Id = id), (r) => setDialogState(() => renk1 = r)),
            const SizedBox(height: 8),
            const Text("VS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.grey)),
            const SizedBox(height: 8),
            // Sınıf 2
            _macSinifSecici("Deplasman", siniflar, sinif2Id!, renk2, (id) => setDialogState(() => sinif2Id = id), (r) => setDialogState(() => renk2 = r)),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.sports_rounded, size: 20),
              onPressed: () {
                if (sinif1Id == sinif2Id) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: const Text("Aynı sınıfı seçemezsiniz."),
                    backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                  return;
                }
                Navigator.pop(ctx);
                _siniflarArasiMacBaslat(sinif1Id!, sinif2Id!, renk1, renk2,
                  siniflar.firstWhere((s) => s['id'] == sinif1Id)['ad'] as String,
                  siniflar.firstWhere((s) => s['id'] == sinif2Id)['ad'] as String,
                );
              },
              label: const Text("Maçı Başlat", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macSinifSecici(String etiket, List<Map<String, dynamic>> siniflar, String secilenId, String secilenRenk,
      Function(String) onSinifChanged, Function(String) onRenkChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _renkBul(secilenRenk).withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _renkBul(secilenRenk).withAlpha(60)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(etiket, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: secilenId,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            isDense: true,
          ),
          items: siniflar.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['ad'] as String, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
          onChanged: (v) { if (v != null) onSinifChanged(v); },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: _renkSecenekleri.map((r) {
            final secili = r == secilenRenk;
            return GestureDetector(
              onTap: () => onRenkChanged(r),
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _renkBul(r),
                  shape: BoxShape.circle,
                  border: Border.all(color: secili ? Colors.white : Colors.transparent, width: 2),
                  boxShadow: secili ? [BoxShadow(color: _renkBul(r).withAlpha(120), blurRadius: 6)] : null,
                ),
                child: secili ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  void _siniflarArasiMacBaslat(String sinif1Id, String sinif2Id, String renk1, String renk2, String ad1, String ad2) async {
    final ogrenciler1 = await _db.ogrencileriGetir(sinif1Id);
    final ogrenciler2 = await _db.ogrencileriGetir(sinif2Id);

    final gelenler1 = ogrenciler1.where((o) => o.buradaMi).toList();
    final gelenler2 = ogrenciler2.where((o) => o.buradaMi).toList();

    if (gelenler1.isEmpty || gelenler2.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${gelenler1.isEmpty ? ad1 : ad2} sınıfında hazır öğrenci yok."),
          backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      return;
    }

    final takimlar = [
      TakimBilgi(
        isim: ad1,
        renkAdi: renk1,
        renk: _renkBul(renk1),
        oyuncular: gelenler1,
        kaptan: gelenler1.first,
      ),
      TakimBilgi(
        isim: ad2,
        renkAdi: renk2,
        renk: _renkBul(renk2),
        oyuncular: gelenler2,
        kaptan: gelenler2.first,
      ),
    ];

    MacDurumu().macBaslat(sinif1Id, takimlar);
    AnalyticsService.macBasladi(takimSayisi: 2, oyuncuSayisi: gelenler1.length + gelenler2.length);

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => SkorEkrani(takimlar: takimlar),
      ));
    }
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
