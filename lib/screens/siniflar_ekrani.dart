import '../tema.dart';
import '../tema_renkleri.dart';
import '../widgets/kalem_simgeleri.dart';
import '../utils/metin.dart';
import '../utils/egitim_yili.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/cikartma.dart';
import '../widgets/girdi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/mac_durumu.dart';
import '../models/kontrol_kalemi.dart';
import '../widgets/yardim_diyalogu.dart';
import '../widgets/yoklama_halkasi.dart';
import '../utils/sinif_ozeti.dart';
import 'ogrenci_listesi_ekrani.dart';
import 'ogrenci_arama_ekrani.dart';
import 'arsiv_sinif_ekrani.dart';
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
  /// Geniş ekranda (iPad yatay, masaüstü) iki sütun: solda sınıflar, sağda
  /// seçili sınıfın öğrencileri (tasarım listesi #5, 2026-09-05).
  static const double _ikiSutunEsigi = 900;
  String? _seciliSinifId;
  String? _seciliSinifAd;

  late final FirestoreService _db = FirestoreService(uid: AuthService().uid);
  bool _migrationYapildi = false;
  /// build() içinde her çizimde yeni Stream kurulup sınıf dokümanları yeniden
  /// okunuyordu; iki sütunda sınıf seçmek bile 5 okuma ediyordu (denetim #3 O2).
  late final Stream<QuerySnapshot> _siniflarAkisi = _db.siniflarStream();
  /// Sol panel geniş/dar geçişinde yeniden mount olup 5 dinleyiciyi
  /// kapatıp açıyordu; GlobalKey durumu korur.
  final _solPanelKey = GlobalKey();

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
  /// Aynı akışa yeniden abone olunca ilk olay gelene kadar veri yok sayılıp
  /// "0 öğrenci" yazılıyordu (denetim #4 Y2); son değer saklanır.
  final Map<String, QuerySnapshot> _sonSayaclar = {};

  /// Sınıf kartındaki yoklama halkasının akışları; sayaçlarla aynı nedenle
  /// sınıf id'sine göre önbelleklenir ve son değer saklanır.
  final Map<String, Stream<QuerySnapshot>> _sonYoklamaAkislari = {};
  final Map<String, QuerySnapshot> _sonYoklamalar = {};

  Stream<QuerySnapshot> _sonYoklamaAkisi(String sinifId) =>
      _sonYoklamaAkislari.putIfAbsent(
          sinifId, () => _db.sonYoklamaStream(sinifId));
  QuerySnapshot? _sonSiniflar;

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
    final r = context.renk;
    return Scaffold(
      backgroundColor: r.sayfa,
      // "Teneffüs": koyu çubuk yerine krem zemin, solda logo; büyük başlık
      // aşağıda (_solPanel).
      appBar: AppBar(
        title: Semantics(
          label: 'Sınıflarım',
          excludeSemantics: true,
          child: Container(
            width: 44, height: 44,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: r.kenar, width: 2.5),
            ),
            child: Image.asset('assets/images/logo_256.png'),
          ),
        ),
        centerTitle: false,
        backgroundColor: r.sayfa,
        foregroundColor: r.metin,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          // Demo modu yalnız admin'e çiziliyordu; tanıtım, yardım, mağaza
          // metni ve gizlilik politikası herkese vaat ediyordu (denetim #4 K4).
          ...[
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
                  backgroundColor: DemoModu.aktif ? AppTema.uyari : AppTema.basari,
                ));
              },
            ),
            if (AuthService().isAdmin) IconButton(
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
                  aciklama: 'Sağ alttaki "Sınıf Ekle" düğmesi → sınıf adı yaz (örn. 7-A) ve branşını seç. Kontrol kalemleri (forma, kitap, boya…) branşa göre hazır gelir; takım renkleri de otomatik atanır.',
                  renk: Color(0xFF43A047),
                ),
                YardimBolumu(
                  ikon: Icons.touch_app_rounded,
                  baslik: 'Sınıfa giriş',
                  aciklama: 'Sınıf kartına dokun → o sınıfın öğrenci listesi açılır. Yoklama alabilir, öğrenci ekleyebilir, takım kurup oyun başlatabilirsin. Sınıflarım ekranındaki göz simgesi demo modunu açar: öğrenci adları sahte isimlerle gösterilir (sunum ve ekran görüntüsü için).',
                  renk: Color(0xFF1976D2),
                ),
                YardimBolumu(
                  ikon: Icons.sports_kabaddi_rounded,
                  baslik: 'Sınıflar Arası Yarışma',
                  aciklama: 'Sağ alttaki kupa düğmesi: iki sınıfı karşı karşıya getir (örn. 7-A ile 7-B) — maç, bilgi yarışması, münazara… Her sınıf bir takım olur, skor tablosu açılır.',
                  renk: Color(0xFFC77B46),
                ),
                YardimBolumu(
                  ikon: Icons.edit_rounded,
                  baslik: 'Sınıf adı değiştir / sil',
                  aciklama: 'Sınıf kartını sola kaydır → "İsmi Düzenle" ya da "Sınıfı Sil". Silme geri alınamaz; Firestore yedeği yoksa geri getirilemez.',
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
      body: LayoutBuilder(builder: (context, c) {
        final ikiSutun = c.maxWidth >= _ikiSutunEsigi;
        final sol = KeyedSubtree(key: _solPanelKey, child: _solPanel(context, ikiSutun));
        if (!ikiSutun) return sol;
        return Row(children: [
          // FAB'lar geniş ekranda sağ sütunun alt çubuğuna biniyordu;
          // sol sütunun içinde kalıyorlar.
          SizedBox(
            width: 380,
            child: Stack(children: [
              sol,
              Positioned(right: 16, bottom: 16, child: _fabSutunu(context)),
            ]),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _seciliSinifId == null
                ? _sagBosDurum()
                : OgrenciListesiEkrani(
                    key: ValueKey(_seciliSinifId),
                    sinifId: _seciliSinifId!,
                    sinifAd: _seciliSinifAd,
                    gomulu: true,
                  ),
          ),
        ]);
      }),
      floatingActionButton: MediaQuery.sizeOf(context).width >= _ikiSutunEsigi ? null : _fabSutunu(context),
    );
  }


  Widget _solPanel(BuildContext context, bool ikiSutun) {
    final r = context.renk;
    return Column(
        children: [
          // Büyük başlık: tarih ve hesap altında.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sınıfların',
                    style: TextStyle(
                        fontFamily: AppTema.baslikFontu, fontSize: 36, fontWeight: FontWeight.w700, color: r.metin, height: 1.1)),
                const SizedBox(height: 2),
                Text(
                  [
                    DateFormat('d MMMM EEEE', 'tr').format(DateTime.now()),
                    if ((AuthService().currentUser?.email ?? '').isNotEmpty) AuthService().currentUser!.email!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: r.metinIkincil, fontSize: 14, fontWeight: FontWeight.w600),
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
              stream: _siniflarAkisi,
              initialData: _sonSiniflar,
              builder: (context, snapshot) {
                if (snapshot.hasData) _sonSiniflar = snapshot.data;
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: r.koyuMu ? r.tehlike : Colors.red.shade300),
                          const SizedBox(height: 12),
                          Text(FirestoreService.hataMesaji(snapshot.error!), textAlign: TextAlign.center,
                              style: TextStyle(color: r.koyuMu ? r.tehlike : Colors.red.shade700)),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: r.vurgu));
                }
                if (snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.class_outlined, size: 72, color: r.bosDurumIkonu),
                          const SizedBox(height: 16),
                          Text("Hoş geldin! 👋",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: r.koyuMu ? r.metinIkincil : Colors.grey.shade600)),
                          const SizedBox(height: 6),
                          Text("Üç adımda hazırsın:",
                              style: TextStyle(color: r.metinIkincil)),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: r.kart,
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
                    child: Builder(builder: (context) {
                      // Doküman kimliğine göre rastgele geliyordu (denetim #4 D3).
                      final docs = List<QueryDocumentSnapshot>.from(snapshot.data!.docs)
                        ..sort((a, b) => trKarsilastir(
                            ((a.data() as Map?)?['ad'] ?? '').toString(),
                            ((b.data() as Map?)?['ad'] ?? '').toString()));
                      // Ana listede yalnız bu yılın sınıfları; eskiler en
                      // altta katlanmış "Geçmiş Yıllar"da.
                      final aktif = docs.where(_buYilin).toList();
                      final gecmis = docs.where((d) => !_buYilin(d)).toList();
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                        children: [
                          if (aktif.isEmpty) _yeniYilKarti(),
                          for (var i = 0; i < aktif.length; i++)
                            _sinifKarti(context, aktif[i], ikiSutun,
                                AppTema.sinifRenkleri[i % AppTema.sinifRenkleri.length]),
                          if (gecmis.isNotEmpty) _gecmisYillar(context, gecmis),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      );
  }


  // İki genişletilmiş FAB alt alta durunca etiket uzunlukları farklı
  // olduğu için sol kenarları kademeli görünüyordu ve ikisi de aynı
  // görsel ağırlıktaydı. İkincil eylem artık küçük ikon-FAB.
  Widget _fabSutunu(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SertGolgeli(
            daire: true,
            kayma: 3,
            child: FloatingActionButton(
              heroTag: 'mac',
              onPressed: () => _siniflarArasiMacDialog(context),
              backgroundColor: const Color(0xFFFFD84D),
              foregroundColor: AppTema.ana,
              shape: const CircleBorder(side: BorderSide(color: AppTema.ana, width: 2.5)),
              tooltip: 'Sınıflar Arası Yarışma',
              child: const Icon(Icons.emoji_events_rounded, size: 28),
            ),
          ),
          const SizedBox(height: 12),
          SertGolgeli(
            child: FloatingActionButton.extended(
              heroTag: 'ekle',
              onPressed: () => _sinifEkle(context),
              icon: const Icon(Icons.add_rounded, size: 26),
              label: const Text("Sınıf Ekle"),
            ),
          ),
        ],
      );
  }

  Widget _sagBosDurum() {
    final r = context.renk;
    return Container(
      color: r.sayfa,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.touch_app_outlined, size: 64, color: r.bosDurumIkonu),
          const SizedBox(height: 14),
          Text('Soldan bir sınıf seç',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: r.metinIkincil)),
          const SizedBox(height: 6),
          Text('Öğrenciler, yoklama ve takım kurma burada açılır.',
              style: TextStyle(color: r.metinUcuncul)),
        ]),
      ),
    );
  }

  /// Boş durum kartındaki tek bir adım satırı (1-2-3 yönlendirmesi).
  Widget _bosAdim(int no, IconData ikon, String baslik, String aciklama) {
    final r = context.renk;
    return Row(children: [
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: r.vurgu.withAlpha(25), shape: BoxShape.circle),
        child: Center(
          child: Text("$no", style: TextStyle(color: r.metinGovde, fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(baslik, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text(aciklama, style: TextStyle(color: r.metinIkincil, fontSize: 12)),
        ]),
      ),
      Icon(ikon, color: r.bosDurumIkonu, size: 22),
    ]);
  }

  Widget _sinifKarti(BuildContext context, QueryDocumentSnapshot doc, bool ikiSutun, Color renk) {
    final data = doc.data() as Map<String, dynamic>?;
    final ad = data?['ad'] ?? doc.id;
    final docId = doc.id;
    final secili = ikiSutun && _seciliSinifId == docId;
    final r = context.renk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: ctx.renk.cizgi, borderRadius: BorderRadius.circular(2))),
                    ListTile(
                      leading: Icon(Icons.edit_rounded, color: ctx.renk.ikonAna),
                      title: const Text("İsmi Düzenle"),
                      onTap: () => Navigator.pop(ctx, 'duzenle'),
                    ),
                    ListTile(
                      leading: Icon(Icons.inventory_2_rounded, color: ctx.renk.ikonAna),
                      title: Text("Geçmiş Yıla Taşı (${EgitimYili.onceki(EgitimYili.simdiki)})"),
                      subtitle: const Text("Ana listeden kalkar, öğrencileri silinmez"),
                      onTap: () => Navigator.pop(ctx, 'arsiv'),
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_rounded, color: ctx.renk.koyuMu ? ctx.renk.tehlike : Colors.red.shade600),
                      title: Text("Sınıfı Sil", style: TextStyle(fontWeight: FontWeight.w600, color: ctx.renk.koyuMu ? ctx.renk.tehlike : Colors.red.shade600)),
                      onTap: () => Navigator.pop(ctx, 'sil'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
            if (result == 'duzenle') {
              if (context.mounted) _sinifAdiniDuzenle(context, docId, ad);
            } else if (result == 'arsiv') {
              if (context.mounted) unawaited(_arsiveTasi(context, docId, ad));
            } else if (result == 'sil') {
              if (context.mounted) _sinifSilOnay(context, docId, ad);
            }
            return false;
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(right: 4, bottom: 4),
            decoration: BoxDecoration(
              color: r.cizgi,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.more_horiz_rounded, color: r.koyuMu ? r.metinGovde : Colors.grey.shade700, size: 28),
          ),
          // Sınıfın rengi; seçili kart (iki sütun) kalın kenarla belli olur.
          child: Cikartma(
            renk: renk,
            kenarRengi: AppTema.ana,
            kenarKalinligi: secili ? 4 : 2.5,
            kayma: secili ? 6 : 4,
            dolgu: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            onTap: () {
              if (ikiSutun) {
                setState(() { _seciliSinifId = docId; _seciliSinifAd = ad; });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OgrenciListesiEkrani(sinifId: docId, sinifAd: ad)),
                );
              }
            },
            child: Row(
              children: [
                Expanded(child: _sinifOzeti(docId, ad, secili)),
                const Icon(Icons.chevron_right_rounded, color: AppTema.ana, size: 28),
              ],
            ),
          ),
      ),
    );
  }

  /// Kartın solu ve ortası: yoklama halkası, sınıf adı, son yoklama özeti.
  /// Öğrenci listesi (mevcut) ile son yoklama dokümanı birlikte okunur.
  Widget _sinifOzeti(String docId, String ad, bool secili) {
    final kisaltma = sinifKisaltmasi(ad);
    return StreamBuilder<QuerySnapshot>(
      stream: _ogrenciSayisiAkisi(docId),
      initialData: _sonSayaclar[docId],
      builder: (context, ogrSnap) {
        if (ogrSnap.hasData) _sonSayaclar[docId] = ogrSnap.data!;
        return StreamBuilder<QuerySnapshot>(
          stream: _sonYoklamaAkisi(docId),
          initialData: _sonYoklamalar[docId],
          builder: (context, yokSnap) {
            if (yokSnap.hasData) _sonYoklamalar[docId] = yokSnap.data!;
            final ogrenciIdleri =
                ogrSnap.hasData ? ogrSnap.data!.docs.map((d) => d.id).toList() : const <String>[];
            final count = ogrenciIdleri.length;
            final bos = ogrSnap.hasData && count == 0;
            final yoklamaDoc = (yokSnap.hasData && yokSnap.data!.docs.isNotEmpty)
                ? yokSnap.data!.docs.first
                : null;
            final ozet = yoklamaDoc == null
                ? null
                : yoklamaOzeti({
                    'tarih': yoklamaDoc.id,
                    ...?(yoklamaDoc.data() as Map<String, dynamic>?),
                  }, ogrenciIdleri);
            final gunEtiketi =
                ozet == null ? null : yoklamaGunEtiketi(ozet.tarih, DateTime.now());

            final Widget alt;
            final String semantik;
            if (bos) {
              // Boş sınıf listede diğerleriyle aynı görünüyordu;
              // öğretmeni bir sonraki adıma yönlendir.
              alt = Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.person_add_alt_rounded, size: 15, color: AppTema.ana),
                const SizedBox(width: 5),
                Text("Öğrenci ekle",
                    style: const TextStyle(color: AppTema.ana, fontSize: 14, fontWeight: FontWeight.w800)),
              ]);
              semantik = "$ad, öğrenci yok";
            } else if (ozet == null || count == 0) {
              // Akış gelmeden "0 öğrenci" yazıyordu (denetim #3 doğrulaması).
              final metin = !ogrSnap.hasData
                  ? "…"
                  : yokSnap.hasData
                      ? "$count öğrenci · yoklama alınmadı"
                      : "$count öğrenci";
              alt = Text(metin, style: const TextStyle(color: AppTema.ana, fontSize: 14, fontWeight: FontWeight.w700));
              semantik = "$ad, $metin";
            } else {
              final metin = "${ozet.gelen} / ${ozet.toplam} geldi · $gunEtiketi";
              alt = Text(metin, style: const TextStyle(color: AppTema.ana, fontSize: 14, fontWeight: FontWeight.w700));
              semantik = "$ad, $gunEtiketi ${ozet.gelen} / ${ozet.toplam} geldi";
            }

            return Row(
              children: [
                // Renkli kartta halka beyaz yuvarlağın içinde.
                Container(
                  width: 62, height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTema.ana, width: 2.5),
                  ),
                  child: YoklamaHalkasi(
                    kisaltma: kisaltma,
                    oran: ozet?.oran,
                    bos: bos,
                    secili: secili,
                    semantik: semantik,
                    renkler: CemberRenkleri.acik,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ad,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: AppTema.baslikFontu, fontSize: 22, fontWeight: FontWeight.w600, color: AppTema.ana, height: 1.15)),
                      const SizedBox(height: 4),
                      alt,
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _macBanner(BuildContext context) {
    final mac = MacDurumu();
    // "Teneffüs": limon sarısı bilet.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Cikartma(
      renk: const Color(0xFFFFD84D),
      kenarRengi: AppTema.ana,
      yaricap: 18,
      dolgu: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(mac.duraklatildi ? Icons.pause_circle_rounded : Icons.timer_rounded, color: AppTema.ana, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: '${mac.duraklatildi ? "Etkinlik duraklatıldı" : "Etkinlik devam ediyor"}, etkinliğe dönmek için dokun',
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // Şerit sınıf listesini açıyor, orada ikinci bir "Devam Et"
                  // gerekiyordu (denetim #4 O3); doğrudan skor tablosu.
                  if (mac.takimlar != null) {
                    Navigator.push<String>(context, MaterialPageRoute(
                      builder: (_) => SkorEkrani(takimlar: mac.takimlar!),
                    )).then((sonuc) {
                      if (sonuc != 'geridon') MacDurumu().macBitir();
                      (context as Element).markNeedsBuild();
                    });
                  }
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      mac.duraklatildi ? "Etkinlik duraklatıldı" : "Etkinlik sürüyor",
                      style: const TextStyle(
                          color: AppTema.ana, fontFamily: AppTema.baslikFontu, fontWeight: FontWeight.w600, fontSize: 18),
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
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTema.ana, width: 2),
            ),
            icon: Icon(
              mac.duraklatildi ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: AppTema.ana, size: 22,
            ),
            onPressed: () => mac.duraklatildi ? mac.devamEt() : mac.duraklat(),
          ),
          const SizedBox(width: 8),
          // Durdur
          IconButton(
            tooltip: 'Etkinliği bitir',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            style: IconButton.styleFrom(
              backgroundColor: AppTema.ana,
              side: const BorderSide(color: AppTema.ana, width: 2),
            ),
            icon: const Icon(Icons.stop_rounded, color: Colors.white, size: 22),
            onPressed: () => _macBitirOnay(context),
          ),
        ],
      ),
    ),
    );
  }

  void _macBitirOnay(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: ctx.renk.koyuMu ? ctx.renk.tehlikeZemin : Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.stop_rounded, color: ctx.renk.koyuMu ? ctx.renk.tehlike : Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          const Text("Etkinliği Bitir", style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          "Etkinliği tamamen bitirmek istediğine emin misin? Skorlar sıfırlanacak.",
          style: TextStyle(color: ctx.renk.koyuMu ? ctx.renk.metinGovde : Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal", style: TextStyle(color: ctx.renk.koyuMu ? ctx.renk.metinIkincil : Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.renk.silDolgu, foregroundColor: Colors.white,
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ctx.renk.yuzeyAna,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_rounded, color: ctx.renk.ikonAna),
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
              borderSide: BorderSide(color: ctx.renk.koyuMu ? ctx.renk.vurgu : ctx.renk.ikonAna, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: ctx.renk.koyuMu ? ctx.renk.metinIkincil : Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.renk.vurgu,
              foregroundColor: ctx.renk.vurguMetin,
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.renk.yuzeyAna,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_rounded, color: context.renk.ikonAna),
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
                    borderSide: BorderSide(color: context.renk.koyuMu ? context.renk.vurgu : context.renk.ikonAna, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Branş',
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.renk.koyuMu ? context.renk.metinGovde : Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: context.renk.cizgi),
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
                                Icon(b.ikon, size: 20, color: context.renk.ikonAna),
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
                  return Text('Kalem yok — sınıfı oluşturduktan sonra ekleyebilirsin.',
                      style: TextStyle(color: context.renk.metinIkincil, fontSize: 12));
                }
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kalemler
                      .map((k) => Chip(
                            visualDensity: VisualDensity.compact,
                            backgroundColor: context.renk.yuzeyAna,
                            side: BorderSide.none,
                            avatar: KalemSimgesi(k.ikon, size: 16, color: context.renk.ikonAna),
                            label: Text(
                              k.tip == KalemTipi.sayac ? '${k.ad} (sayaç)' : k.ad,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ))
                      .toList(),
                );
              }),
              const SizedBox(height: 4),
              Text('Bu kalemleri sonra değiştirebilirsin.',
                  style: TextStyle(color: context.renk.metinIkincil, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: context.renk.koyuMu ? context.renk.metinIkincil : Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.renk.vurgu,
              foregroundColor: context.renk.vurguMetin,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (c.text.trim().isEmpty) return;
              final ad = trBuyut(c.text).trim();
              // Aynı adla ikinci sınıf uyarısız oluşuyordu (denetim #4 O8).
              // Yalnız bu yıl: geçen yılın 7E'si varken bu yıl yeni bir 7E
              // açılabilmeli.
              final mevcut = _sonSiniflar?.docs.any((d) => _buYilin(d) &&
                      trKucult(((d.data() as Map?)?['ad'] ?? '').toString()) == trKucult(ad)) ??
                  false;
              if (mevcut) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('"$ad" adında bir sınıfın zaten var. Farklı bir ad seç.'),
                  backgroundColor: AppTema.uyari,
                ));
                return;
              }
              Navigator.pop(context);
              try {
                await _db.sinifEkle(ad, brans: secilenBrans);
                unawaited(AnalyticsService.sinifOlusturuldu());
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Sınıf eklenemedi. ${FirestoreService.hataMesaji(e)}"),
                    backgroundColor: AppTema.tehlike,
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

  static const _renkSecenekleri = AppTema.formaRenkAdlari;

  Color _renkBul(String renkAdi) => AppTema.formaRengi(renkAdi);

  void _siniflarArasiMacDialog(BuildContext context) async {
    final snapshot = await _db.siniflarGetir();
    // Yarışma yalnız bu yılın sınıfları arasında.
    final buYil = snapshot.docs.where(_buYilin).toList();
    if (buYil.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("En az 2 sınıf gerekli."),
          backgroundColor: AppTema.tehlike, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      return;
    }

    final siniflar = buYil.map((d) {
      final data = d.data() as Map<String, dynamic>?;
      return {'id': d.id, 'ad': data?['ad'] ?? d.id};
    }).toList()
      ..sort((a, b) => trKarsilastir(a['ad'].toString(), b['ad'].toString()));

    String? sinif1Id = siniflar[0]['id'] as String;
    String? sinif2Id = siniflar[1]['id'] as String;
    String renk1 = 'Kırmızı';
    String renk2 = 'Mavi';

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: ctx.renk.koyuMu ? ctx.renk.yuzeyAna : Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.sports_rounded, color: ctx.renk.koyuMu ? ctx.renk.ikonAna : Colors.indigo),
            ),
            const SizedBox(width: 12),
            const Text("Sınıflar Arası Yarışma", style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            // Sınıf 1
            _macSinifSecici("Ev Sahibi", siniflar, sinif1Id!, renk1, (id) => setDialogState(() => sinif1Id = id), (r) => setDialogState(() => renk1 = r)),
            const SizedBox(height: 8),
            Text("VS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: ctx.renk.metinIkincil)),
            const SizedBox(height: 8),
            // Sınıf 2
            _macSinifSecici("Deplasman", siniflar, sinif2Id!, renk2, (id) => setDialogState(() => sinif2Id = id), (r) => setDialogState(() => renk2 = r)),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("İptal", style: TextStyle(color: ctx.renk.koyuMu ? ctx.renk.metinIkincil : Colors.grey.shade600)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTema.panelKoyu1, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.sports_rounded, size: 20),
              onPressed: () async {
                if (sinif1Id == sinif2Id) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: const Text("Aynı sınıfı iki kez seçemezsin."),
                    backgroundColor: AppTema.tehlike, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                  return;
                }
                // Süren etkinlik onaysız eziliyordu (denetim O2).
                if (MacDurumu().aktif) {
                  final onay = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      title: const Text('Süren etkinlik silinsin mi?'),
                      content: const Text('Devam eden etkinliğin skoru ve süresi silinip yarışma başlatılacak.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: TextButton.styleFrom(foregroundColor: c.renk.tehlike),
                          child: const Text('Yarışmayı başlat'),
                        ),
                      ],
                    ),
                  );
                  if (onay != true) return;
                }
                // Diyalog hata durumunda ("hazır öğrenci yok") açık kalır;
                // eskiden kapanıp kullanıcıyı baştan seçtiriyordu (denetim O8).
                final takimlar = await _siniflarArasiMacBaslat(sinif1Id!, sinif2Id!, renk1, renk2,
                  siniflar.firstWhere((s) => s['id'] == sinif1Id)['ad'] as String,
                  siniflar.firstWhere((s) => s['id'] == sinif2Id)['ad'] as String,
                );
                if (takimlar == null) return;
                // Skor ekranı push edildikten SONRA diyaloğu kapatmak en
                // üstteki rotayı, yani skor ekranını kapatıyordu (denetim #4
                // K3). Önce diyalog, sonra skor.
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  unawaited(Navigator.push<String>(context, MaterialPageRoute(
                    builder: (_) => SkorEkrani(takimlar: takimlar),
                  )).then((sonuc) {
                    if (sonuc != 'geridon') MacDurumu().macBitir();
                  }));
                }
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
        Text(etiket, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.renk.koyuMu ? context.renk.metinIkincil : Colors.grey.shade600)),
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

  Future<List<TakimBilgi>?> _siniflarArasiMacBaslat(String sinif1Id, String sinif2Id, String renk1, String renk2, String ad1, String ad2) async {
    final ogrenciler1 = await _db.ogrencileriGetir(sinif1Id);
    final ogrenciler2 = await _db.ogrencileriGetir(sinif2Id);

    final gelenler1 = ogrenciler1.where((o) => o.buradaMi).toList();
    final gelenler2 = ogrenciler2.where((o) => o.buradaMi).toList();

    if (gelenler1.isEmpty || gelenler2.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${gelenler1.isEmpty ? ad1 : ad2} sınıfında hazır öğrenci yok."),
          backgroundColor: AppTema.tehlike, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      return null;
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
    return takimlar;
  }

  bool _buYilin(QueryDocumentSnapshot d) =>
      EgitimYili.sinifin(d.data() as Map<String, dynamic>?).compareTo(EgitimYili.simdiki) >= 0;

  Future<void> _arsiveTasi(BuildContext context, String sinifId, String sinifAdi) async {
    final yil = EgitimYili.onceki(EgitimYili.simdiki);
    try {
      if (MacDurumu().sinifId == sinifId) MacDurumu().macBitir();
      await _db.sinifEgitimYiliniGuncelle(sinifId, yil);
      if (_seciliSinifId == sinifId && mounted) {
        setState(() { _seciliSinifId = null; _seciliSinifAd = null; });
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$sinifAdi, $yil arşivine taşındı."),
        action: SnackBarAction(
          label: 'Geri Al',
          onPressed: () => _db.sinifEgitimYiliniGuncelle(sinifId, EgitimYili.simdiki),
        ),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Taşınamadı. ${FirestoreService.hataMesaji(e)}"),
        backgroundColor: AppTema.tehlike,
      ));
    }
  }

  /// Bu yıl henüz sınıf yokken (ama geçmiş yıllar varken) gösterilir.
  Widget _yeniYilKarti() {
    final r = context.renk;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Cikartma(
      renk: r.vurguZemin,
      dolgu: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.auto_awesome_rounded, color: r.vurguKoyu),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${EgitimYili.simdiki} eğitim yılı",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: r.vurguKoyu)),
            const SizedBox(height: 4),
            Text(
                "Bu yılın sınıflarını + ile ekle. Geçen yılın öğrencilerini her sınıfta ⋮ menüsünden \"Geçen Yıldan Ekle\" ile seçerek aktarabilirsin.",
                style: TextStyle(fontSize: 13, color: r.metin, height: 1.4)),
          ]),
        ),
      ]),
    ),
    );
  }

  /// Geçmiş yılların sınıfları, yıla göre gruplu ve katlanmış.
  Widget _gecmisYillar(BuildContext context, List<QueryDocumentSnapshot> gecmis) {
    final yillar = <String, List<QueryDocumentSnapshot>>{};
    for (final d in gecmis) {
      yillar.putIfAbsent(EgitimYili.sinifin(d.data() as Map<String, dynamic>?), () => []).add(d);
    }
    final sirali = yillar.keys.toList()..sort((a, b) => b.compareTo(a));
    final r = context.renk;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Cikartma(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(Icons.inventory_2_rounded, color: r.ikonAna),
            title: Text("Geçmiş Yıllar", style: TextStyle(fontWeight: FontWeight.w700, color: r.metin)),
            subtitle: Text("${gecmis.length} sınıf · salt okunur",
                style: TextStyle(fontSize: 12, color: r.metinIkincil)),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            children: [
              for (final yil in sirali) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                  child: Row(children: [
                    Expanded(
                      child: Text(yil,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: r.metinUcuncul)),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: r.tehlike),
                      onPressed: () => _yilArsiviniSilOnay(context, yil, yillar[yil]!),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text("Yılı Sil"),
                    ),
                  ]),
                ),
                for (final d in yillar[yil]!) _arsivSatiri(context, d, yil),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _arsivSatiri(BuildContext context, QueryDocumentSnapshot d, String yil) {
    final ad = ((d.data() as Map?)?['ad'] ?? d.id).toString();
    return ListTile(
      dense: true,
      leading: Icon(Icons.groups_rounded, color: context.renk.koyuMu ? context.renk.metinUcuncul : Colors.grey.shade500),
      title: Text(ad, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: context.renk.ikonPasif),
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ArsivSinifEkrani(sinifId: d.id, sinifAd: ad, egitimYili: yil),
      )),
    );
  }

  /// KVKK: eski öğrenci verisi gerektiğinden uzun tutulmamalı; bir yılın
  /// arşivi tek seferde silinebilir.
  void _yilArsiviniSilOnay(BuildContext context, String yil, List<QueryDocumentSnapshot> siniflar) {
    bool siliniyor = false;
    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dctx, setDState) => AlertDialog(
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: dctx.renk.koyuMu ? dctx.renk.tehlikeZemin : Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.delete_forever_rounded, color: dctx.renk.koyuMu ? dctx.renk.tehlike : Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text("$yil silinsin mi?", style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          content: Text(
              "$yil arşivindeki ${siniflar.length} sınıf, öğrencileri ve yoklama geçmişiyle birlikte kalıcı olarak silinecek. "
              "Bu yıla aktardığın öğrenciler etkilenmez.\n\nBu işlem geri alınamaz.",
              style: TextStyle(color: dctx.renk.koyuMu ? dctx.renk.metinGovde : Colors.grey.shade700, height: 1.5)),
          actions: [
            TextButton(
              onPressed: siliniyor ? null : () => Navigator.pop(dctx),
              child: Text("İptal", style: TextStyle(color: dctx.renk.koyuMu ? dctx.renk.metinIkincil : Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dctx.renk.silDolgu,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: siliniyor
                  ? null
                  : () async {
                      setDState(() => siliniyor = true);
                      var silinen = 0;
                      for (final d in siniflar) {
                        try {
                          await _db.sinifSil(d.id);
                          silinen++;
                        } catch (_) {
                          break;
                        }
                      }
                      if (dctx.mounted) Navigator.pop(dctx);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(silinen == siniflar.length
                            ? "$yil arşivi silindi."
                            : "$silinen / ${siniflar.length} sınıf silindi. Bağlantı gerekiyor; kalanlar için tekrar dene."),
                        backgroundColor: silinen == siniflar.length ? null : AppTema.tehlike,
                      ));
                    },
              child: siliniyor
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Evet, Sil", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _sinifSilOnay(BuildContext context, String sinifId, String sinifAdi) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.renk.koyuMu ? context.renk.tehlikeZemin : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, color: context.renk.koyuMu ? context.renk.tehlike : Colors.red.shade700),
            ),
            const SizedBox(width: 12),
            const Text("Sınıfı Sil", style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          "$sinifAdi sınıfını ve tüm öğrencilerini silmek istediğine emin misin?\n\nBu işlem geri alınamaz.",
          style: TextStyle(color: context.renk.koyuMu ? context.renk.metinGovde : Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal", style: TextStyle(color: context.renk.koyuMu ? context.renk.metinIkincil : Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.renk.silDolgu,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              try {
                // Silinen sınıfın maçı bandda kalıyordu (denetim #3 O5).
                if (MacDurumu().sinifId == sinifId) MacDurumu().macBitir();
                await _db.sinifSil(sinifId);
                if (context.mounted) Navigator.pop(context);
              } catch (_) {
                // Sunucudan okunamadı (çevrimdışı): yetim veri bırakmamak
                // için silme hiç başlamıyor (denetim #3 Y4).
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Sınıf silinemedi. Bağlantı gerekiyor; tekrar dene.'),
                    backgroundColor: AppTema.tehlike,
                  ));
                }
              }
            },
            child: const Text("Evet, Sil", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
