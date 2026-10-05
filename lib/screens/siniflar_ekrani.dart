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
import '../widgets/yoklama_halkasi.dart';
import '../widgets/ziplayan_logo.dart';
import '../widgets/yenilikler_penceresi.dart';
import '../utils/sinif_ozeti.dart';
import 'ogrenci_listesi_ekrani.dart';
import 'ogrenci_arama_ekrani.dart';
import 'arsiv_sinif_ekrani.dart';
import 'profil_ekrani.dart';
import 'skor_ekrani.dart';

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
  Color? _seciliSinifRenk;

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
      // Çok aboneli: kart yeniden kurulunca (yeni sınıf eklenince, sınıftan
      // geri dönünce) aynı akışa ikinci kez abone olunuyor; tek abonelikli
      // akışta bu hata verip kart yenilenene kadar sayı hiç gelmiyordu.
      _ogrenciSayaclari.putIfAbsent(
          sinifId, () => _db.ogrencilerStream(sinifId).asBroadcastStream());
  /// Aynı akışa yeniden abone olunca ilk olay gelene kadar veri yok sayılıp
  /// "0 öğrenci" yazılıyordu (denetim #4 Y2); son değer saklanır.
  final Map<String, QuerySnapshot> _sonSayaclar = {};

  /// Sınıf kartındaki yoklama halkasının akışları; sayaçlarla aynı nedenle
  /// sınıf id'sine göre önbelleklenir ve son değer saklanır.
  final Map<String, Stream<QuerySnapshot>> _sonYoklamaAkislari = {};
  final Map<String, QuerySnapshot> _sonYoklamalar = {};

  Stream<QuerySnapshot> _sonYoklamaAkisi(String sinifId) =>
      _sonYoklamaAkislari.putIfAbsent(
          sinifId, () => _db.sonYoklamaStream(sinifId).asBroadcastStream());
  QuerySnapshot? _sonSiniflar;

  @override
  void initState() {
    super.initState();
    _migrationKontrol();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) YeniliklerPenceresi.gerekirseGoster(context);
    });
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
    // Maketteki süs daireleri (sağ üstte limon + domates, sol altta lila);
    // dokunmayı engellemez, koyu temada soluk.
    final susOpaklik = r.koyuMu ? 0.35 : 1.0;
    return ColoredBox(
      color: r.sayfa,
      child: Stack(children: [
        Positioned(
          right: -110, top: -120,
          child: IgnorePointer(child: Opacity(opacity: susOpaklik, child: _susDaire(260, const Color(0xFFFFD84D)))),
        ),
        Positioned(
          right: -24, top: 118,
          child: IgnorePointer(child: Opacity(opacity: susOpaklik, child: _susDaire(64, const Color(0xFFFF6B57)))),
        ),
        Positioned(
          left: -120, bottom: -70,
          child: IgnorePointer(child: Opacity(opacity: susOpaklik * 0.45, child: _susDaire(240, const Color(0xFFB794F6)))),
        ),
        Scaffold(
      backgroundColor: Colors.transparent,
      // "Teneffüs": koyu çubuk yerine krem zemin; büyük başlık aşağıda
      // (_solPanel). Küre logonun kendisi küçükte karalamaya dönüyordu
      // (Sabri, 2026-10-04); yerine küçük boy için çizilmiş kalın çizgili
      // simge (assets/images/logo_simge.svg) + yazı.
      // Maketteki gibi: solda logo, sağda yalnız arama ve profil (Sabri,
      // 2026-10-04). Demo, yardım, admin ve çıkış Profil ekranında; dar
      // telefonda simgeler logonun üstüne biniyordu.
      appBar: AppBar(
        toolbarHeight: 68,
        title: Semantics(
          label: 'Çember',
          excludeSemantics: true,
          child: const ZiplayanLogo(),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: r.metin,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        actions: [
          _yuvarlakEylem(Icons.search_rounded, 'Öğrenci ara',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OgrenciAramaEkrani()))),
          const SizedBox(width: 8),
          _yuvarlakEylem(Icons.person_outline_rounded, 'Profilim',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilEkrani()))
                  .then((_) { if (mounted) setState(() {}); })),
          const SizedBox(width: 12),
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
              Positioned(left: 16, right: 16, bottom: 16, child: _fabSutunu(context)),
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
                    renk: _seciliSinifRenk,
                  ),
          ),
        ]);
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: MediaQuery.sizeOf(context).width >= _ikiSutunEsigi
          ? null
          : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _fabSutunu(context)),
    ),
      ]),
    );
  }


  /// Yeni eklenen sınıfın kaydı sunucuya ulaşmadan kart dinlemeye başlayınca
  /// kural izni reddediyor, akış hata verip kapanıyordu: sayı sayfa
  /// yenilenene kadar "…" kalıyordu. Hatada akışı bırakıp biraz sonra yeniden
  /// abone ol.
  final Set<String> _yenilenecek = {};
  void _akisiYenile(Map<String, Stream<QuerySnapshot>> akislar, String docId) {
    final anahtar = '${identityHashCode(akislar)}/$docId';
    if (!_yenilenecek.add(anahtar)) return;
    Future.delayed(const Duration(seconds: 2), () {
      _yenilenecek.remove(anahtar);
      akislar.remove(docId);
      if (mounted) setState(() {});
    });
  }

  Widget _susDaire(double cap, Color renk) =>
      Container(width: cap, height: cap, decoration: BoxDecoration(color: renk, shape: BoxShape.circle));

  Widget _yuvarlakEylem(IconData ikon, String ipucu, VoidCallback onTap) {
    final r = context.renk;
    return IconButton(
      tooltip: ipucu,
      onPressed: onTap,
      icon: Icon(ikon, size: 26),
      style: IconButton.styleFrom(
        minimumSize: const Size(50, 50),
        backgroundColor: r.kart,
        foregroundColor: r.metin,
        side: BorderSide(color: r.kenar, width: 2.5),
      ),
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
                          Icon(Icons.error_outline, size: 48, color: r.tehlike),
                          const SizedBox(height: 12),
                          Text(FirestoreService.hataMesaji(snapshot.error!), textAlign: TextAlign.center,
                              style: TextStyle(color: r.tehlike)),
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
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: r.metinIkincil)),
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
                        // Alttaki kupa + Sınıf Ekle satırı (~84 px) kartları örtmesin.
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                        children: [
                          if (aktif.isEmpty) _yeniYilKarti(),
                          if (aktif.isNotEmpty) _sinifIzgarasi(context, aktif, ikiSutun),
                          if (gecmis.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _gecmisYillar(context, gecmis),
                          ],
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
  /// Sağ altta yalnız Sınıf Ekle; yarışma ızgaranın sonunda bir kart.
  Widget _fabSutunu(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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

  /// Bu yılın sınıfları: maketteki gibi 2 sütunlu kare kartlar (Sabri,
  /// 2026-10-04). Liste kartlarında sola kaydırma vardı; karede işlemler
  /// ⋯ düğmesinde ve basılı tutunca.
  Widget _sinifIzgarasi(BuildContext context, List<QueryDocumentSnapshot> aktif, bool ikiSutun) {
    return LayoutBuilder(builder: (context, c) {
      const aralik = 12.0;
      final w = (c.maxWidth - aralik) / 2;
      return Wrap(
        spacing: aralik,
        runSpacing: aralik,
        children: [
          for (var i = 0; i < aktif.length; i++)
            SizedBox(
              width: w,
              child: _sinifKarti(context, aktif[i], ikiSutun,
                  AppTema.sinifRenkleri[i % AppTema.sinifRenkleri.length], i),
            ),
          // Yarışma, kartların üstünde yüzen kupa yerine ızgaranın sonunda
          // kesik kenarlı boş bir kart (Sabri, 2026-10-04).
          SizedBox(width: w, child: _yarismaKarti(context)),
        ],
      );
    });
  }

  Widget _sinifKarti(BuildContext context, QueryDocumentSnapshot doc, bool ikiSutun, Color renk, int sira) {
    final data = doc.data() as Map<String, dynamic>?;
    final String ad = (data?['ad'] ?? doc.id).toString();
    final docId = doc.id;
    final secili = ikiSutun && _seciliSinifId == docId;
    // Çıkartmalar hafif eğik; sırayla değişen küçük açılar.
    const acilar = [-0.022, 0.016, 0.016, -0.016];
    return Transform.rotate(
      angle: acilar[sira % acilar.length],
      child: Cikartma(
        renk: renk,
        kenarRengi: AppTema.ana,
        kenarKalinligi: secili ? 4 : 2.5,
        kayma: secili ? 6 : 4,
        yaricap: 24,
        onTap: () {
          if (ikiSutun) {
            setState(() { _seciliSinifId = docId; _seciliSinifAd = ad; _seciliSinifRenk = renk; });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OgrenciListesiEkrani(sinifId: docId, sinifAd: ad, renk: renk)),
            );
          }
        },
        onLongPress: () => _sinifIslemleri(context, docId, ad),
        child: SizedBox(
          height: _kartYuksekligi(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 6),
            child: _sinifOzeti(docId, ad, secili),
          ),
        ),
      ),
    );
  }

  /// Büyük yazı ayarında alt yazılar kartın dibinden taşıp kesiliyordu
  /// (denetim #4); kart yazıyla birlikte uzar.
  double _kartYuksekligi(BuildContext context) =>
      172 + (MediaQuery.textScalerOf(context).scale(10) / 10 - 1).clamp(0.0, 1.0) * 110;

  Widget _yarismaKarti(BuildContext context) {
    final r = context.renk;
    return Semantics(
      button: true,
      label: 'Sınıflar Arası Yarışma',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _siniflarArasiMacDialog(context),
          child: CustomPaint(
            painter: _KesikKenar(renk: r.kenar, yaricap: 24),
            child: SizedBox(
              height: _kartYuksekligi(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 56, height: 56,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: const CircleBorder(side: BorderSide(color: AppTema.ana, width: 2.5)),
                      shadows: [BoxShadow(color: r.sertGolge, offset: const Offset(3, 3))],
                    ),
                    child: const Icon(Icons.emoji_events_rounded, size: 30, color: AppTema.ana),
                  ),
                  const SizedBox(height: 12),
                  Text('Sınıflar Arası\nYarışma',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 17, fontWeight: FontWeight.w600, color: r.metin, height: 1.15)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sinifIslemleri(BuildContext context, String docId, String ad) async {
    final result = await showModalBottomSheet<String>(
      barrierLabel: 'Kapat',
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(ad,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 22, fontWeight: FontWeight.w600, color: ctx.renk.metin)),
            ),
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
              leading: Icon(Icons.delete_rounded, color: ctx.renk.tehlike),
              title: Text("Sınıfı Sil", style: TextStyle(fontWeight: FontWeight.w600, color: ctx.renk.tehlike)),
              onTap: () => Navigator.pop(ctx, 'sil'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (result == 'duzenle') {
      _sinifAdiniDuzenle(context, docId, ad);
    } else if (result == 'arsiv') {
      unawaited(_arsiveTasi(context, docId, ad));
    } else if (result == 'sil') {
      _sinifSilOnay(context, docId, ad);
    }
  }

  /// Kare kartın içi: büyük sınıf kodu, yoklama yüzdesi, ad ve durum.
  /// Öğrenci listesi (mevcut) ile son yoklama dokümanı birlikte okunur.
  Widget _sinifOzeti(String docId, String ad, bool secili) {
    // Büyük kod: ad "7-A Yıldızlar" gibi şube koduyla başlıyorsa o kod
    // ("7-A"), geri kalanı başlık; değilse kısaltma ("4. SINIF FUTBOL" → 4SF).
    // "5A" gibi adlarda başlık tekrar yazılmaz.
    final temizAd = ad.trim();
    final kodEslesme = RegExp(r'^(\d{1,2})\s*([-/.]?)\s*([A-ZÇĞİÖŞÜ])(?=\s|$)').firstMatch(trBuyut(temizAd));
    final String kod;
    final String? baslik;
    if (kodEslesme != null) {
      kod = '${kodEslesme[1]}${kodEslesme[2]}${kodEslesme[3]}';
      final kalan = temizAd.substring(kodEslesme.end).trim();
      baslik = kalan.isEmpty ? null : kalan;
    } else {
      kod = sinifKisaltmasi(temizAd);
      baslik = trBuyut(temizAd).replaceAll(RegExp(r'[\s\-/._]+'), '') == kod ? null : temizAd;
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _ogrenciSayisiAkisi(docId),
      initialData: _sonSayaclar[docId],
      builder: (context, ogrSnap) {
        if (ogrSnap.hasData) _sonSayaclar[docId] = ogrSnap.data!;
        if (ogrSnap.hasError) _akisiYenile(_ogrenciSayaclari, docId);
        return StreamBuilder<QuerySnapshot>(
          stream: _sonYoklamaAkisi(docId),
          initialData: _sonYoklamalar[docId],
          builder: (context, yokSnap) {
            if (yokSnap.hasData) _sonYoklamalar[docId] = yokSnap.data!;
            if (yokSnap.hasError) _akisiYenile(_sonYoklamaAkislari, docId);
            final ogrenciIdleri =
                ogrSnap.hasData ? ogrSnap.data!.docs.map((d) => d.id).toList() : const <String>[];
            final count = ogrenciIdleri.length;
            final bos = ogrSnap.hasData && count == 0;
            final yoklamaDoc = (yokSnap.hasData && yokSnap.data!.docs.isNotEmpty)
                ? yokSnap.data!.docs.first
                : null;
            final ozet = yoklamaDoc == null || count == 0
                ? null
                : yoklamaOzeti({
                    'tarih': yoklamaDoc.id,
                    ...?(yoklamaDoc.data() as Map<String, dynamic>?),
                  }, ogrenciIdleri);
            final gunEtiketi =
                ozet == null ? null : yoklamaGunEtiketi(ozet.tarih, DateTime.now());
            // Akış gelmeden "0 öğrenci" yazıyordu (denetim #3 doğrulaması).
            final String alt = !ogrSnap.hasData
                ? "…"
                : bos
                    ? "öğrenci ekle"
                    : ozet == null
                        // "yoklama bekliyor" iki sütunda "yoklama bekli…" diye
                        // kesiliyordu (denetim #4).
                        ? "$count öğrenci · yoklama yok"
                        // Sayı ile "geldi" bölünmez boşlukla bağlı: satır
                        // sığmazsa "geldi" tek başına alta düşmesin, gün
                        // etiketi ayrılsın (Sabri, 2026-10-05).
                        : "$gunEtiketi ${ozet.gelen}/${ozet.toplam}\u00A0geldi";
            final semantik = "$ad, $alt";
            const yazi = AppTema.ana;
            // Kart tek etiketle okunur; ⋯ düğmesi ayrıca ulaşılabilir kalır.
            return Semantics(
              container: true,
              label: semantik,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(kod,
                            style: const TextStyle(
                                fontFamily: AppTema.baslikFontu, fontSize: 44, fontWeight: FontWeight.w700, color: yazi, height: 1.05)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      // Ortada yüzde, çevresinde son yoklamanın halkası;
                      // bugün yoklama yoksa "?" ve boş halka.
                      child: Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: CircleBorder(side: BorderSide(color: AppTema.ana, width: 2.5)),
                        ),
                        child: bos
                            ? const Icon(Icons.person_add_alt_rounded, size: 24, color: yazi)
                            : YoklamaHalkasi(
                                kisaltma: ozet == null ? "?" : "%${(ozet.oran * 100).round()}",
                                oran: ozet?.oran,
                                secili: secili,
                                renkler: CemberRenkleri.acik,
                                yaziBoyutu: ozet == null ? 18 : 13,
                              ),
                      ),
                    ),
                  ])),
                  const Spacer(),
                  if (baslik != null)
                    ExcludeSemantics(child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(baslik,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: AppTema.baslikFontu, fontSize: 18, fontWeight: FontWeight.w600, color: yazi, height: 1.1)),
                    )),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                      child: ExcludeSemantics(child: Text(alt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: yazi, fontSize: 13, fontWeight: FontWeight.w800, height: 1.2))),
                    ),
                    IconButton(
                      // Ekran okuyucuda hepsi aynı "Sınıf işlemleri"ydi.
                      tooltip: '$ad işlemleri',
                      onPressed: () => _sinifIslemleri(context, docId, ad),
                      icon: const Icon(Icons.more_horiz_rounded, color: yazi, size: 24),
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                  ]),
                ],
              ),
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
                  child: Builder(builder: (_) {
                    // Maketteki gibi skor da görünsün: 2 takımda "A 5 – 3 B".
                    final t = mac.takimlar ?? const [];
                    String ad(int i) => t[i].isim.isNotEmpty ? t[i].isim : t[i].renkAdi;
                    final skor = t.length == 2
                        ? "${ad(0)} ${t[0].skor} – ${t[1].skor} ${ad(1)}"
                        : t.isEmpty ? null : "${t.length} takım";
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mac.duraklatildi ? "Etkinlik duraklatıldı" : "Etkinlik sürüyor",
                          style: const TextStyle(color: AppTema.ana, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        if (skor != null)
                          Text(
                            skor,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTema.ana, fontFamily: AppTema.baslikFontu, fontWeight: FontWeight.w600, fontSize: 18, height: 1.15),
                          ),
                      ],
                    );
                  }),
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
            decoration: BoxDecoration(color: ctx.renk.tehlikeZemin, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.stop_rounded, color: ctx.renk.tehlike),
          ),
          const SizedBox(width: 12),
          const Text("Etkinliği Bitir", style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: Text(
          "Etkinliği tamamen bitirmek istediğine emin misin? Skorlar sıfırlanacak.",
          style: TextStyle(color: ctx.renk.metinGovde, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal", style: TextStyle(color: ctx.renk.metinIkincil)),
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
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: TextStyle(color: ctx.renk.metinIkincil)),
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
                ),
              ),
              const SizedBox(height: 18),
              Text('Branş',
                  style: TextStyle(fontWeight: FontWeight.w600, color: context.renk.metinGovde, fontSize: 13)),
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
            child: Text('İptal', style: TextStyle(color: context.renk.metinIkincil)),
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
              decoration: BoxDecoration(color: ctx.renk.yuzeyAna, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.sports_rounded, color: ctx.renk.ikonAna),
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
              child: Text("İptal", style: TextStyle(color: ctx.renk.metinIkincil)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
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
        Text(etiket, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.renk.metinIkincil)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: secilenId,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      leading: Icon(Icons.groups_rounded, color: context.renk.metinUcuncul),
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
                color: context.renk.tehlikeZemin,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded, color: context.renk.tehlike),
            ),
            const SizedBox(width: 12),
            const Text("Sınıfı Sil", style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          "$sinifAdi sınıfını ve tüm öğrencilerini silmek istediğine emin misin?\n\nBu işlem geri alınamaz.",
          style: TextStyle(color: context.renk.metinGovde, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal", style: TextStyle(color: context.renk.metinIkincil)),
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

/// Yarışma kartının kesik çizgili yuvarlak köşeli kenarı.
class _KesikKenar extends CustomPainter {
  _KesikKenar({required this.renk, required this.yaricap});
  final Color renk;
  final double yaricap;

  @override
  void paint(Canvas canvas, Size size) {
    final boya = Paint()
      ..color = renk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final yol = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1.25), Radius.circular(yaricap)));
    for (final m in yol.computeMetrics()) {
      for (double d = 0; d < m.length; d += 14) {
        canvas.drawPath(m.extractPath(d, d + 8), boya);
      }
    }
  }

  @override
  bool shouldRepaint(_KesikKenar eski) => eski.renk != renk || eski.yaricap != yaricap;
}
