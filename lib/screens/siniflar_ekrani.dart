import '../tema.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/girdi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/mac_durumu.dart';
import '../models/kontrol_kalemi.dart';
import '../widgets/yardim_diyalogu.dart';
import 'ogrenci_listesi_ekrani.dart';
import 'ogrenci_arama_ekrani.dart';
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

  /// Sınıf kartlarındaki "N öğrenci" sayacının akışları, sınıf id'sine göre
  /// önbelleklenir.
  ///
  /// Eskiden akış doğrudan `build()` içinde kuruluyordu: `stream:` her
  /// yeniden çizimde yeni bir nesne olduğu için StreamBuilder aboneliği
  /// iptal edip yeniden kuruyor, her yeniden abonelik koleksiyonun
  /// tamamını Firestore'dan tekrar okuyordu. 10 sınıf × 30 öğrenci, her
  /// setState'te 300 okuma demekti — Spark planında günlük kota gün
  /// ortasında tükenebiliyordu.
  final Map<String, Stream<QuerySnapshot>> _ogrenciSayaclari = {};

  Stream<QuerySnapshot> _ogrenciSayisiAkisi(String sinifId) =>
      _ogrenciSayaclari.putIfAbsent(
          sinifId, () => _db.ogrencilerStream(sinifId));

  @override
  void initState() {
    super.initState();
    _migrationKontrol();
  }

  Future<void> _migrationKontrol() async {
    if (_migrationYapildi) return;
    _migrationYapildi = true;
    // Eski şifreli kayıtları düz metne taşıyan arka plan göçü. Eskiden
    // burada "N öğrenci verisi şifrelendi" diye bir bildirim gösteriliyordu:
    // artık şifreleme yapılmadığı için yanlış olmasının yanında, öğretmenin
    // hakkında bir şey yapabileceği bir olay da değil. Sessiz çalışıyor.
    await _db.tumSiniflariMigrate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Sınıflarım'),
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
            icon: const Icon(Icons.person_search_rounded),
            tooltip: 'Öğrenci ara',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OgrenciAramaEkrani())),
          ),
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
                  aciklama: 'Sağ alttaki "+" düğmesi → sınıf adı yaz (örn. 7-A, 6-B) ve branşını seç. Kontrol kalemleri (forma, kitap, boya…) branşa göre otomatik gelir; takım renkleri de otomatik atanır.',
                  renk: Color(0xFF43A047),
                ),
                YardimBolumu(
                  ikon: Icons.touch_app_rounded,
                  baslik: 'Sınıfa giriş',
                  aciklama: 'Sınıf kartına dokun → o sınıfın öğrenci listesi açılır. Yoklama alabilir, öğrenci ekleyebilir, takım kurup etkinlik başlatabilirsin.',
                  renk: Color(0xFF1976D2),
                ),
                YardimBolumu(
                  ikon: Icons.sports_kabaddi_rounded,
                  baslik: 'Sınıflar Arası Yarışma',
                  aciklama: 'İki farklı sınıfı karşı karşıya getir (örn. 7-A vs 7-B) — maç, bilgi yarışması, münazara… Her sınıf bir takım olur, skor tablosu açılır.',
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
                  baslik: 'Takım renkleri',
                  aciklama: 'Takım kurarken formalar sırayla renk alır: kırmızı, mavi, sarı, yeşil, siyah, turuncu, mor, lacivert. Sınıfın forma listesini öğrenci ekranındaki ⋮ menüsünden "Takım Renkleri" ile değiştirebilirsin.',
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
          // Aktif maç banner'ı — geniş ekranda kart listesiyle aynı
          // genişlikte kalsın, tek başına kenardan kenara yayılmasın.
          ListenableBuilder(
            listenable: MacDurumu(),
            builder: (context, _) {
              if (!MacDurumu().aktif) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
                  child: _macBanner(context),
                ),
              );
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.class_outlined, size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text("Hoş geldin! 👋",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          const Text("Üç adımda hazırsın:",
                              style: TextStyle(color: AppTema.metinIkincil)),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 2))],
                            ),
                            child: Column(children: [
                              _bosAdim(1, Icons.add_circle_outline_rounded, "Sınıfını ekle",
                                  "Sağ alttaki + düğmesi → ad + branş seç"),
                              const SizedBox(height: 14),
                              _bosAdim(2, Icons.person_add_alt_rounded, "Öğrencileri ekle",
                                  "Tek tek veya toplu liste olarak"),
                              const SizedBox(height: 14),
                              _bosAdim(3, Icons.fact_check_rounded, "Yoklamanı al",
                                  "Kontrol kalemleri branşına göre hazır"),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Geniş ekranda (iPad, masaüstü web) kartlar 1400+ px'e
                // yayılıyordu. Center DEĞİL Align — bkz. profil_ekrani.dart'taki
                // iPad kaydırma notu.
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 180),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, i) => _sinifKarti(context, snapshot.data!.docs[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // İki genişletilmiş FAB alt alta durunca etiket uzunlukları farklı
      // olduğu için sol kenarları kademeli görünüyordu ve ikisi de aynı
      // görsel ağırlıktaydı. İkincil eylem artık küçük ikon-FAB.
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'mac',
            onPressed: () => _siniflarArasiMacDialog(context),
            backgroundColor: AppTema.panelKoyu1,
            foregroundColor: Colors.white,
            elevation: 3,
            tooltip: 'Sınıflar Arası Yarışma',
            child: const Icon(Icons.emoji_events_rounded),
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

  /// Boş durum kartındaki tek bir adım satırı (1-2-3 yönlendirmesi).
  Widget _bosAdim(int no, IconData ikon, String baslik, String aciklama) {
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: AppTema.ana.withAlpha(20), shape: BoxShape.circle),
        child: Center(
          child: Text("$no", style: const TextStyle(color: AppTema.ana, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text(aciklama, style: const TextStyle(color: AppTema.metinIkincil, fontSize: 12)),
        ]),
      ),
      Icon(ikon, color: Colors.grey.shade300, size: 22),
    ]);
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
                      title: const Text("İsmi Düzenle"),
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
                            stream: _ogrenciSayisiAkisi(docId),
                            builder: (context, snap) {
                              final count = snap.hasData ? snap.data!.docs.length : 0;
                              // Boş sınıf listede diğerleriyle aynı görünüyordu;
                              // öğretmeni bir sonraki adıma yönlendir.
                              if (snap.hasData && count == 0) {
                                return Row(mainAxisSize: MainAxisSize.min, children: [
                                  const Icon(Icons.person_add_alt_rounded,
                                      size: 14, color: AppTema.uyari),
                                  const SizedBox(width: 5),
                                  Text("Öğrenci ekle",
                                      style: TextStyle(
                                          color: AppTema.uyari,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ]);
                              }
                              return Text("$count öğrenci",
                                  style: const TextStyle(color: AppTema.metinIkincil, fontSize: 13));
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
        gradient: const LinearGradient(colors: AppTema.panelGradient),
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
            child: Semantics(
              button: true,
              label: '${mac.duraklatildi ? "Etkinlik duraklatıldı" : "Etkinlik devam ediyor"}, etkinliğe dönmek için dokun',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      mac.duraklatildi ? "Etkinlik duraklatıldı" : "Etkinlik devam ediyor",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Duraklat / Devam Et ve Durdur: GestureDetector'dı, semantik
          // ağaçta hiç yoktu ve ~38×30 px'ti (denetim Y6).
          IconButton(
            tooltip: mac.duraklatildi ? 'Etkinliğe devam et' : 'Etkinliği duraklat',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            style: IconButton.styleFrom(
              backgroundColor: Colors.orange.withAlpha(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(
              mac.duraklatildi ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: Colors.orange, size: 20,
            ),
            onPressed: () => mac.duraklatildi ? mac.devamEt() : mac.duraklat(),
          ),
          const SizedBox(width: 4),
          // Durdur
          IconButton(
            tooltip: 'Etkinliği bitir',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withAlpha(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: Icon(Icons.stop_rounded, color: Colors.red.shade300, size: 20),
            onPressed: () => _macBitirOnay(context),
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
          const Text("Etkinliği Bitir", style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          "Etkinliği tamamen bitirmek istediğinize emin misiniz? Skorlar sıfırlanacak.",
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
          maxLength: GirdiSiniri.sinifAdi,
          buildCounter: gizliSayac,
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
      builder: (context) {
        String secilenBrans = 'beden_egitimi';
        return StatefulBuilder(
          builder: (context, setLocal) => AlertDialog(
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: c,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: GirdiSiniri.sinifAdi,
                buildCounter: gizliSayac,
                decoration: InputDecoration(
                  hintText: 'Örn: 8/B',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTema.ana, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Branş',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: secilenBrans,
                    isExpanded: true,
                    items: bransSablonlari
                        .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Row(children: [
                                Icon(b.ikon, size: 20, color: AppTema.ana),
                                const SizedBox(width: 10),
                                Text(b.ad, style: const TextStyle(fontWeight: FontWeight.w600)),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => secilenBrans = v ?? 'beden_egitimi'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Builder(builder: (_) {
                final kalemler = bransSablonu(secilenBrans).varsayilanKalemler;
                if (kalemler.isEmpty) {
                  return const Text('Kalem yok — sınıfı oluşturduktan sonra ekleyebilirsin.',
                      style: TextStyle(color: AppTema.metinIkincil, fontSize: 12));
                }
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kalemler
                      .map((k) => Chip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: AppTema.ana50,
                            side: BorderSide.none,
                            avatar: Icon(kalemIkonu(k.ikon), size: 16, color: AppTema.ana),
                            label: Text(
                              k.tip == KalemTipi.sayac ? '${k.ad} (sayaç)' : k.ad,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList(),
                );
              }),
              const SizedBox(height: 4),
              const Text('Bu kalemleri sonra değiştirebilirsin.',
                  style: TextStyle(color: AppTema.metinIkincil, fontSize: 12)),
            ],
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
                await _db.sinifEkle(ad, brans: secilenBrans);
                unawaited(AnalyticsService.sinifOlusturuldu());
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
      },
    ).then((_) => c.dispose());
  }

  // 8 palet + `ad.hashCode % 8` ile 5-6 sınıfta bile aynı renk iki kez
  // düşebiliyordu (listede iki turuncu, iki mor yan yana). Havuz 12'ye
  // çıkarıldı — çakışma olasılığı belirgin düştü.
  static const _sinifPaletleri = [
    [Color(0xFFE94B6A), Color(0xFFFF6B35)], // pembe → turuncu
    [Color(0xFF4A90E2), Color(0xFF50C9C3)], // mavi → turkuaz
    [Color(0xFF00C896), Color(0xFF7FE5C5)], // yeşil → mint
    [Color(0xFF9B59B6), Color(0xFFD16BA5)], // mor → pembe
    [Color(0xFFF5C544), Color(0xFFFF8C42)], // sarı → turuncu
    [Color(0xFF26A69A), Color(0xFF4DB6AC)], // teal
    [Color(0xFFEF5350), Color(0xFFEC407A)], // kırmızı
    [Color(0xFF5C6BC0), Color(0xFF7986CB)], // indigo
    [Color(0xFF7E57C2), Color(0xFFB39DDB)], // menekşe
    [Color(0xFF0288D1), Color(0xFF4FC3F7)], // gök mavisi
    [Color(0xFF8D6E63), Color(0xFFBCAAA4)], // kahve
    [Color(0xFF43A047), Color(0xFF9CCC65)], // çim yeşili
  ];

  List<Color> _sinifPaleti(String ad) {
    return _sinifPaletleri[ad.hashCode.abs() % _sinifPaletleri.length];
  }

  static const _renkSecenekleri = AppTema.formaRenkAdlari;

  Color _renkBul(String renkAdi) => AppTema.formaRengi(renkAdi);

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
            const Text("Sınıflar Arası Yarışma", style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Sınıf 1
            _macSinifSecici("Ev Sahibi", siniflar, sinif1Id!, renk1, (id) => setDialogState(() => sinif1Id = id), (r) => setDialogState(() => renk1 = r)),
            const SizedBox(height: 8),
            const Text("VS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTema.metinIkincil)),
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
                backgroundColor: AppTema.panelKoyu1, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.sports_rounded, size: 20),
              onPressed: () async {
                if (sinif1Id == sinif2Id) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: const Text("Aynı sınıfı seçemezsiniz."),
                    backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                  return;
                }
                // Süren etkinlik onaysız eziliyordu (denetim O2).
                if (MacDurumu().aktif) {
                  final onay = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text('Süren etkinlik silinsin mi?'),
                      content: const Text('Devam eden etkinliğin skoru ve süresi silinip yarışma başlatılacak.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: TextButton.styleFrom(foregroundColor: AppTema.tehlike),
                          child: const Text('Yarışmayı başlat'),
                        ),
                      ],
                    ),
                  );
                  if (onay != true) return;
                }
                // Diyalog hata durumunda ("hazır öğrenci yok") açık kalır;
                // eskiden kapanıp kullanıcıyı baştan seçtiriyordu (denetim O8).
                final basladi = await _siniflarArasiMacBaslat(sinif1Id!, sinif2Id!, renk1, renk2,
                  siniflar.firstWhere((s) => s['id'] == sinif1Id)['ad'] as String,
                  siniflar.firstWhere((s) => s['id'] == sinif2Id)['ad'] as String,
                );
                if (basladi && ctx.mounted) Navigator.pop(ctx);
              },
              label: const Text("Yarışmayı Başlat", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ).ignore();
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
        Text(etiket, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: secilenId,
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
        // Daireler 28px + 6px aralıkla 8 tanesi satıra sığmıyordu, sonuncusu
        // tek başına alta düşüyordu. Görünen daire 24'e indi ama dokunma
        // alanı 44px'e çıktı (görsel küçüldü, hedef büyüdü).
        Wrap(
          spacing: 0, runSpacing: 0,
          children: _renkSecenekleri.map((r) {
            final secili = r == secilenRenk;
            return Semantics(
              label: r,
              selected: secili,
              button: true,
              child: InkWell(
                onTap: () => onRenkChanged(r),
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 44, height: 44,
                  child: Center(
                    child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: _renkBul(r),
                        shape: BoxShape.circle,
                        border: Border.all(color: secili ? Colors.white : Colors.transparent, width: 2),
                        boxShadow: secili ? [BoxShadow(color: _renkBul(r).withAlpha(120), blurRadius: 6)] : null,
                      ),
                      child: secili ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  Future<bool> _siniflarArasiMacBaslat(String sinif1Id, String sinif2Id, String renk1, String renk2, String ad1, String ad2) async {
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
      return false;
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
    unawaited(AnalyticsService.macBasladi(takimSayisi: 2, oyuncuSayisi: gelenler1.length + gelenler2.length));

    if (mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => SkorEkrani(takimlar: takimlar),
      )).ignore();
    }
    return true;
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
