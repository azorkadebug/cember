import '../tema.dart';
import '../tema_renkleri.dart';
import '../widgets/kalem_simgeleri.dart';
import '../utils/metin.dart';
import '../utils/sinif_ozeti.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/girdi.dart';
import '../widgets/simgeler.dart';
import '../widgets/cikartma.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ogrenci.dart';
import '../models/kontrol_kalemi.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/demo_modu.dart';
import '../services/mac_durumu.dart';
import '../widgets/sus_daireleri.dart';
import '../widgets/yardim_diyalogu.dart';
import 'skor_ekrani.dart';
import 'yoklama_ekrani.dart';
import 'kontrol_kalemleri_ekrani.dart';
import 'gecen_yildan_ekle_ekrani.dart';

// Rastgele takım adları: yalnız Türkçe, ortaokul mizahı (Sabri, 2026-10-04:
// İngilizce olanlar — FC, United, Lag, AFK, WiFi… — çıkarıldı). Kimseyi
// etiketlemeyen, kaba olmayan absürtler; denetim #4'te ayıklananlar geri
// gelmesin (Sus Len, Biber Gazı Spor, taraftar göndermeleri…).
const List<String> _takimIsimHavuzu = [
  // Kantin & yemek
  "Tost Mafyası", "Ayran Kardeşliği", "Simit Karteli", "Poğaça Operasyonu",
  "Kantin Korsanları", "Çikolata Çetesi", "Kraker Komandoları", "Cips Fırtınası",
  "Susamlı Şimşekler", "Ketçap Canavarları", "Uçan Lahmacunlar", "Galaktik Börekler",
  "Patlayan Mısırlar", "Kozmik Köfteciler", "Turşu Yıldızları", "Dinamit Domatesler",
  "Kaptan Patlıcan", "Kızgın Bamyalar", "Fırtınalı Fasulyeler", "Hızlı Hıyarlar",
  "Şaşkın Şalgamlar", "Gizemli Gofretler", "Fırıldak Fındıklar", "Zıpzıp Zerdeçallar",
  "Lazerli Lokumlar", "Uçan Köfteler", "Pilav Üstü Kahramanlar", "Mercimek Muhafızları",
  "Sucuklu Yumurta Birliği", "Kaşık Düşmanları", "Çorba Savaşçıları", "Pişmaniye Paşaları",
  // Okul & ders
  "Teneffüs Kaplanları", "Teneffüs Tayfası", "Ödev Avcıları", "Zil Korsanları",
  "Silgi Savaşçıları", "Uçan Tebeşirler", "Dev Cetvel", "Defter Ejderhaları",
  "Çılgın Silgiler", "Kalemtıraş Kardeşliği", "Kozmik Kalemtıraşlar", "Kayıp Kalem Uçları",
  "Sıra Arkası Spor", "Yoklama Ustaları", "Beslenme Çantası Birliği", "Kırmızı Kalem Korkusu",
  "Pisagor Çetesi", "Bölen Bulunmaz", "Kesirli Kahramanlar", "Virgülden Sonrası",
  "Türev Canavarları", "X'i Bulanlar", "Çarpım Tablosu Çetesi", "Pi Sayısı Takımı",
  // Sınıf içi klasikler
  "Son Sıra Kulübü", "Geç Kalanlar Birliği", "Unuttum Spor", "Ders Bitti Spor",
  "Pardon Hocam", "Ben Yapmadım Spor", "Beş Dakika Daha", "Zil Çalsın Yeter",
  "Tahtaya Kalkmam", "Hocam Bir Soru", "Kalem Ödünç Alanlar", "Yarın Getiririm",
  "Defterim Evde Kaldı", "Sessiz Sınıf", "Parmak Kaldıranlar",
  // Absürt hayvanlar
  "Korsan Papağanlar", "Viking Kedileri", "Şimşek Hamsterlar", "Perişan Penguenler",
  "Sesten Hızlı Sincaplar", "Panik Ahtapotlar", "Halaycı Arılar", "Roketli Salyangozlar",
  "Karambol Kedileri", "Torpido Tilkileri", "Roket Tavukları", "Lazer Koyunları",
  "Bumerang Balıkları", "Dalgalı Tavşanlar", "Atom Karıncaları", "Kızgın Flamingolar",
  "Parkurcu Pandalar", "Göbek Atan Yunuslar", "Uykucu Kaplumbağalar", "Hapşıran Zürafalar",
  "Kaykaycı Kirpiler", "Gözlüklü Baykuşlar", "Davulcu Ördekler", "Mırmır Aslanlar",
  // Absürt eşya & doğa
  "Çaydanlık Kardeşliği", "Ejder Çorapları", "Gizli Ajanlar", "Gök Gürültüsü Takımı",
  "Buldozer Kelebekler", "Sihirli Noktalar", "Nükleer Cevizler", "Dalga Delileri",
  "Yıkılmaz Yumurtalar", "Uçan Halıcılar", "Fırtına Fıstıkları", "Yanan Buzlar",
  "Demir Elmalar", "Altın Sakızlar", "Elmas Dirsekler", "Atomik Ayakkabılar",
  "Yağmur Botları", "Hortum Takımı", "Kar Topu Ordusu", "Şimşek Şemsiyeler",
  // Epik & komik
  "Meşhur Patatesler", "Efsane Peçeteler", "Korkusuz Krakerler", "Asi Kurabiyeler",
  "Efsane Çocuklar", "Aynen Öyle Takımı", "Tamamdır Reis", "Yok Artık",
  "Valla Olmaz", "Hadi Canım", "Kimse Bizi Tutamaz", "Bugün Bizim Günümüz",
  // Süper kahraman & çakma spor
  "Kaptan Kek", "Süper Simit", "Işın Kılıçlı Kalemler", "Radyoaktif Silgiler",
  "Pelerinli Pankekler", "Görünmez Çantalar", "Adidos Spor", "Pumba Spor",
  "Real Mısır", "Barçelona Börek", "Mantıspor", "Lahmacunspor",
];

class OgrenciListesiEkrani extends StatefulWidget {
  final String sinifId;
  final String? sinifAd;
  /// Arama sonucundan gelindiğinde liste yüklenir yüklenmez bu öğrencinin
  /// kartı açılır (bkz. ogrenci_arama_ekrani.dart).
  final String? acilacakOgrenciId;
  /// Geniş ekranda Sınıflarım'ın sağ sütununa gömülü: geri oku yok.
  final bool gomulu;
  /// Sınıfın Sınıflarım'daki rengi; verilmezse kimlikten sabit bir renk.
  final Color? renk;
  const OgrenciListesiEkrani({super.key, required this.sinifId, this.sinifAd, this.acilacakOgrenciId, this.gomulu = false, this.renk});
  @override
  State<OgrenciListesiEkrani> createState() => _OgrenciListesiEkraniState();
}

class _OgrenciListesiEkraniState extends State<OgrenciListesiEkrani> {
  late final FirestoreService _db;

  /// Öğrenci akışları bir kez kurulur. `build()` içinde `_db.ogrencilerStream(...)`
  /// çağırmak her yeniden çizimde yeni bir Stream nesnesi üretiyordu;
  /// StreamBuilder de aboneliği iptal edip yeniden kuruyor ve koleksiyonun
  /// tamamı Firestore'dan tekrar okunuyordu.
  ///
  /// Başlık istatistiği ile liste ayrı akışlar kullanıyor (bugünkü davranış
  /// korunuyor); ikisini tek akışta birleştirmek okuma sayısını yarıya
  /// indirir ama build ağacının yeniden düzenlenmesi gerekir.
  late final Stream<QuerySnapshot> _ogrencilerAkisiBaslik =
      _db.ogrencilerStream(widget.sinifId);
  late final Stream<QuerySnapshot> _ogrencilerAkisiListe =
      _db.ogrencilerStream(widget.sinifId);
  /// Yeniden abonelikte ilk olaya kadar veri yok sayılıp 0/0/0 yazılıyordu
  /// (denetim #4 Y2).
  QuerySnapshot? _sonBaslik, _sonListe;
  /// Başlıktaki Mevcut/Yok yalnız BUGÜN yoklama alındıysa sayı gösterir;
  /// yoksa "15 Mevcut" yoklama alınmış gibi görünüyordu (denetim #3).
  late final Stream<QuerySnapshot> _sonYoklamaAkisi = _db.sonYoklamaStream(widget.sinifId);
  QuerySnapshot? _sonYoklama;

  static String _bugunAnahtari() {
    final b = DateTime.now();
    return '${b.year}-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}';
  }

  int secilenTakimSayisi = 2;
  List<String> formaRenkleri = ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Beyaz', 'Turuncu', 'Lacivert'];
  String? _sinifAd;
  List<KontrolKalemi> _kontrolKalemleri = [];
  final _random = Random();
  String _aramaMetni = '';
  final _aramaCtrl = TextEditingController();
  bool _otomatikKartAcildi = false;
  bool _kartKapaniyor = false;
  /// Kontrol kalemleri/forma renkleri yüklendi mi (arama kartı bunu bekler).
  late final Future<void> _sinifBilgisiHazir;

  void _hataGoster(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: AppTema.tehlike,
    ));
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OgrenciListesiEkrani eski) {
    super.didUpdateWidget(eski);
    // İki sütunda sınıf adı değişince başlık eski kalıyordu (denetim #3 O4).
    if (eski.sinifAd != widget.sinifAd && widget.sinifAd != null) _sinifAd = widget.sinifAd;
  }

  List<String> _rastgeleTakimIsimleri(int adet) {
    final havuz = [..._takimIsimHavuzu]..shuffle(_random);
    return havuz.take(adet).toList();
  }

  @override
  void initState() {
    super.initState();
    _db = FirestoreService(uid: AuthService().uid);
    _sinifAd = widget.sinifAd; // sınıf listesinden geldiyse anında göster; yoksa fetch dolduracak
    _sinifBilgisiHazir = _formaRenkleriniYukle();
  }

  List<KontrolKalemi> _kontrolKalemleriCoz(Map<String, dynamic>? data) {
    final raw = data?['kontrolKalemleri'];
    if (raw is List && raw.isNotEmpty) {
      final list = raw
          .map((e) => KontrolKalemi.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      list.sort((a, b) => a.sira.compareTo(b.sira));
      return list;
    }
    // Eski sınıf: branşı yoksa Beden Eğitimi varsayılır.
    return bransSablonu(data?['brans'] as String?).varsayilanKalemler;
  }

  Future<void> _formaRenkleriniYukle() async {
    try {
      final data = await _db.sinifBilgisiGetir(widget.sinifId);
      final ad = (data?['ad'] as String?)?.trim();
      final kalemler = _kontrolKalemleriCoz(data);
      if (!mounted) return;
      setState(() {
        if (ad != null && ad.isNotEmpty) _sinifAd = ad;
        _kontrolKalemleri = kalemler;
        formaRenkleri = data != null && data['formaRenkleri'] != null
            ? List<String>.from(data['formaRenkleri'])
            : ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Beyaz', 'Turuncu', 'Lacivert'];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        formaRenkleri = ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Beyaz', 'Turuncu', 'Lacivert'];
      });
    }
  }

  Color get _sinifRengi => widget.renk ?? AppTema.sinifRengiKimlikten(widget.sinifId);

  @override
  Widget build(BuildContext context) {
    final r = context.renk;
    // Büyük yazıda başlık bloğu uzar; sabit 160 px'te istatistikler alttan
    // kırpılıyordu (denetim #3).
    final olcek = MediaQuery.textScalerOf(context).scale(1);
    return Scaffold(
      backgroundColor: r.sayfa,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // Eylemler maketteki gibi beyaz, mürekkep kenarlı yuvarlak düğmeler.
          Theme(
            data: Theme.of(context).copyWith(
              iconButtonTheme: IconButtonThemeData(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTema.ana,
                  side: const BorderSide(color: AppTema.ana, width: 2.5),
                  fixedSize: const Size(44, 44),
                ),
              ),
            ),
            child: SliverAppBar(
            // 120 iken flexibleSpace'teki büyük başlık, 56px'lik toolbar
            // şeridiyle aynı yüksekliğe düşüp aksiyon ikonlarının üstüne
            // çiziliyordu. Başlık artık Column'un başındaki SizedBox ile
            // şeridin ALTINA itiliyor; expandedHeight de ona göre büyüdü.
            expandedHeight: 122 + 56 * olcek,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: !widget.gomulu,
            // "Teneffüs": başlık sınıfın renginde, altı yuvarlak ve mürekkep kenarlı.
            backgroundColor: _sinifRengi,
            foregroundColor: AppTema.ana,
            surfaceTintColor: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              side: BorderSide(color: AppTema.ana, width: 2.5),
            ),
            centerTitle: true,
            title: innerBoxIsScrolled
                ? Text(_sinifAd ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: AppTema.baslikFontu, fontWeight: FontWeight.w600, fontSize: 21, color: AppTema.ana))
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.fact_check_rounded),
                tooltip: 'Yoklama',
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => YoklamaEkrani(sinifId: widget.sinifId, sinifAd: _sinifAd, kalemler: _kontrolKalemleri),
                )),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.help_outline_rounded),
                tooltip: 'Yardım',
                onPressed: () => YardimDiyalogu.goster(
                  context,
                  baslik: 'Öğrenciler & Takımlar — Yardım',
                  bolumler: const [
                    YardimBolumu(
                      ikon: Icons.person_add_alt_rounded,
                      baslik: 'Öğrenci ekleme',
                      aciklama: 'Sağ üstteki ⋮ menüsünden "Hızlı Öğrenci Ekle" ile toplu ekle: her satıra bir isim, cinsiyet ve puan. Aynı isim varsa uyarır.',
                      renk: Color(0xFF1976D2),
                    ),
                    YardimBolumu(
                      ikon: Icons.sticky_note_2_rounded,
                      baslik: 'Hızlı not',
                      aciklama: 'Öğrencinin satırına basılı tut → not penceresi açılır. Notu olan öğrencinin yanında sarı not kâğıdı görünür; notun içeriği listede gösterilmez, yalnız sen görürsün.',
                      renk: Color(0xFFFFA63D),
                    ),
                    YardimBolumu(
                      ikon: Icons.bolt_rounded,
                      baslik: 'Yetenek puanı',
                      aciklama: 'Her öğrenciye bir yetenek puanı verebilirsin (varsayılan 100). Takım kurucu puanları yılan sıralamasıyla dağıtıp takım toplamlarını dengeler. Öğrenci kartındaki "Bilgiler" bölümünden değiştir; 70-130 arası yeterli.',
                      renk: Color(0xFFFFB300),
                    ),
                    YardimBolumu(
                      ikon: Icons.local_fire_department_rounded,
                      baslik: 'Element',
                      aciklama: 'Öğrenci kartındaki "Element" satırından ata: ateş, su, toprak, hava. Çatışan elementler (ateş ile su, toprak ile hava) hep FARKLI takımlara düşer; kavgalı ya da ayrılması gereken öğrenciler için. Aynı elementler genelde aynı takımda toplanır.',
                      renk: Color(0xFFE53935),
                    ),
                    YardimBolumu(
                      ikon: Icons.link_rounded,
                      baslik: 'Eşleştirme 🔗',
                      aciklama: 'Öğrenci kartındaki "Eşleş" satırından iki öğrenciyi birbirine bağla. Takım kurucu bu ikiliyi hep aynı takıma koyar; elementten bağımsızdır. Birlikte oynamaktan hoşlanan iki arkadaşı ayırmamak için.',
                      renk: Color(0xFF3949AB),
                    ),
                    YardimBolumu(
                      ikon: Icons.checklist_rounded,
                      baslik: 'Yoklama',
                      aciklama: 'Üstteki ✓ simgesiyle tarihli yoklama al; kontrol kalemleriyle (kitap, forma, boya…) birlikte kaydedilir. Listede bir öğrenciyi sağa kaydırarak da hızlıca "Yok" yazabilirsin; ikisi aynı kayda işler. Yalnız gelenler takım kurmaya girer.',
                      renk: Color(0xFF00897B),
                    ),
                    YardimBolumu(
                      ikon: Icons.sports_score_rounded,
                      baslik: 'Takım Kur',
                      aciklama: 'Alttaki "Takım Kur" düğmesi öğrencileri adil gruplara ayırır: oyun, yarışma ya da grup çalışması için. Önce kızları, sonra erkekleri puana göre sıralayıp yılan sıralamasıyla dağıtır; elementli ve eşli öğrencileri önce yerleştirir. Sonuç: en fazla 1 kişi farkı, denk puanlar, çatışan elementler ayrı.',
                      renk: Color(0xFF43A047),
                    ),
                    YardimBolumu(
                      ikon: Icons.visibility_off_rounded,
                      baslik: 'Demo modu',
                      aciklama: 'Sınıflarım ekranındaki göz simgesi: AÇIK iken öğrenci adları rastgele sahte isimlerle gösterilir. Sunum, ekran görüntüsü veya gösterimler için ideal — gerçek öğrenci adları sızmaz.',
                      renk: Color(0xFFFB8C00),
                    ),
                    YardimBolumu(
                      ikon: Icons.assignment_late_rounded,
                      baslik: 'Kontrol kalemleri',
                      aciklama: 'Branşına göre kontrol kalemleri tanımla (forma, kitap, boya, enstrüman…): günlük ✓/✗ ya da sezon boyu sayaç. ⋮ menüsünden "Kontrol Kalemleri" ile düzenle. Sağlık notları ve rozetler öğrenci kartında.',
                      renk: Color(0xFF8E24AA),
                    ),
                  ],
                ),
              ),
              // Beş ikon dar ekranda başlıkla yarışıyordu; üçü taşır menüye
              // alındı. Yoklama ve Yardım en sık kullanılanlar, dışarıda kaldı.
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'Daha fazla',
                onSelected: (secim) async {
                  switch (secim) {
                    case 'kalemler':
                      final yeni = await Navigator.push<List<KontrolKalemi>>(context, MaterialPageRoute(
                        builder: (_) => KontrolKalemleriEkrani(sinifId: widget.sinifId, kalemler: _kontrolKalemleri),
                      ));
                      if (yeni != null && mounted) setState(() => _kontrolKalemleri = yeni);
                    case 'hizliEkle':
                      _hizliSinifEkleDialog();
                    case 'gecenYil':
                      unawaited(_gecenYildanEkle());
                    case 'renkler':
                      _renkYonetimi();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'kalemler',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.tune_rounded),
                      title: Text('Kontrol Kalemleri'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'hizliEkle',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.group_add_rounded),
                      title: Text('Hızlı Öğrenci Ekle'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'gecenYil',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.history_rounded),
                      title: Text('Geçen Yıldan Ekle'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'renkler',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.palette_outlined),
                      title: Text('Takım Renkleri'),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Maketteki süs daireleri (sağ üstte limon, sol altta beyaz),
                  // yavaşça süzülür.
                  Positioned.fill(
                    child: SusDaireleri(daireler: [
                      SusDaire(const Offset(0.94, 0.08), 150,
                          _sinifRengi == const Color(0xFFFFD84D) ? Colors.white.withAlpha(110) : const Color(0xFFFFD84D).withAlpha(140),
                          genlik: 12),
                      SusDaire(const Offset(0.03, 0.96), 96, Colors.white.withAlpha(46)),
                      SusDaire(const Offset(0.86, 0.6), 18, Colors.white.withAlpha(90), genlik: 6),
                    ]),
                  ),
                  SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, kToolbarHeight, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _sinifAd ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontFamily: AppTema.baslikFontu,
                            color: AppTema.ana,
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            height: 1.05),
                      ),
                      const SizedBox(height: 10),
                      // İstatistikler çıkartma çipler.
                      StreamBuilder<QuerySnapshot>(
                        stream: _ogrencilerAkisiBaslik,
                        initialData: _sonBaslik,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) _sonBaslik = snapshot.data;
                          final total = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          return StreamBuilder<QuerySnapshot>(
                            stream: _sonYoklamaAkisi,
                            initialData: _sonYoklama,
                            builder: (context, ySnap) {
                              if (ySnap.hasData) _sonYoklama = ySnap.data;
                              // Sayım ana sayfadaki halkayla aynı kaynaktan: bugünkü
                              // yoklama kaydı (kaydı olmayan öğrenci "geldi").
                              final bugunku = ySnap.data?.docs.where((d) => d.id == _bugunAnahtari()).firstOrNull;
                              final ozet = bugunku == null || !snapshot.hasData
                                  ? null
                                  : yoklamaOzeti(bugunku.data() as Map<String, dynamic>?, snapshot.data!.docs.map((d) => d.id));
                              return Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _baslikCipi(Icons.people_alt_rounded, "$total öğrenci", Colors.white, AppTema.ana),
                                  if (ozet != null) ...[
                                    _baslikCipi(Icons.check_rounded, "${ozet.gelen} geldi", const Color(0xFF63C77A), AppTema.ana),
                                    _baslikCipi(Icons.close_rounded, "${ozet.toplam - ozet.gelen} yok", AppTema.ana, Colors.white),
                                  ] else
                                    _baslikCipi(Icons.fact_check_rounded, "Yoklama alınmadı", Colors.white, AppTema.ana),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
                ],
              ),
            ),
          ),
          ),
        ],
        body: Column(
          children: [
            // Aktif maç banner'ı
            // Maç bitince yeniden çizime kadar "devam ediyor" kalıyordu (denetim #3 O5).
            ListenableBuilder(
              listenable: MacDurumu(),
              builder: (_, _) => MacDurumu().aktif && MacDurumu().sinifId == widget.sinifId
                  ? _aktifMacBanner()
                  : const SizedBox.shrink(),
            ),
            // Arama çubuğu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _aramaCtrl,
                onChanged: (val) => setState(() => _aramaMetni = trKucult(val)),
                decoration: InputDecoration(
                  hintText: "Öğrenci ara...",
                  prefixIcon: Icon(Icons.search_rounded, color: r.metinUcuncul),
                  suffixIcon: _aramaMetni.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          tooltip: 'Aramayı temizle',
                          onPressed: () {
                            _aramaCtrl.clear();
                            setState(() => _aramaMetni = '');
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            Expanded(child: _bulutListeInsaEt()),
          ],
        ),
      ),
      bottomNavigationBar: IgnorePointer(
        ignoring: _kartKapaniyor,
        child: Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              decoration: BoxDecoration(
                color: r.sayfa,
                border: Border(top: BorderSide(color: r.cizgi, width: 1.5)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Açılır menü yerine sayaç (Sabri: menüyü açıp seçmek
                    // sıkıcı): tek dokunuşla bir artır/azalt. Sınır aynı:
                    // 2 ile sınıfın forma rengi sayısı arası.
                    _takimSayaci(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SertGolgeli(
                        // 320 px'te sayacın yanında sığsın diye küçülebilir.
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            minimumSize: const Size.fromHeight(54),
                          ),
                          onPressed: _takimlariKur,
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.auto_awesome_rounded),
                              SizedBox(width: 8),
                              Text("Takım Kur", style: TextStyle(fontSize: 19)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  /// Geçmiş yılların sınıflarından öğrenci seçip bu sınıfa aktarır.
  Future<void> _gecenYildanEkle() async {
    final eklenen = await Navigator.push<int>(context, MaterialPageRoute(
      builder: (_) => GecenYildanEkleEkrani(
        hedefSinifId: widget.sinifId,
        hedefSinifAd: _sinifAd ?? 'Bu sınıf',
      ),
    ));
    if (eklenen == null || eklenen == 0 || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$eklenen öğrenci geçen yıldan eklendi."),
      backgroundColor: AppTema.basari,
    ));
  }

  int get _enCokTakim => formaRenkleri.length > 2 ? formaRenkleri.length : 2;

  Widget _takimSayaci() {
    final r = context.renk;
    final n = secilenTakimSayisi.clamp(2, _enCokTakim);
    Widget dugme(IconData ikon, String ipucu, bool etkin, int fark) => IconButton(
          tooltip: ipucu,
          onPressed: etkin ? () => setState(() => secilenTakimSayisi = n + fark) : null,
          icon: Icon(ikon, size: 24),
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44),
            backgroundColor: r.kart,
            foregroundColor: r.metin,
            disabledBackgroundColor: r.kart,
            disabledForegroundColor: r.cizgi,
            side: BorderSide(color: etkin ? r.kenar : r.cizgi, width: 2.5),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      dugme(Icons.remove_rounded, 'Takım sayısını azalt', n > 2, -1),
      Semantics(
        liveRegion: true,
        label: '$n takım',
        excludeSemantics: true,
        child: SizedBox(
          width: 58,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$n',
                textScaler: TextScaler.noScaling,
                style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 26, fontWeight: FontWeight.w700, color: r.metin, height: 1)),
            Text('takım',
                textScaler: TextScaler.noScaling,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: r.metinIkincil)),
          ]),
        ),
      ),
      dugme(Icons.add_rounded, 'Takım sayısını artır', n < _enCokTakim, 1),
    ]);
  }

  Widget _baslikCipi(IconData ikon, String metin, Color zemin, Color yazi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTema.ana, width: 2.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ikon, size: 17, color: yazi),
        const SizedBox(width: 5),
        Text(metin, style: TextStyle(color: yazi, fontSize: 15, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _aktifMacBanner() {
    return GestureDetector(
      onTap: () {
        Navigator.push<String>(context, MaterialPageRoute(
          builder: (_) => SkorEkrani(takimlar: MacDurumu().takimlar!),
        )).then((sonuc) {
          if (sonuc != 'geridon') MacDurumu().macBitir();
          setState(() {});
        });
      },
      // Sınıflarım'daki bantla aynı sarı bilet (eskiden ayrı, lacivert
      // bir tasarımdı — denetim #3).
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Cikartma(
          renk: const Color(0xFFFFD84D),
          kenarRengi: AppTema.ana,
          yaricap: 18,
          dolgu: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.timer_rounded, color: AppTema.ana, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text("Etkinlik sürüyor",
                    style: TextStyle(fontFamily: AppTema.baslikFontu, color: AppTema.ana, fontWeight: FontWeight.w600, fontSize: 18)),
              ),
              Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: StadiumBorder(side: BorderSide(color: AppTema.ana, width: 2)),
                ),
                child: const Text("Devam Et", style: TextStyle(color: AppTema.ana, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bulutListeInsaEt() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ogrencilerAkisiListe,
      initialData: _sonListe,
      builder: (context, snapshot) {
        if (snapshot.hasData) _sonListe = snapshot.data;
        if (snapshot.hasError && !snapshot.hasData) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(FirestoreService.hataMesaji(snapshot.error!), textAlign: TextAlign.center,
                style: TextStyle(color: context.renk.metinIkincil)),
          ));
        }
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: context.renk.vurgu));
        List<Ogrenci> liste = snapshot.data!.docs
            .map((d) => Ogrenci.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();
        if (liste.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_alt_1_rounded, size: 80, color: context.renk.bosDurumIkonu),
                const SizedBox(height: 16),
                Text("Henüz öğrenci yok", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.renk.metinIkincil)),
                const SizedBox(height: 8),
                Text("Sağ üstteki ⋮ menüsünden \"Hızlı Öğrenci Ekle\" ile başla",
                    textAlign: TextAlign.center, style: TextStyle(color: context.renk.metinUcuncul)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _gecenYildanEkle,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text("Geçen Yıldan Ekle"),
                ),
              ],
            ),
          );
        }
        // Alfabetik sıralama
        liste.sort((a, b) => trKarsilastir(a.gorunenAd, b.gorunenAd));
        // Eşleştirme seçicisi arama filtresinden etkilenmemeli — sınıfın
        // tamamı adayları olarak kalsın.
        final tumOgrenciler = List<Ogrenci>.from(liste);
        // Öğrenci aramasından gelindiyse kartı bir kez, ilk veride aç.
        if (!_otomatikKartAcildi && widget.acilacakOgrenciId != null) {
          _otomatikKartAcildi = true;
          final hedef = tumOgrenciler.where((o) => o.id == widget.acilacakOgrenciId).firstOrNull;
          if (hedef != null) {
            // Kalemler yüklenmeden açılınca kart "kontrol kalemi yok"
            // gösteriyordu (denetim #3 O6).
            unawaited(_sinifBilgisiHazir.then((_) {
              if (mounted) _ogrenciKartiAc(hedef, tumOgrenciler);
            }));
          }
        }
        // Arama filtresi — ekranda görünen ada göre. Demo modunda gerçek ada
        // göre aramak, kullanıcının gördüğü isimle sonuç bulamamasına yol açar.
        if (_aramaMetni.isNotEmpty) {
          liste = liste
              .where((o) => trKucult(o.gorunenAd).contains(_aramaMetni))
              .toList();
        }
        return _listeInsaEt(liste, tumOgrenciler);
      },
    );
  }

  Widget _listeInsaEt(List<Ogrenci> liste, List<Ogrenci> tumOgrenciler) {
    // 1440 px'te satırlar 1900 px uzunluğa yayılıyordu: solda isim, sağ uçta
    // tek bir onay ikonu, arada kocaman boşluk. Center DEĞİL Align — bkz.
    // profil_ekrani.dart'taki iPad kaydırma notu.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
        child: _liste(liste, tumOgrenciler),
      ),
    );
  }

  List<Ogrenci> _tumOgrenciler = const [];
  Map<String, Color> _renkler = const {};

  Widget _liste(List<Ogrenci> liste, List<Ogrenci> tumOgrenciler) {
    _tumOgrenciler = tumOgrenciler;
    // tumOgrenciler görünen ada göre alfabetik; renkler bu sırayla.
    _renkler = AppTema.ogrenciRenkHaritasi(tumOgrenciler.map((o) => o.id));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: liste.length,
      itemBuilder: (context, i) {
        final o = liste[i];
        final r = context.renk;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Dismissible(
            key: Key(o.id),
            direction: DismissDirection.startToEnd,
            confirmDismiss: (_) async {
              o.buradaMi = !o.buradaMi;
              // Tek alan yazılıyor: tüm dokümanı geri yazmak, ikinci bir
              // cihazdan o sırada girilen puan/sayaç değişikliklerini siler.
              unawaited(_db.buradaMiGuncelle(widget.sinifId, o.id, o.buradaMi));
              // Yoklama ekranı ile sınıf listesi iki ayrı "yok" tutuyordu
              // (denetim #4 Y1): kaydırma bugünün yoklamasına da işlensin.
              unawaited(_db.yoklamaTekOgrenci(widget.sinifId, _bugunAnahtari(), o.id, o.buradaMi).catchError((_) {}));
              return false; // Kartı silme, sadece toggle
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              margin: const EdgeInsets.only(right: 3, bottom: 3),
              decoration: BoxDecoration(
                color: o.buradaMi
                    ? (r.yokZemin)
                    : (r.geldiZemin),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  // green.shade700, green.shade100 zemin üzerinde 3,1:1
                  // veriyordu; AppTema.basari (green900) 5,9:1.
                  Icon(o.buradaMi ? Icons.cancel_rounded : Icons.check_circle_rounded,
                      color: o.buradaMi ? (r.yokMetin) : r.basari),
                  const SizedBox(width: 8),
                  Text(o.buradaMi ? "Yok yaz" : "Geldi",
                      style: TextStyle(fontWeight: FontWeight.w700, color: o.buradaMi ? (r.yokMetin) : r.basari)),
                ],
              ),
            ),
            child: Cikartma(
              yaricap: 18,
              kayma: 3,
              kenarKalinligi: 2,
              onTap: () => _ogrenciKartiAc(o, tumOgrenciler),
              // Hızlı not (Sabri'nin isteği, 2026-08-28) satırdaki simge
              // yerine basılı tutunca; içerik listede hiç görünmez.
              onLongPress: () => _notHizliDuzenle(o),
                // Alt satırı/çıkartması olmayan öğrencide satır kısalıyor,
                // yuvarlak kartın kenarına değiyordu (Sabri): hepsi aynı
                // asgari yükseklikte, içerik ortada.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 62),
                  child: Row(
                  children: [
                    // Cinsiyet şeridi yerine baş harfli renkli yuvarlak (renk
                    // öğrenciye sabit); cinsiyet adın yanındaki simgede.
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Semantics(
                        label: o.isMale ? 'Erkek öğrenci' : 'Kız öğrenci',
                        child: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: !o.buradaMi ? const Color(0xFFE6E2DA) : AppTema.ogrenciRengi(o.id, _renkler),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTema.ana, width: 2),
                          ),
                          child: Text(
                            basHarfler(o.gorunenAd),
                            textScaler: TextScaler.noScaling,
                            style: const TextStyle(
                                fontFamily: AppTema.baslikFontu, fontSize: 16, fontWeight: FontWeight.w600, color: AppTema.ana),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                  children: [
                                CinsiyetSimgesi(o.isMale, boyut: 16),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(o.gorunenAd,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 16,
                                        color: o.buradaMi ? r.metin : r.metinUcuncul,
                                      )),
                                ),
                              ],
                            ),
                            // Maketteki kısa bilgi satırı: element, eksikler,
                            // sarı kart, not var. Puan yazmaz (Sabri: kartta
                            // görürüm); notun İÇERİĞİ hiçbir zaman listede yok.
                            if (_bilgiSatiri(o).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(_bilgiSatiri(o),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: r.metinIkincil, fontSize: 13.5, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                      _rozetGrubu(o),
                    ],
                  ),
                )),
                  ],
                ),
                ),
            ),
          ),
        );
      },
    );
  }

  /// "Su · eşli · not var" gibi kısa bilgi.
  String _bilgiSatiri(Ogrenci o) {
    if (!o.buradaMi) return 'bugün gelmedi';
    // Kalem eksikleri yazıyla değil sağdaki çıkartmalarla (Sabri).
    final parcalar = <String>[
      ?ElementSistemi.etiket(o.element),
      if (o.eslesenIdler.isNotEmpty) 'eşli',
      if (o.not.isNotEmpty) 'not var',
    ];
    return parcalar.join(' · ');
  }

  /// Sağdaki çıkartmalar: kare içinde kare yok (Sabri, 2026-10-04) —
  /// sarı kart eğik sarı etiket, rozet mor yıldız, sağlık kırmızı çanta,
  /// Yok mürekkep etiket; en sonda hızlı not.
  Widget _rozetGrubu(Ogrenci o) {
    final r = context.renk;
    final cikartmalar = <Widget>[
      if (!o.buradaMi)
        Transform.rotate(
          angle: -0.07,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: ShapeDecoration(color: r.murekkepDolgu, shape: const StadiumBorder()),
            child: Text("Yok", style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 15, color: r.murekkepUstu, fontWeight: FontWeight.w600)),
          ),
        ),
      for (final k in _kontrolKalemleri)
        if (o.kalemDeger(k.id) > 0 && k.id == 'sari_kart')
          Transform.rotate(
            angle: 0.1,
            child: Container(
              constraints: const BoxConstraints(minWidth: 28),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // İkinci sarı kart kırmızı (eski davranış).
                color: o.kalemDeger(k.id) >= 2 ? const Color(0xFFFF6B57) : const Color(0xFFFFD84D),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTema.ana, width: 2),
              ),
              child: Text('${o.kalemDeger(k.id)}',
                  style: const TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 15, fontWeight: FontWeight.w700, color: AppTema.ana)),
            ),
          )
        else if (o.kalemDeger(k.id) > 0)
          // Kıyafet/ayakkabı eksik ve diğer sayaçlar: çerçevesiz renkli
          // çıkartma, 2+ ise köşede sayı.
          KalemCikartmasi(k.ikon, sayi: o.kalemDeger(k.id)),
      if (o.saglikDurumu != 0) const KalemCikartmasi('saglik'),
      if (o.not.isNotEmpty) const NotCikartmasi(),
      if (o.rozetler.isNotEmpty)
        Container(
          width: 30, height: 30,
          alignment: Alignment.center,
          decoration: const ShapeDecoration(
            color: Color(0xFF9B6BF2),
            shape: CircleBorder(side: BorderSide(color: AppTema.ana, width: 2)),
          ),
          child: o.rozetler.length > 1
              ? Text('${o.rozetler.length}',
                  style: const TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))
              : const Icon(Icons.star_rounded, color: Colors.white, size: 18),
        ),
    ];
    final etiket = [
      if (!o.buradaMi) 'yok',
      for (final k in _kontrolKalemleri)
        if (o.kalemDeger(k.id) > 0) '${k.ad} ${o.kalemDeger(k.id)}',
      if (o.saglikDurumu != 0) 'sağlık notu',
      if (o.not.isNotEmpty) 'not var',
      if (o.rozetler.isNotEmpty) '${o.rozetler.length} rozet',
    ].join(', ');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (cikartmalar.isNotEmpty)
        Semantics(
          button: true,
          label: 'İşaretler: $etiket',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => _ogrenciKartiAc(o, _tumOgrenciler),
            behavior: HitTestBehavior.opaque,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final c in cikartmalar) Padding(padding: const EdgeInsets.only(left: 6), child: c),
              ]),
            ),
          ),
        ),
    ]);
  }


  Color _kalemRengi(KontrolKalemi k) {
    if (k.tip == KalemTipi.sayac) return Colors.amber.shade700;
    final palet = [Colors.deepOrange, Colors.purple, Colors.teal, Colors.indigo, Colors.pink.shade400, Colors.green];
    return palet[k.id.hashCode.abs() % palet.length];
  }

  Widget _artieksi(String ikonAnahtari, Color renk, String label, int val, Function(int) onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // Kare içinde kare yok (Sabri): simge doğrudan, − beyaz / + sarı
      // yuvarlak çıkartma; etiket esnek (320 px + büyük yazıda taşıyordu).
      child: Row(children: [
        // Listedeki çıkartmaların aynısı (Sabri: üçü siyah, sağlık kırmızıydı).
        SizedBox(width: 30, child: Center(child: KalemCikartmasi(ikonAnahtari, boyut: 28))),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        _kartSayacDugmesi(Icons.remove_rounded, '$label azalt', () => onEdit(-1), false),
        SizedBox(
          width: 38,
          child: Text("$val",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppTema.baslikFontu, fontWeight: FontWeight.w700, fontSize: 20)),
        ),
        _kartSayacDugmesi(Icons.add_rounded, '$label artır', () => onEdit(1), true),
      ]),
    );
  }

  Widget _kartSayacDugmesi(IconData ikon, String ipucu, VoidCallback onTap, bool arti) {
    const sekil = CircleBorder(side: BorderSide(color: AppTema.ana, width: 2));
    return Material(
      color: arti ? const Color(0xFFFFD84D) : Colors.white,
      shape: sekil,
      child: InkWell(
        customBorder: sekil,
        onTap: onTap,
        child: Tooltip(
          message: ipucu,
          child: SizedBox(width: 44, height: 44, child: Icon(ikon, size: 22, color: AppTema.ana)),
        ),
      ),
    );
  }

  Widget _saglikSatiri(Ogrenci o, StateSetter setDialogState) {
    final r = context.renk;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        // Geçmiş düğmesi 30 px'ti (denetim #3): satırın sol kısmı 44 px hedef.
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: o.saglikNotlari.isEmpty ? null : () => _saglikGecmisiDialog(o),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Row(children: [
                const SizedBox(width: 30, child: Center(child: KalemCikartmasi('saglik', boyut: 28))),
                const SizedBox(width: 10),
                const Flexible(child: Text("Sağlık", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                if (o.saglikNotlari.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.history_rounded, size: 18, color: r.metinIkincil),
                ],
              ]),
            ),
          ),
        ),
        _kartSayacDugmesi(Icons.remove_rounded, 'Sağlık puanını azalt',
            () => setDialogState(() => o.saglikDurumu += -1), false),
        SizedBox(
          width: 38,
          child: Text("${o.saglikDurumu}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: AppTema.baslikFontu, fontWeight: FontWeight.w700, fontSize: 20)),
        ),
        _kartSayacDugmesi(Icons.add_rounded, 'Sağlık notu ekle', () => _saglikNotuEkleDialog(o, setDialogState), true),
      ]),
    );
  }

  void _saglikNotuEkleDialog(Ogrenci o, StateSetter setDialogState) {
    final notCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const OzelSimgeWidget(OzelSimge.saglik, color: Colors.teal, size: 22),
          const SizedBox(width: 8),
          const Text("Sağlık Notu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: TextField(
          controller: notCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: GirdiSiniri.saglikNotu,
          buildCounter: gizliSayac,
          decoration: InputDecoration(
            hintText: "Örn: derse katılamaz, dikkat edilmeli...",
            helperText: "Teşhis/hastalık adı yazma — yalnızca derste ne yapman gerektiğini not al.",
            helperMaxLines: 2,
            helperStyle: const TextStyle(fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final now = DateTime.now();
              final tarih = "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";
              o.saglikNotlari.add({'tarih': tarih, 'not': notCtrl.text.trim()});
              setDialogState(() => o.saglikDurumu += 1);
              Navigator.pop(ctx);
            },
            child: const Text("Ekle", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _saglikGecmisiDialog(Ogrenci o) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.history_rounded, color: Colors.teal, size: 22),
          const SizedBox(width: 8),
          Flexible(child: Text("${o.gorunenAd} - Sağlık Geçmişi", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: o.saglikNotlari.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final kayit = o.saglikNotlari[o.saglikNotlari.length - 1 - i];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.teal.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                  child: Text(kayit['tarih'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.teal)),
                ),
                title: Text(DemoModu.aktif ? 'Demo modunda gizli' : (kayit['not'] ?? '-'), style: const TextStyle(fontSize: 14)),
                // Sağlık notu hiçbir yerden silinemiyordu (denetim #4 O2).
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: ctx.renk.tehlike, size: 20),
                  tooltip: 'Notu sil',
                  onPressed: () {
                    setD(() => o.saglikNotlari.remove(kayit));
                    unawaited(_db.saglikNotuSil(widget.sinifId, o.id, kayit)
                        .catchError((_) => _hataGoster('Not silinemedi.')));
                    if (o.saglikNotlari.isEmpty) Navigator.pop(ctx);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kapat"),
          ),
        ],
      )),
    );
  }

  void _rozetVerDialog(Ogrenci o, StateSetter parentSetState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 8),
          Flexible(child: Text("${o.gorunenAd} - Rozet Ver", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (o.rozetler.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: ctx.renk.uyariZemin, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mevcut Rozetler:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ctx.renk.uyari)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4, runSpacing: 4,
                      children: o.rozetler.reversed.map((r) {
                        final tanim = Ogrenci.rozetTanimlari[r['rozet']] ?? r['rozet'];
                        return Chip(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          label: Text("$tanim  ${r['tarih']}", style: const TextStyle(fontSize: 12)),
                          deleteIcon: Icon(Icons.close_rounded, size: 16, color: Colors.red.shade400),
                          onDeleted: () {
                            Navigator.pop(ctx);
                            _rozetSilOnay(o, r, parentSetState);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...Ogrenci.rozetTanimlari.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final now = DateTime.now();
                    final tarih = "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";
                    final rozet = {'rozet': e.key, 'tarih': tarih};
                    o.rozetler.add(rozet);
                    unawaited(_db.rozetEkle(widget.sinifId, o.id, rozet));
                    parentSetState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: ctx.renk.yuzeyGri,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ctx.renk.cizgiAcik),
                    ),
                    child: Row(children: [
                      Text(e.value, style: const TextStyle(fontSize: 14)),
                    ]),
                  ),
                ),
              );
            }),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Kapat"),
          ),
        ],
      ),
    );
  }

  void _rozetSilOnay(Ogrenci o, Map<String, dynamic> rozet, StateSetter parentSetState) {
    final tanim = Ogrenci.rozetTanimlari[rozet['rozet']] ?? rozet['rozet'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Rozet Sil"),
        content: Text("$tanim rozetini silmek istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              o.rozetler.remove(rozet);
              unawaited(_db.rozetSil(widget.sinifId, o.id, rozet));
              parentSetState(() {});
              Navigator.pop(ctx);
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  // Tam "Öğrenci Düzenle" penceresini açmadan hızlıca not eklemek/düzenlemek
  // için (2026-08-28) — sınıf listesindeki not satırından tetiklenir.
  void _notHizliDuzenle(Ogrenci o) {
    if (DemoModu.aktif) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo modunda notlar gizli.')));
      return;
    }
    final nC = TextEditingController(text: o.not);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.sticky_note_2_rounded, color: Colors.amber, size: 22),
          const SizedBox(width: 8),
          Flexible(child: Text(o.gorunenAd, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        ]),
        // minLines=maxLines: sabit yükseklikte kutu — yoksa 1 satırdan
        // başlayıp yazdıkça büyüyor, pencere her tuşta yeniden boyutlanıp
        // titriyordu (Sabri'nin isteği, 2026-08-28).
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: nC,
            maxLength: GirdiSiniri.ogrenciNotu,
            buildCounter: gizliSayac,
            autofocus: true,
            minLines: 3,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Özel Not",
              floatingLabelBehavior: FloatingLabelBehavior.always,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.renk.vurgu, foregroundColor: ctx.renk.vurguMetin,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              o.not = nC.text;
              // Tüm dokümanı mutlak yazıyordu; başka cihazın sayaç/rozet
              // değişikliğini eziyordu (denetim #3 Y1). Yalnız not.
              unawaited(_db
                  .ogrenciAlanlariniGuncelle(widget.sinifId, o.id, {'not': o.not})
                  .catchError((_) => _hataGoster('Not kaydedilemedi.')));
              Navigator.pop(ctx);
            },
            child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).then((_) => nC.dispose());
  }


  /// Bir öğrencinin her şeyi tek yerde: kontrol kalemleri, not, rozetler,
  /// takım kurma ayarları (ifade + eşleşme) ve kimlik bilgileri.
  /// Eskiden satır → "Öğrenci Düzenle", sağdaki rozet alanı → kalem
  /// penceresi, "Not ekle" → hızlı not olmak üzere üç ayrı pencere vardı;
  /// hangisine dokunulacağı ekrandan anlaşılmıyordu (2026-09-05, Sabri
  /// "yapalım, beğenmezsem geri döneriz" dedi).
  ///
  /// Kaydetme modeli: tek Kaydet. Sayaçlar FARK olarak işlemle yazılır (iki
  /// cihaz aynı anda sarı kart verince ikisi de sayılsın), diğer alanlar
  /// sayaçlara dokunmadan güncellenir. İptal/dışarı tıklama bellekteki
  /// nesneyi açılıştaki hâline döndürür. Rozetler istisna: verildiği anda
  /// yazılır (eski davranış korunuyor).
  void _ogrenciKartiAc(Ogrenci o, List<Ogrenci> tumOgrenciler) {
    // Demo modunda kart gerçek adı ve notu göstermemeli (denetim #3): alanlar
    // sahte adla/boş açılır, salt okunur kalır ve kaydedilmez.
    final demo = DemoModu.aktif;
    final adC = TextEditingController(text: demo ? o.gorunenAd : o.ad);
    final pC = TextEditingController(text: o.puan.toString());
    final nC = TextEditingController(text: demo ? '' : o.not);
    final dokunulanEslerinIdleri = <String>{};

    // Açılış anının kopyası — iptalde geri almak için.
    final ilkIsMale = o.isMale;
    final ilkElement = o.element;
    final ilkSaglik = o.saglikDurumu;
    final ilkSaglikNotlari = o.saglikNotlari.map((e) => Map<String, dynamic>.from(e)).toList();
    final ilkSayaclar = Map<String, int>.from(o.kalemSayaclari);
    final ilkEsler = List<String>.from(o.eslesenIdler);
    final ilkPartnerEsleri = {
      for (final p in tumOgrenciler) p.id: List<String>.from(p.eslesenIdler),
    };
    void geriAl() {
      o.isMale = ilkIsMale;
      o.element = ilkElement;
      o.saglikDurumu = ilkSaglik;
      o.saglikNotlari
        ..clear()
        ..addAll(ilkSaglikNotlari);
      o.kalemSayaclari
        ..clear()
        ..addAll(ilkSayaclar);
      o.eslesenIdler
        ..clear()
        ..addAll(ilkEsler);
      for (final p in tumOgrenciler) {
        final eski = ilkPartnerEsleri[p.id];
        if (eski != null) {
          p.eslesenIdler
            ..clear()
            ..addAll(eski);
        }
      }
    }

    final ilkAd = o.ad, ilkPuan = o.puan, ilkNot = o.not;

    void kaydet(BuildContext sheetCtx) {
      final yeniAd = adC.text.trim();
      if (!demo && yeniAd.isNotEmpty) o.ad = yeniAd;
      o.puan = (int.tryParse(pC.text) ?? 100).clamp(0, 9999);
      if (!demo) o.not = nC.text;
      // Yalnız DEĞİŞEN alanlar (denetim #3 Y1): açık kart bayat olabilir,
      // dokunulmayan alanı yazmak diğer cihazın değişikliğini siler.
      final alanlar = <String, dynamic>{
        if (o.ad != ilkAd) 'ad': o.ad,
        if (o.puan != ilkPuan) 'puan': o.puan,
        if (o.not != ilkNot) 'not': o.not,
        if (o.isMale != ilkIsMale) 'isMale': o.isMale,
        if (o.element != ilkElement) 'element': o.element ?? FieldValue.delete(),
      };
      final farklar = <String, int>{};
      for (final id in {...ilkSayaclar.keys, ...o.kalemSayaclari.keys}) {
        final fark = (o.kalemSayaclari[id] ?? 0) - (ilkSayaclar[id] ?? 0);
        if (fark != 0) farklar[id] = fark;
      }
      final yeniNotlar = o.saglikNotlari.length > ilkSaglikNotlari.length
          ? o.saglikNotlari.sublist(ilkSaglikNotlari.length)
          : const <Map<String, dynamic>>[];
      final esEkle = o.eslesenIdler.where((e) => !ilkEsler.contains(e)).toList();
      final esKaldir = ilkEsler.where((e) => !o.eslesenIdler.contains(e)).toList();
      final bosMu = alanlar.isEmpty && farklar.isEmpty && o.saglikDurumu == ilkSaglik &&
          yeniNotlar.isEmpty && esEkle.isEmpty && esKaldir.isEmpty;
      // Kapanış animasyonu sırasında ikinci dokunuş alt çubuktaki "AI Takım
      // Kur"a düşüyordu (denetim #3 O7).
      _kartKapaniyor = true;
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _kartKapaniyor = false);
      });
      Navigator.pop(sheetCtx, 'kaydedildi');
      if (bosMu) return;
      // Başarı için hiç geri bildirim yoktu (denetim #4 O1).
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${o.gorunenAd} kaydedildi'),
        duration: const Duration(seconds: 2),
      ));
      // Beklenmiyor: çevrimdışıyken kuyruğa girer, bağlanınca gider
      // (kalıcı önbellek açık). Hata gelirse kullanıcıya söylenir.
      unawaited(_db
          .ogrenciFarklariniYaz(
            widget.sinifId, o.id,
            alanlar: alanlar,
            kalemFarklari: farklar,
            saglikFarki: o.saglikDurumu - ilkSaglik,
            yeniSaglikNotlari: yeniNotlar,
            esEkle: esEkle,
            esKaldir: esKaldir,
          )
          .catchError((e) => _hataGoster('Kaydedilemedi: öğrenci silinmiş ya da bağlantı sorunu olabilir.')));
    }

    Widget bolumBasligi(String metin, {IconData? ikon}) => Padding(
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 8),
          child: Row(children: [
            if (ikon != null) ...[
              Icon(ikon, size: 19, color: context.renk.metin),
              const SizedBox(width: 6),
            ],
            // Küçük harf aralıklı büyük harf yerine Fredoka başlık (Teneffüs).
            Text(metin[0] + trKucult(metin.substring(1)),
                style: TextStyle(
                    fontFamily: AppTema.baslikFontu, fontSize: 18, fontWeight: FontWeight.w600,
                    color: context.renk.metin)),
          ]),
        );

    InputDecoration alanDeko(String etiket) => InputDecoration(
          labelText: etiket,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          isDense: true,
          // Çerçeve temadan (mürekkep kenarlı); eski ince gri kenar koyu
          // temada 1,5:1'di (denetim #3).
        );

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final r = sheetCtx.renk;
          final esAdlari = o.eslesenIdler
              .map((eid) => tumOgrenciler.where((p) => p.id == eid).map((p) => p.gorunenAd).join())
              .where((a) => a.isNotEmpty)
              .toList();
          final ozet = [
            '${o.puan} puan',
            if (o.element != null) 'Element: ${ElementSistemi.etiket(o.element)}',
            if (esAdlari.isNotEmpty) 'Eşli: ${esAdlari.join(', ')}',
          ].join('  ·  ');
          return Padding(
            // Klavye açılınca alt çubuk ve alan görünür kalsın.
            padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 560,
                  maxHeight: MediaQuery.of(sheetCtx).size.height * 0.92,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: r.sayfa,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    border: Border.all(color: r.kenar, width: 2.5),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: r.cizgi, borderRadius: BorderRadius.circular(2)),
                    ),
                    // Başlık
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                      child: Row(children: [
                        // Listedeki renkli baş harf yuvarlağı, büyük.
                        Container(
                          width: 58, height: 58,
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            color: AppTema.ogrenciRengi(o.id, _renkler),
                            shape: const CircleBorder(side: BorderSide(color: AppTema.ana, width: 2.5)),
                            shadows: const [BoxShadow(color: AppTema.ana, offset: Offset(3, 3))],
                          ),
                          child: Text(basHarfler(o.gorunenAd),
                              textScaler: TextScaler.noScaling,
                              style: const TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 21, fontWeight: FontWeight.w600, color: AppTema.ana)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Semantics(
                                label: o.isMale ? 'Erkek öğrenci' : 'Kız öğrenci',
                                child: CinsiyetSimgesi(o.isMale, boyut: 20),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(o.gorunenAd, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 24, fontWeight: FontWeight.w600, color: r.metin)),
                              ),
                            ]),
                            Text(ozet, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: r.metinIkincil)),
                          ]),
                        ),
                        IconButton(
                          tooltip: 'Kapat',
                          icon: Icon(Icons.close_rounded, color: r.metin),
                          style: IconButton.styleFrom(
                            backgroundColor: r.kart,
                            side: BorderSide(color: r.kenar, width: 2),
                          ),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ]),
                    ),
                    // Gövde
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          // 1. Kontrol kalemleri — derste en sık dokunulan yer, en üstte.
                          bolumBasligi('KONTROL KALEMLERİ', ikon: Icons.fact_check_rounded),
                          if (_kontrolKalemleri.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('Bu sınıfta kontrol kalemi yok. ⋮ menüsünden ekleyebilirsin.',
                                  style: TextStyle(color: r.metinIkincil, fontSize: 13)),
                            ),
                          Cikartma(
                            kayma: 3,
                            yaricap: 20,
                            dolgu: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Column(children: [
                              for (final k in _kontrolKalemleri) ...[
                                _artieksi(
                                  k.ikon,
                                  _kalemRengi(k),
                                  k.tip == KalemTipi.sayac ? k.ad : '${k.ad} (eksik)',
                                  o.kalemDeger(k.id),
                                  (v) => setSheetState(() => o.kalemArti(k.id, v)),
                                ),
                                Divider(height: 1, color: r.cizgi),
                              ],
                              _saglikSatiri(o, setSheetState),
                            ]),
                          ),

                          // 2. Not
                          bolumBasligi('NOT', ikon: Icons.sticky_note_2_rounded),
                          TextField(
                            controller: nC,
                            readOnly: demo,
                            maxLength: GirdiSiniri.ogrenciNotu,
                            buildCounter: gizliSayac,
                            minLines: 3,
                            maxLines: 3,
                            decoration: alanDeko('Özel Not').copyWith(
                              hintText: demo ? 'Demo modunda notlar gizli' : 'Yalnız sen görürsün',
                              hintStyle: TextStyle(color: r.metinUcuncul),
                            ),
                          ),

                          // 3. Rozetler — anında yazılır
                          bolumBasligi('ROZETLER', ikon: Icons.emoji_events_rounded),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            ...o.rozetler.reversed.map((rz) => Chip(
                                  label: Text(Ogrenci.rozetTanimlari[rz['rozet']] ?? rz['rozet'].toString(),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                  backgroundColor: r.kart,
                                  deleteButtonTooltipMessage: 'Rozeti kaldır',
                                  onDeleted: () => _rozetSilOnay(o, rz, setSheetState),
                                )),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 18, color: AppTema.ana),
                              label: const Text('Rozet Ver',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTema.ana)),
                              backgroundColor: const Color(0xFFFFD84D),
                              onPressed: () => _rozetVerDialog(o, setSheetState),
                            ),
                          ]),

                          // 4. Takım kurma
                          bolumBasligi('TAKIM KURMA', ikon: Icons.groups_rounded),
                          Row(children: [
                            SizedBox(width: 56, child: Text('Element', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: r.metinIkincil))),
                            ...ElementSistemi.ikonlar.entries.map((e) {
                              final secili = o.element == e.key;
                              final renk = ElementSistemi.renkler[e.key]!;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Semantics(
                                  button: true,
                                  selected: secili,
                                  label: 'Element: ${ElementSistemi.etiketler[e.key] ?? e.key}',
                                  excludeSemantics: true,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () => setSheetState(() => o.element = secili ? null : e.key),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 48, height: 48,
                                      decoration: ShapeDecoration(
                                        color: secili ? renk : r.kart,
                                        shape: CircleBorder(side: BorderSide(color: secili ? AppTema.ana : r.kenar, width: secili ? 2.5 : 2)),
                                        shadows: secili ? const [BoxShadow(color: AppTema.ana, offset: Offset(2, 2))] : null,
                                      ),
                                      child: Center(child: Icon(e.value, size: 24, color: secili ? Colors.white : renk)),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ]),
                          const SizedBox(height: 10),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            SizedBox(width: 56, child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text('Eşleş', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: r.metinIkincil)),
                            )),
                            Expanded(
                              child: Wrap(spacing: 6, runSpacing: 6, children: [
                                ...o.eslesenIdler.map((eid) {
                                  final eslerAday = tumOgrenciler.where((p) => p.id == eid);
                                  final ad = eslerAday.isNotEmpty ? eslerAday.first.gorunenAd : "?";
                                  return Chip(
                                    avatar: const Icon(Icons.link_rounded, size: 16),
                                    label: Text(ad, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    backgroundColor: r.vurguZemin,
                                    deleteButtonTooltipMessage: '$ad ile eşleşmeyi kaldır',
                                    onDeleted: () => setSheetState(() {
                                      o.eslesenIdler.remove(eid);
                                      if (eslerAday.isNotEmpty) eslerAday.first.eslesenIdler.remove(o.id);
                                      dokunulanEslerinIdleri.add(eid);
                                    }),
                                  );
                                }),
                                ActionChip(
                                  avatar: const Icon(Icons.add, size: 16),
                                  label: const Text("Ekle", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                  onPressed: () => _eslesenSecDialog(
                                    sheetCtx, o, tumOgrenciler, setSheetState, dokunulanEslerinIdleri,
                                  ),
                                ),
                              ]),
                            ),
                          ]),
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('Çatışan elementler ayrı takıma, eşleşenler aynı takıma düşer.',
                                style: TextStyle(fontSize: 12, color: r.metinUcuncul)),
                          ),

                          // 5. Kimlik — en nadir değişen alanlar en altta.
                          bolumBasligi('BİLGİLER', ikon: Icons.badge_rounded),
                          if (o.oncekiKayit != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(children: [
                                Icon(Icons.history_rounded, size: 16, color: r.metinUcuncul),
                                const SizedBox(width: 6),
                                Text("Geçen yıl: ${o.oncekiKayit!['sinifAd']}"
                                    "${o.oncekiKayit!['egitimYili'] != null ? ' (${o.oncekiKayit!['egitimYili']})' : ''}",
                                    style: TextStyle(fontSize: 13, color: r.metinIkincil)),
                              ]),
                            ),
                          TextField(
                            controller: adC,
                            readOnly: demo,
                            maxLength: GirdiSiniri.ogrenciAdi,
                            buildCounter: gizliSayac,
                            textCapitalization: TextCapitalization.words,
                            decoration: alanDeko('İsim').copyWith(
                              helperText: demo ? 'Demo modunda ad düzenlenemez' : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: TextField(
                                controller: pC,
                                maxLength: GirdiSiniri.puanBasamak,
                                buildCounter: gizliSayac,
                                keyboardType: TextInputType.number,
                                decoration: alanDeko('Yetenek Puanı'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _genderChip("Erkek", true, o.isMale, () => setSheetState(() => o.isMale = true)),
                            const SizedBox(width: 6),
                            _genderChip("Kız", false, !o.isMale, () => setSheetState(() => o.isMale = false)),
                          ]),
                        ]),
                      ),
                    ),
                    // Alt eylem çubuğu
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                      decoration: BoxDecoration(
                        color: r.sayfa,
                        border: Border(top: BorderSide(color: r.cizgi, width: 1.5)),
                      ),
                      child: Row(children: [
                        TextButton.icon(
                          onPressed: () => _ogrenciSilOnay(sheetCtx, o),
                          icon: Icon(Icons.delete_rounded, color: r.tehlike),
                          label: Text("Sil", style: TextStyle(color: r.tehlike, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: const Text("İptal"),
                        ),
                        // 3,5 px'ti (denetim #3).
                        const SizedBox(width: 10),
                        SertGolgeli(
                          kayma: 3,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                            ),
                            onPressed: () => kaydet(sheetCtx),
                            child: const Text("Kaydet"),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    ).then((sonuc) {
      if (sonuc != 'kaydedildi') geriAl();
      adC.dispose(); pC.dispose(); nC.dispose();
    });
  }

  /// [o] öğrencisini sınıftaki bir başkasıyla eşleştirmek/eşleşmeyi
  /// kaldırmak için seçim penceresi. Karşılıklı bağlantıyı bellekte kurar;
  /// asıl Firestore yazımı _ogrenciKartiAc'taki Kaydet'te olur.
  void _eslesenSecDialog(
    BuildContext context,
    Ogrenci o,
    List<Ogrenci> tumOgrenciler,
    StateSetter disDialogState,
    Set<String> dokunulanEslerinIdleri,
  ) {
    final adaylar = tumOgrenciler.where((p) => p.id != o.id).toList()
      ..sort((a, b) => trKarsilastir(a.gorunenAd, b.gorunenAd));
    final adlar = {for (final p in tumOgrenciler) p.id: p.gorunenAd};
    // 30 kişilik sınıfta arama olmadan kullanılamıyordu; başkasıyla eşli
    // adaylar da ayırt edilmiyordu (denetim O4).
    String arama = '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) {
          final gorunen = arama.isEmpty
              ? adaylar
              : adaylar.where((p) => trKucult(p.gorunenAd).contains(arama)).toList();
          return AlertDialog(
          title: const Text("Kiminle Eşleştir?"),
          content: SizedBox(
            width: 320,
            height: 400,
            child: adaylar.isEmpty
                ? const Center(child: Text("Sınıfta başka öğrenci yok"))
                : Column(children: [
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setPickerState(() => arama = trKucult(v)),
                      decoration: InputDecoration(
                        hintText: 'Öğrenci ara...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: ListView.builder(
                    itemCount: gorunen.length,
                    itemBuilder: (_, i) {
                      final p = gorunen[i];
                      final secili = o.eslesenIdler.contains(p.id);
                      final digerEsler = p.eslesenIdler.where((eid) => eid != o.id).map((eid) => adlar[eid] ?? '?').toList();
                      return CheckboxListTile(
                        value: secili,
                        title: Text(p.gorunenAd),
                        subtitle: digerEsler.isEmpty
                            ? null
                            : Text('Zaten eşli: ${digerEsler.join(', ')}',
                                style: TextStyle(fontSize: 12, color: ctx.renk.metinIkincil)),
                        onChanged: (_) {
                          setPickerState(() {
                            if (secili) {
                              o.eslesenIdler.remove(p.id);
                              p.eslesenIdler.remove(o.id);
                            } else {
                              o.eslesenIdler.add(p.id);
                              p.eslesenIdler.add(o.id);
                            }
                            dokunulanEslerinIdleri.add(p.id);
                          });
                          disDialogState(() {});
                        },
                      );
                    },
                  )),
                  ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Kapat")),
          ],
        );
        },
      ),
    );
  }

  Widget _genderChip(String label, bool erkek, bool selected, VoidCallback onTap) {
    final color = CinsiyetSimgesi.rengi(erkek);
    return GestureDetector(
      onTap: onTap,
      // Seçili hap limon sarısı + mürekkep kenar; kenar kalınlığı sabit
      // (seçilince 2 px zıplıyordu, denetim #3).
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: ShapeDecoration(
          color: selected ? const Color(0xFFFFD84D) : context.renk.kart,
          shape: StadiumBorder(side: BorderSide(color: selected ? AppTema.ana : context.renk.kenar, width: 2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CinsiyetSimgesi(erkek, boyut: 18, renk: selected ? AppTema.ana : color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              color: selected ? AppTema.ana : context.renk.metin,
              fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  void _ogrenciSilOnay(BuildContext dialogContext, Ogrenci o) {
    showDialog(
      context: dialogContext,
      builder: (c2) => AlertDialog(
        title: const Text("Öğrenciyi Sil"),
        content: Text("${o.gorunenAd} isimli öğrenciyi kalıcı olarak silmek istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c2), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c2.renk.silDolgu, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await _db.ogrenciSil(widget.sinifId, o.id,
                  partnerIdler: _tumOgrenciler.where((p) => p.eslesenIdler.contains(o.id)).map((p) => p.id).toList());
              if (c2.mounted) Navigator.pop(c2);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text("Evet, Sil", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // --- HIZLI ÖĞRENCİ EKLE (İsim kontrolü ile) ---
  void _hizliSinifEkleDialog() {
    final uid = AuthService().uid;
    final taslak = TopluEklemeTaslagi.geriYukle(uid, widget.sinifId);
    // Boş satır eklenmeden önce say: `satirlar` taslak listesinin kendisi.
    final geriYuklenen = taslak?.length ?? 0;
    List<TopluOgrenciSatiri> satirlar = taslak ?? List.generate(5, (i) => TopluOgrenciSatiri());
    // Taslaktan dönülünce boş satır bırak, öğretmen kaldığı yerden yazsın.
    while (taslak != null && satirlar.length < 5) {
      satirlar.add(TopluOgrenciSatiri());
    }
    final durum = _TopluKayitDurumu();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final r = sheetContext.renk;
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: r.sayfa,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
              border: Border.all(color: r.kenar, width: 2.5),
            ),
            child: Column(
              children: [
                Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                    decoration: BoxDecoration(color: r.cizgi, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [
                    Icon(Icons.group_add_rounded, color: r.metin, size: 28),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: Text("Hızlı Öğrenci Ekle",
                            style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 24, fontWeight: FontWeight.w600))),
                  ]),
                ),
                if (geriYuklenen > 0 && !durum.taslakTemizlendi)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(children: [
                      Icon(Icons.history_rounded, size: 18, color: r.metinIkincil),
                      const SizedBox(width: 8),
                      Expanded(child: Text("Kaydedilmemiş $geriYuklenen isim geri getirildi.",
                          style: TextStyle(color: r.metinIkincil, fontSize: 13))),
                      TextButton(
                        onPressed: durum.kaydediyor ? null : () => setSheetState(() {
                          final eski = List.of(satirlar);
                          satirlar
                            ..clear()
                            ..addAll(List.generate(5, (i) => TopluOgrenciSatiri()));
                          durum.taslakTemizlendi = true;
                          TopluEklemeTaslagi.sil(uid, widget.sinifId);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            for (final e in eski) {
                              e.dispose();
                            }
                          });
                        }),
                        child: const Text("Temizle"),
                      ),
                    ]),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: Text("Ad Soyad", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: r.metinIkincil, letterSpacing: 0.3))),
                    SizedBox(width: 52, child: Center(child: Text("Cins.", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: r.metinIkincil)))),
                    SizedBox(width: 54, child: Center(child: Text("Puan", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: r.metinIkincil, letterSpacing: 0.3)))),
                    const SizedBox(width: 36),
                  ]),
                ),
                const Divider(height: 12),
                Expanded(
                  child: ListView(
                    // iPhone Safari'de (web) klavye yüksekliği gelmiyor
                    // (viewInsets 0); son satırlar klavyenin altında kalıp
                    // yukarı kaydırılamıyordu (Sabri'nin ekranı, iPad'de
                    // "~10. öğrencide takılıyor"). Web'de yarım ekran pay.
                    padding: EdgeInsets.fromLTRB(16, 4, 16,
                        kIsWeb
                            ? MediaQuery.of(sheetContext).size.height * 0.5
                            : MediaQuery.of(sheetContext).viewInsets.bottom + 16),
                    children: List.generate(satirlar.length, (i) {
                      final satir = satirlar[i];
                      void scrollToRow() {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final ctx = satir.rowKey.currentContext;
                          if (ctx != null) {
                            // Listenin ÜSTÜNE hizala: alta hizalayınca satır
                            // klavyenin tam arkasına düşüyordu.
                            Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut, alignment: 0.08);
                          }
                        });
                      }
                      return Padding(
                        key: satir.rowKey,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          SizedBox(width: 24, child: Text("${i + 1}", style: TextStyle(color: r.metinUcuncul, fontWeight: FontWeight.w600))),
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: satir.adCtrl,
                              onTap: scrollToRow,
                              textCapitalization: TextCapitalization.words,
                              maxLength: GirdiSiniri.ogrenciAdi,
                              buildCounter: gizliSayac,
                              decoration: InputDecoration(
                                hintText: "Ad Soyad",
                                hintStyle: TextStyle(color: r.metinUcuncul, fontSize: 14),
                                // Çerçeve ve dolgu temadan (mürekkep kenar, beyaz).
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
                              ),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            button: true,
                            label: 'Cinsiyet: ${!satir.cinsiyetSecildi ? "seçilmedi" : (satir.isMale ? "erkek" : "kız")}, değiştirmek için dokun',
                            excludeSemantics: true,
                            child: GestureDetector(
                            onTap: () => setSheetState(() {
                              if (!satir.cinsiyetSecildi) {
                                satir.cinsiyetSecildi = true;
                              } else {
                                satir.isMale = !satir.isMale;
                              }
                            }),
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: !satir.cinsiyetSecildi
                                    ? r.kart
                                    : (satir.isMale ? const Color(0xFF4FA3F7) : const Color(0xFFFF8FB1)),
                                shape: BoxShape.circle,
                                border: Border.all(color: r.kenar, width: 2),
                              ),
                              child: Center(
                                child: !satir.cinsiyetSecildi
                                    ? Icon(Icons.question_mark_rounded, size: 18, color: r.metinUcuncul)
                                    : CinsiyetSimgesi(satir.isMale, boyut: 22, renk: AppTema.ana),
                              ),
                            ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 54,
                            child: TextField(
                              controller: satir.puanCtrl,
                              onTap: scrollToRow,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: GirdiSiniri.puanBasamak,
                              buildCounter: gizliSayac,
                              decoration: InputDecoration(
                                hintText: "100",
                                hintStyle: TextStyle(color: r.metinUcuncul, fontWeight: FontWeight.w600),
                                // Çerçeve ve dolgu temadan (mürekkep kenar, beyaz).
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.red.shade300, size: 20),
                            tooltip: 'Satırı sil',
                            onPressed: () {
                              setSheetState(() => satirlar.remove(satir));
                              // Önce listeden çıkar/rebuild et, controller'ı sonra dispose et.
                              WidgetsBinding.instance.addPostFrameCallback((_) => satir.dispose());
                            },
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          ),
                        ]),
                      );
                    })..add(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: TextButton.icon(
                            // Üst sınır: tek seferde çok fazla satır hem UI'ı
                            // dondurur hem Firestore batch sınırını zorlar.
                            onPressed: satirlar.length >= GirdiSiniri.topluEklemeMaxSatir
                                ? null
                                : () => setSheetState(() => satirlar.add(TopluOgrenciSatiri())),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(
                                satirlar.length >= GirdiSiniri.topluEklemeMaxSatir
                                    ? "Satır sınırına ulaşıldı (${GirdiSiniri.topluEklemeMaxSatir})"
                                    : "Satır Ekle",
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              foregroundColor: r.vurgu,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: r.ikonAna.withAlpha(60), width: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  decoration: BoxDecoration(
                    color: r.kartUstu,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, -2))],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (durum.hata != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Icon(Icons.error_outline_rounded, size: 18, color: r.yokMetin),
                        const SizedBox(width: 8),
                        Expanded(child: Text(durum.hata!, style: TextStyle(color: r.yokMetin, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  Row(children: [
                    Text("${satirlar.length} satır", style: TextStyle(color: r.metinIkincil, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: durum.kaydediyor ? null : () => Navigator.pop(sheetContext),
                      child: Text("İptal", style: TextStyle(color: r.metinIkincil)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: r.vurgu, foregroundColor: r.vurguMetin,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), elevation: 2,
                      ),
                      icon: durum.kaydediyor
                          ? SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: r.vurguMetin))
                          : const Icon(Icons.save_rounded, size: 20),
                      label: Text(durum.kaydediyor ? "Kaydediliyor…" : "Tümünü Kaydet",
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: durum.kaydediyor
                          ? null
                          : () => _topluKaydet(satirlar, sheetContext, durum, setSheetState),
                    ),
                  ]),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      // Kaydedilmeden kapandıysa (İptal, dışarı dokunma, hata) yazılanlar
      // bellekte kalsın; aynı sınıfta yeniden açınca geri gelir.
      // Kayıt sürerken dışarı dokunup kapatıldıysa da saklama: yazma devam
      // ediyor, taslak kalırsa aynı isimler ikinci kez kaydedilebilir.
      if (durum.kaydedildi || durum.kaydediyor) {
        TopluEklemeTaslagi.sil(uid, widget.sinifId);
      } else {
        TopluEklemeTaslagi.sakla(uid, widget.sinifId, satirlar);
      }
      // .then() pop anında çalışır ama sheet kapanış animasyonu (~250ms)
      // henüz bitmemiştir; TextField'lar animasyon boyunca hâlâ bu
      // controller'lara bağlı. Animasyon bitene kadar bekleyip dispose et,
      // aksi halde "TextEditingController used after disposed" hatası olur.
      Future.delayed(const Duration(milliseconds: 500), () {
        for (final s in satirlar) {
          s.dispose();
        }
      });
    });
  }

  /// Toplu ekleme. Bu metot `onPressed` içinden await edilmeden çağrılıyor;
  /// gövdesi try/catch ile sarılmazsa bir hata (ağ kopması, kural reddi)
  /// sessizce yutulur ve kullanıcı ne başarı ne hata mesajı görür.
  ///
  /// Hata olunca pencere KAPANMAZ: önceden kapanıyordu ve yazılan isimler
  /// gidiyordu, öğretmen baştan yazmak zorunda kalıyordu (2 Eki 2026).
  Future<void> _topluKaydet(List<TopluOgrenciSatiri> satirlar, BuildContext sheetContext,
      _TopluKayitDurumu durum, StateSetter setSheetState) async {
    // Yavaş bağlantıda çift dokunuş işlemi iki kez koşturuyordu (denetim #3 Y8).
    if (durum.kaydediyor) return;
    setSheetState(() {
      durum.kaydediyor = true;
      durum.hata = null;
    });
    try {
      await _topluKaydetYurut(satirlar, sheetContext, durum);
    } catch (_) {
      if (sheetContext.mounted) {
        setSheetState(() => durum.hata = "Kaydedilemedi. İsimler duruyor, tekrar dene.");
      }
    } finally {
      if (sheetContext.mounted) setSheetState(() => durum.kaydediyor = false);
    }
  }

  Future<void> _topluKaydetYurut(List<TopluOgrenciSatiri> satirlar,
      BuildContext sheetContext, _TopluKayitDurumu durum) async {
    int eklenen = 0;
    int atlanan = 0;
    // Sunucu 10 sn'de onay vermezse yazma kuyrukta sayılır: kalıcı önbellek
    // açık, kayıt cihazda yapıldı, bağlantı gelince gider. Önceden süresiz
    // bekliyordu ve pencere takılı kalıyordu (yoklama ekranıyla aynı kalıp).
    bool kuyrukta = false;
    Future<void> yaz(List<Ogrenci> liste) async {
      try {
        await _db.ogrencilerTopluEkle(widget.sinifId, liste)
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        kuyrukta = true;
      }
    }

    // Tüm mevcut isimleri tek sorguda al; sunucu yavaşsa cihazdaki kopya
    Set<String> mevcutAdlar;
    try {
      mevcutAdlar = await _db.mevcutOgrenciAdlari(widget.sinifId)
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      mevcutAdlar = await _db.mevcutOgrenciAdlari(widget.sinifId, sadeceOnbellek: true);
    }

    // Yeni ve çakışan öğrencileri ayır
    final yeniOgrenciler = <Ogrenci>[];
    final cakisanSatirlar = <TopluOgrenciSatiri>[];
    final cakisanlar = <String>[];

    for (var s in satirlar) {
      final ad = s.adCtrl.text.trim();
      if (ad.isEmpty) continue;

      if (mevcutAdlar.contains(ad)) {
        cakisanlar.add(ad);
        cakisanSatirlar.add(s);
      } else {
        yeniOgrenciler.add(Ogrenci(
          id: '', ad: ad, isMale: s.isMale,
          puan: int.tryParse(s.puanCtrl.text) ?? 100,
        ));
      }
    }

    // Yeni öğrencileri toplu ekle
    if (yeniOgrenciler.isNotEmpty) {
      await yaz(yeniOgrenciler);
      eklenen = yeniOgrenciler.length;
    }

    // Çakışanları sor
    if (cakisanlar.isNotEmpty && sheetContext.mounted) {
      final devamEt = await showDialog<bool>(
        context: sheetContext,
        builder: (c) {
          final r = c.renk;
          return AlertDialog(
          title: Row(children: [
            Icon(Icons.warning_amber_rounded, color: r.ikonAna),
            const SizedBox(width: 8),
            const Text("Aynı İsim Var", style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Bu isimlerle zaten kayıtlı öğrenci var:", style: TextStyle(color: r.metinGovde)),
            const SizedBox(height: 12),
            ...cakisanlar.map((ad) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.person, color: r.ikonAna, size: 18),
                const SizedBox(width: 8),
                Text(ad, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            )),
            const SizedBox(height: 12),
            Text("Yine de ekleyelim mi?", style: TextStyle(color: r.metinIkincil)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text("Atla", style: TextStyle(color: r.metinIkincil))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: r.vurgu, foregroundColor: r.vurguMetin,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(c, true),
              child: const Text("Yine de Ekle", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
        },
      );

      if (devamEt == true) {
        final cakisanOgrenciler = cakisanSatirlar.map((s) => Ogrenci(
          id: '', ad: s.adCtrl.text.trim(), isMale: s.isMale,
          puan: int.tryParse(s.puanCtrl.text) ?? 100,
        )).toList();
        await yaz(cakisanOgrenciler);
        eklenen += cakisanOgrenciler.length;
      } else {
        atlanan = cakisanlar.length;
      }
    }

    // Not: controller dispose'u sheet kapanışındaki .then() içinde yapılıyor.
    durum.kaydedildi = true;
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    if (mounted) {
      final ozet = atlanan > 0 ? "$eklenen eklendi, $atlanan atlandı" : "$eklenen öğrenci eklendi!";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(kuyrukta ? "$ozet Bağlantı yavaş, internet gelince gönderilecek." : ozet),
        backgroundColor: kuyrukta ? AppTema.uyari : AppTema.basari,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _renkYonetimi() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Forma Renkleri"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Wrap(
                spacing: 8, runSpacing: 8,
                children: formaRenkleri.map((r) => Chip(
                  label: Text(r),
                  backgroundColor: _takimRenginiBul(r).withAlpha(30),
                  side: BorderSide(color: _takimRenginiBul(r).withAlpha(80)),
                  deleteIconColor: Colors.red.shade400,
                  deleteButtonTooltipMessage: '$r rengini sil',
                  onDeleted: () => setDialogState(() => formaRenkleri.remove(r)),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: c,
                maxLength: GirdiSiniri.renkAdi,
                buildCounter: gizliSayac,
                decoration: InputDecoration(hintText: "Yeni Renk Ekle (Örn: Mor)",),
              ),
            ]),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: context.renk.vurgu, foregroundColor: context.renk.vurguMetin,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                if (c.text.isNotEmpty) { setDialogState(() => formaRenkleri.add(c.text)); c.clear(); setState(() {}); }
              },
              child: const Text("Ekle"),
            ),
            TextButton(
              onPressed: () { _db.formaRenkleriniGuncelle(widget.sinifId, formaRenkleri); Navigator.pop(context); },
              child: const Text("Kaydet ve Kapat", style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    ).then((_) => c.dispose());
  }

  Color _takimRenginiBul(String renkAdi) => AppTema.formaRengi(renkAdi);

  Future<void> _takimlariKur() async {
    // Forma listesi kısaldıysa sayaçta kalan eski değer sınırı aşmasın.
    secilenTakimSayisi = secilenTakimSayisi.clamp(2, _enCokTakim);
    final List<Ogrenci> gelenler;
    try {
      gelenler = (await _db.ogrencileriGetir(widget.sinifId)).where((o) => o.buradaMi).toList();
    } catch (_) {
      _hataGoster('Öğrenci listesi alınamadı. Bağlantını kontrol et.');
      return;
    }

    if (gelenler.length < secilenTakimSayisi) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("$secilenTakimSayisi takım için en az $secilenTakimSayisi gelen öğrenci gerekir (şu an ${gelenler.length})."),
          backgroundColor: AppTema.tehlike, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
      return;
    }

    // Efektif puan: gerçek puan + rastgele -4/+4
    final Map<String, int> efektifPuan = {};
    for (var o in gelenler) {
      efektifPuan[o.id] = o.puan + _random.nextInt(9) - 4;
    }

    // Kız-erkek ayır
    final kizlar = gelenler.where((o) => !o.isMale).toList();
    final erkekler = gelenler.where((o) => o.isMale).toList();

    // Her grubu efektif puana göre sırala
    kizlar.sort((a, b) => efektifPuan[b.id]!.compareTo(efektifPuan[a.id]!));
    erkekler.sort((a, b) => efektifPuan[b.id]!.compareTo(efektifPuan[a.id]!));

    // Önce kızları, sonra erkekleri dengeli dağıt
    List<List<Ogrenci>> takimlar = List.generate(secilenTakimSayisi, (_) => []);
    // Her takımın toplam efektif puanını tut
    List<int> takimPuanlari = List.filled(secilenTakimSayisi, 0);

    /// Bir oyuncunun belirli bir takıma uygunluk puanı.
    /// Aynı element: +10 (birleştirme bonusu)
    /// Çatışan element: -100 (ayırma cezası — agresif şekilde uzaklaştırır)
    /// Bu skor min-pop takımlar arasında karşılaştırılır; eşit kişi sayısı
    /// hard constraint, element uyumu soft preference.
    int elementUyumPuani(int takimIdx, Ogrenci o) {
      if (o.element == null) return 0;
      int puan = 0;
      for (final m in takimlar[takimIdx]) {
        if (m.element == null) continue;
        if (m.element == o.element) {
          puan += 10;
        } else if (ElementSistemi.catisir(o.element, m.element)) {
          puan -= 100;
        }
      }
      return puan;
    }

    /// Elle eşleştirilmiş öğrenciler (bkz. Ogrenci.eslesenIdler) aynı takıma
    /// düşsün diye element bonusundan çok daha ağır basan bir puan verir —
    /// ama yine de takım sayısı dengesinin (1. adımdaki hard constraint)
    /// önüne geçmez.
    int eslesUyumPuani(int takimIdx, Ogrenci o) {
      if (o.eslesenIdler.isEmpty) return 0;
      int puan = 0;
      for (final m in takimlar[takimIdx]) {
        if (o.eslesenIdler.contains(m.id)) puan += 1000;
      }
      return puan;
    }

    // Eşli öğrenciler (Ogrenci.eslesenIdler) TEK BİRİM olarak yerleşir:
    // biri yerleşince partnerleri de aynı takıma alınır. Eskiden partner
    // yalnızca "en az kişili takımlar" kümesindeyse +1000 puan işliyordu;
    // kızlar puan sırasıyla dizilirken partner bir önceki adımda takımı
    // doldurunca bonus hiç devreye girmiyor, 8 dağıtımın 3'ünde ikili
    // ayrılıyordu (denetim Y1). Şimdi geçici +1 dengesizlik sonraki
    // yerleşimlerle kapanıyor; nihai fark ≤ birim büyüklüğü.
    final gelenIdler = {for (final o in gelenler) o.id: o};
    final yerlesti = <String>{};
    void birimiYerlestir(int hedef, Ogrenci o) {
      if (yerlesti.contains(o.id)) return;
      yerlesti.add(o.id);
      takimlar[hedef].add(o);
      takimPuanlari[hedef] += efektifPuan[o.id]!;
      for (final eid in o.eslesenIdler) {
        final es = gelenIdler[eid];
        if (es != null) birimiYerlestir(hedef, es);
      }
    }

    void dengeliDagit(List<Ogrenci> liste) {
      for (var o in liste) {
        if (yerlesti.contains(o.id)) continue;
        // 1. HARD: En az kişiye sahip takımları bul (count balance ≤ 1)
        final minKisi = takimlar.map((t) => t.length).reduce((a, b) => a < b ? a : b);
        final enAzKisiTakimlar = <int>[
          for (var t = 0; t < secilenTakimSayisi; t++)
            if (takimlar[t].length == minKisi) t,
        ];

        // 2. SOFT: Her min-pop takım için eşleşme + element uyumu puanı
        final uyumPuanlari = {
          for (final t in enAzKisiTakimlar) t: eslesUyumPuani(t, o) + elementUyumPuani(t, o),
        };
        final maxUyum = uyumPuanlari.values.reduce((a, b) => a > b ? a : b);

        // En yüksek element-uyum puanına sahip takımları aday seç
        final adaylar = enAzKisiTakimlar.where((t) => uyumPuanlari[t] == maxUyum).toList();

        // 3. TIE-BREAKER: Aday takımlar arasında en düşük toplam puana sahip
        // olan (skor dengesi)
        final hedef = adaylar.reduce(
          (a, b) => takimPuanlari[a] <= takimPuanlari[b] ? a : b,
        );
        birimiYerlestir(hedef, o);
      }
    }

    // İfadeli ya da eşli öğrenciler önce yerleşir: elementsiz bir öğrenci
    // beraberliği bozunca su için tek aday kalıyor, o da ateşin takımı
    // oluyordu — 1000 denemede %10-24 çatışma (denetim #3 Y7). Bu sıralamayla
    // 0/1000; puan dengesi değişmiyor (test/takim_kurma_test.dart).
    bool kisitli(Ogrenci o) => o.element != null || o.eslesenIdler.isNotEmpty;
    List<Ogrenci> kisitlilarOnce(List<Ogrenci> l) => [...l.where(kisitli), ...l.where((o) => !kisitli(o))];
    dengeliDagit(kisitlilarOnce(kizlar));
    dengeliDagit(kisitlilarOnce(erkekler));

    final takimIsimleri = _rastgeleTakimIsimleri(secilenTakimSayisi);
    if (!mounted) return;

    // TakimBilgi listesi oluştur (skor ekranı için de kullanılacak)
    final takimBilgileri = <TakimBilgi>[];
    for (int i = 0; i < secilenTakimSayisi; i++) {
      String takimRenkAdi = formaRenkleri.length > i ? formaRenkleri[i] : 'Siyah';
      Color gorselRenk = _takimRenginiBul(takimRenkAdi);
      String komikIsim = takimIsimleri.length > i ? takimIsimleri[i] : "Bilinmeyen";
      final takim = takimlar[i];
      Ogrenci? kaptan;
      if (takim.isNotEmpty) {
        kaptan = takim[Random().nextInt(takim.length)];
      }
      takimBilgileri.add(TakimBilgi(
        isim: komikIsim, renkAdi: takimRenkAdi, renk: gorselRenk,
        oyuncular: takim, kaptan: kaptan,
      ));
    }

    unawaited(AnalyticsService.takimKuruldu(takimSayisi: secilenTakimSayisi, oyuncuSayisi: gelenler.length));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: sheetCtx.renk.sayfa,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          border: Border.all(color: sheetCtx.renk.kenar, width: 2.5),
        ),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: sheetCtx.renk.cizgi, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Takım Dağılımı",
                    style: TextStyle(fontFamily: AppTema.baslikFontu, fontSize: 26, fontWeight: FontWeight.w600)),
                Text("${gelenler.length} öğrenci  •  $secilenTakimSayisi takım",
                    style: TextStyle(color: sheetCtx.renk.metinIkincil, fontWeight: FontWeight.w700)),
              ]),
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: sheetCtx.renk.metin, size: 28),
                tooltip: "Yeniden Karıştır",
                style: IconButton.styleFrom(
                  backgroundColor: sheetCtx.renk.kart,
                  side: BorderSide(color: sheetCtx.renk.kenar, width: 2.5),
                  minimumSize: const Size(52, 52),
                ),
                onPressed: () { Navigator.pop(sheetCtx); _takimlariKur(); },
              ),
            ]),
          ),
          const Divider(),
          // Takım kartları: içeriğe göre boy, en çok 2 sütun. Sabit oranlı
          // ızgarada 1,5x yazıda oyuncular kesiliyor, 4 takımda kartların
          // yarısı boş kalıyordu (denetim #3).
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: LayoutBuilder(builder: (context, c) {
                final sutun = takimBilgileri.length < 2 ? 1 : 2;
                final w = (c.maxWidth - 8 * (sutun - 1)) / sutun;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in takimBilgileri)
                      SizedBox(width: w, child: _dagilimKarti(t, efektifPuan)),
                  ],
                );
              }),
            ),
          ),
          // Oyunu Başlat butonu
          Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: SertGolgeli(
              child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sports_rounded, size: 26),
                label: const Text("Oyunu Başlat", style: TextStyle(fontSize: 20)),
                onPressed: () async {
                  // Süren bir etkinlik varken onaysız üstüne yazılıyordu;
                  // Sınıflarım'daki "Etkinliği Bitir" ise onay istiyor (denetim O2).
                  if (MacDurumu().aktif) {
                    final onay = await showDialog<bool>(
                      context: sheetCtx,
                      builder: (c) => AlertDialog(
                        title: const Text('Süren etkinlik silinsin mi?'),
                        content: const Text('Devam eden etkinliğin skoru ve süresi silinip yeni oyun başlatılacak.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: TextButton.styleFrom(foregroundColor: c.renk.tehlike),
                            child: const Text('Yeni oyunu başlat'),
                          ),
                        ],
                      ),
                    );
                    if (onay != true || !sheetCtx.mounted || !mounted) return;
                  }
                  Navigator.pop(sheetCtx);
                  MacDurumu().macBaslat(widget.sinifId, takimBilgileri);
                  unawaited(AnalyticsService.macBasladi(takimSayisi: secilenTakimSayisi, oyuncuSayisi: gelenler.length));
                  unawaited(Navigator.push<String>(context, MaterialPageRoute(
                    builder: (_) => SkorEkrani(takimlar: takimBilgileri),
                  )).then((sonuc) {
                    if (sonuc != 'geridon') MacDurumu().macBitir();
                    setState(() {});
                  }));
                },
              ),
            ),
            ),
          ),
        ]),
      ),
    ).ignore();
  }

  Widget _dagilimKarti(TakimBilgi t, Map<String, int> efektifPuan) {
    final r = context.renk;
    // Sarı formada beyaz metin 1,6:1'di (denetim Y4).
    final metin = AppTema.ustMetin(t.renk);
    final puan = t.oyuncular.fold<int>(0, (toplam, o) => toplam + (efektifPuan[o.id] ?? o.puan));
    return Cikartma(
      kayma: 3,
      yaricap: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: t.renk,
              border: Border(bottom: BorderSide(color: r.kenar, width: 2)),
            ),
            child: Column(children: [
              Text(t.isim,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: AppTema.baslikFontu, color: metin, fontWeight: FontWeight.w600, fontSize: 18, height: 1.1)),
              const SizedBox(height: 2),
              // Tek satırda "(795 pu…" diye kesiliyordu (denetim #3).
              Text("${t.renkAdi} · ${t.oyuncular.length} kişi",
                  textAlign: TextAlign.center, style: TextStyle(color: metin, fontSize: 13, fontWeight: FontWeight.w700)),
              Text("$puan puan",
                  textAlign: TextAlign.center, style: TextStyle(color: metin, fontSize: 13, fontWeight: FontWeight.w800)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Column(children: [
              for (final o in t.oyuncular)
                Builder(builder: (_) {
                  final isKaptan = t.kaptan != null && o.id == t.kaptan!.id;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Container(
                        width: 28, height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTema.ogrenciRengi(o.id, _renkler),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTema.ana, width: 1.5),
                        ),
                        child: Text(basHarfler(o.gorunenAd),
                            textScaler: TextScaler.noScaling,
                            style: const TextStyle(
                                fontFamily: AppTema.baslikFontu, fontSize: 11, fontWeight: FontWeight.w600, color: AppTema.ana)),
                      ),
                      const SizedBox(width: 6),
                      CinsiyetSimgesi(o.isMale, boyut: 14),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(o.gorunenAd,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isKaptan ? FontWeight.w800 : FontWeight.w600,
                              color: r.metin,
                            )),
                      ),
                      // Eşleşme yalnız skor tablosunda görünüyordu (denetim O4).
                      if (o.eslesenIdler.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.link_rounded, size: 15, color: r.metinIkincil),
                        ),
                      if (isKaptan)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.star_rounded, size: 17, color: r.uyari),
                        ),
                    ]),
                  );
                }),
            ]),
          ),
        ],
      ),
    );
  }
}

/// "Hızlı Öğrenci Ekle" penceresinin kayıt durumu (pencereye özgü).
class _TopluKayitDurumu {
  bool kaydediyor = false;
  bool kaydedildi = false;
  bool taslakTemizlendi = false;
  String? hata;
}
