import '../tema.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/girdi.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ogrenci.dart';
import '../models/kontrol_kalemi.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/mac_durumu.dart';
import '../widgets/yardim_diyalogu.dart';
import 'skor_ekrani.dart';
import 'yoklama_ekrani.dart';
import 'kontrol_kalemleri_ekrani.dart';

const List<String> _takimIsimHavuzu = [
  // Oyun & internet kültürü
  "Lag Kralları", "AFK Takımı", "Respawn FC", "Noob Avcıları", "GG United",
  "Bot Ordusu", "Ctrl+Z Spor", "Alt+F4 Kalesi", "Pro Oyuncular", "Ping Canavarları",
  "Combo Kralları", "Double Kill FC", "Glitch Takımı", "Bug Avcıları",
  // Kantin & yemek teması
  "Tost Mafyası", "Ayran United", "Simit Karteli", "Poğaça Operasyonu",
  "Kantin Korsanları", "Çikolata Çetesi", "Kraker Komandoları", "Cips Fırtınası",
  "Kaşarlı Ejderhalar", "Susamlı Şimşekler", "Ketçap Canavarları", "Kola Kasırgası",
  // Okul teması
  "Teneffüs Kaplanları", "Ödev Avcıları", "Zil Korsanları", "Sınav Hayaletleri",
  "Silgi Savaşçıları", "Uçan Tebeşirler", "Mega Cetvel", "Defter Ejderhaları",
  "Çılgın Silgiler", "Kalem Açar Birliği", "Tahta Kalesi FC", "Müdür Yardımcıları",
  "Sıra Arkası Spor", "Kopya Ajanları", "Yoklama Fantastiği",
  // Absürt hayvan
  "Ninja Kaplumbağalar", "Korsan Papağanlar", "Viking Kedileri", "Şimşek Hamsterlar",
  "Perişan Penguenler", "Süpersonik Sincaplar", "Panik Ahtapotlar", "Disko Arıları",
  "Turbo Salyangozlar", "Karambol Kedileri", "Torpido Tilkileri", "Roket Tavukları",
  "Lazer Koyunları", "Bumerang Balıkları", "Tsunami Tavşanları", "Atom Karıncaları",
  "Kızgın Flamingolar", "Parkur Pandaları", "Dubstep Yunusları",
  // Absürt yemek
  "Uçan Lahmacunlar", "Galaktik Börekler", "Patlayan Mısırlar", "Meteor Kurabiyeler",
  "Kozmik Köfteciler", "Turşu Yıldızları", "Dinamit Domatesler", "Kaptan Patlıcan",
  "Fantom Peynirler", "Kızgın Bamyalar", "Fırtınalı Fasulye",
  // Absürt eşya & kavram
  "Çaydanlık United", "Ejder Çorapları", "Gizli Ajanlar FC", "Gökgürültüsü FC",
  "Buldozer Kelebekler", "Sihirli Noktalar", "Nükleer Cevizler", "Dalga Delileri",
  "Yıkılmaz Yumurtalar", "Uçan Halıcılar", "Biber Gazı Spor",
  // Epik & komik karışım
  "Meşhur Patatesler", "Efsane Peçeteler", "Korkusuz Krakerler", "Sönen Yıldızlar",
  "Asi Kurabiyeler", "Gölge Simsarları", "Fırtına Fıstıkları", "Yanan Buzlar",
  "Demir Elmalar", "Altın Sakızlar", "Gümüş Göbekler", "Elmas Dirsekler",
  // Trend & pop kültür
  "WiFi Avcıları", "Şarj Bitti FC", "Ekran Kırıkları", "Caps Efsaneleri",
  "Meme Lordu", "Hashtag Ordusu", "Emoji Savaşçıları", "TikTok Kaplanları",
  "Spotify Hayaletleri", "Netflix Nöbetçileri", "Bluetooth Korsanları",
  // Sınıf içi klasikler & self-deprecating
  "Son Sıra Kulübü", "Geç Kalanlar Birliği", "Unuttum Spor", "Ders Bitti FC",
  "Kitap Unutanlar", "Rapor Kralları", "Pardon Hocam", "Ben Yapmadım FC",
  "Beş Dakika Daha", "Zil Çalsın Yeter", "Tahtaya Kalkmam",
  // Ortaokul meme / gündelik dil
  "Efsane Çocuklar", "Mood Bozanlar", "Resmen Biz", "Aynen Öyle FC",
  "Off Yine mi Biz", "Sus Len", "Tamamdır Reis", "Hadi Canım",
  "Valla Olmaz", "Yok Artık", "Bana mı Dedin",
  // Absürt süper kahraman
  "Kaptan Kek", "Süper Simit", "Işın Kılıçlı Kalemler", "Radyoaktif Silgiler",
  "X-Men Yok Biz Varız", "Lazerli Lokumlar", "Atomik Ayakkabılar",
  // Ortaokul spor & çakma marka
  "Adidos FC", "Nayki United", "Pumba Spor", "Beşiktoast", "Galatasaray Tost",
  "Real Mısır", "Barçelona Börek", "Manchester Mantı",
  // Matematik & ders esprisi
  "Pisagor Çetesi", "Bölen Bulunmaz", "Sıfırın Altı", "Negatif Enerji FC",
  "Virgülden Sonrası", "Türev Canavarları", "X'i Bulanlar",
];

class OgrenciListesiEkrani extends StatefulWidget {
  final String sinifId;
  final String? sinifAd;
  /// Arama sonucundan gelindiğinde liste yüklenir yüklenmez bu öğrencinin
  /// kartı açılır (bkz. ogrenci_arama_ekrani.dart).
  final String? acilacakOgrenciId;
  /// Geniş ekranda Sınıflarım'ın sağ sütununa gömülü: geri oku yok.
  final bool gomulu;
  const OgrenciListesiEkrani({super.key, required this.sinifId, this.sinifAd, this.acilacakOgrenciId, this.gomulu = false});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            // 120 iken flexibleSpace'teki büyük başlık, 56px'lik toolbar
            // şeridiyle aynı yüksekliğe düşüp aksiyon ikonlarının üstüne
            // çiziliyordu. Başlık artık Column'un başındaki SizedBox ile
            // şeridin ALTINA itiliyor; expandedHeight de ona göre büyüdü.
            expandedHeight: 160,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: !widget.gomulu,
            backgroundColor: AppTema.ana,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: innerBoxIsScrolled
                ? Text(_sinifAd ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.fact_check_rounded),
                tooltip: 'Yoklama',
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => YoklamaEkrani(sinifId: widget.sinifId, sinifAd: _sinifAd, kalemler: _kontrolKalemleri),
                )),
              ),
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
                      aciklama: 'Sağ alttaki "+" düğmesi → tek tek ekle. Üstte "👥 Hızlı Ekle" ile toplu ekle (her satıra bir isim).',
                      renk: Color(0xFF1976D2),
                    ),
                    YardimBolumu(
                      ikon: Icons.bolt_rounded,
                      baslik: 'Puan (50-150)',
                      aciklama: 'Her öğrenciye seviye puanı verebilirsin. AI takım dağıtımı bu puanları kullanarak adil takımlar kurar — yüksek puanlı öğrencileri dengeli dağıtır (snake draft). Varsayılan 100; yetenek/katılım seviyesine göre 70-130 arası ayarla.',
                      renk: Color(0xFFFFB300),
                    ),
                    YardimBolumu(
                      ikon: Icons.local_fire_department_rounded,
                      baslik: 'Element sistemi 🔥💧🌱💨',
                      aciklama: 'Öğrencilere element ata: 🔥 ateş, 💧 su, 🌱 toprak, 💨 hava. Çatışan elementler (🔥↔💧 ve 🌱↔💨) algoritma tarafından FARKLI takımlara yerleştirilir. Sınıfta kavgalı/dağıtılması gereken öğrencileri ayırmak için ideal. Aynı element olan öğrenciler genelde aynı takıma kümelenir.',
                      renk: Color(0xFFE53935),
                    ),
                    YardimBolumu(
                      ikon: Icons.link_rounded,
                      baslik: 'Eşleştirme 🔗',
                      aciklama: 'Öğrenci düzenle penceresindeki "Eşleş" alanından iki öğrenciyi birbirine bağla. AI Takım Kur bu ikiliyi mümkün olduğunca hep aynı takıma yerleştirir — element sisteminden bağımsızdır, mevcut elementlerini etkilemez. Örn. birlikte oynamaktan hoşlanan iki arkadaşı ayırmadan takım kurmak için ideal.',
                      renk: Color(0xFF3949AB),
                    ),
                    YardimBolumu(
                      ikon: Icons.checklist_rounded,
                      baslik: 'Yoklama',
                      aciklama: 'Üstteki ✓ simgesiyle tarihli yoklama al — kontrol kalemleriyle (kitap, forma, boya…) birlikte kaydedilir. Öğrenciye dokunarak da hızlıca "burada/yok" işaretleyebilirsin; yalnızca burada olanlar takım dağıtımında yer alır.',
                      renk: Color(0xFF00897B),
                    ),
                    YardimBolumu(
                      ikon: Icons.sports_score_rounded,
                      baslik: 'AI Takım Oluştur',
                      aciklama: 'Alttaki "AI Takım Kur" düğmesi ile öğrencileri adil gruplara ayır — oyun, yarışma veya grup çalışması için. Snake draft algoritması: önce kızları, sonra erkekleri puana göre sıralayıp en az kişili takıma yerleştirir. Element çatışmalarını otomatik önler. Sonuç: max 1 kişi farkı + denk puanlar.',
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
                      aciklama: 'Branşına göre kontrol kalemleri tanımla (forma, kitap, boya, enstrüman…): günlük ✓/✗ veya sezon boyu sayaç. Üstteki ayar simgesinden düzenle. Sağlık notları + rozetler de öğrenci kartında tutulur.',
                      renk: Color(0xFF8E24AA),
                    ),
                  ],
                ),
              ),
              // Beş ikon dar ekranda başlıkla yarışıyordu; üçü taşır menüye
              // alındı. Yoklama ve Yardım en sık kullanılanlar, dışarıda kaldı.
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
                    value: 'renkler',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.palette_outlined),
                      title: Text('Takım Renkleri'),
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [AppTema.ana, AppTema.anaKoyu],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Aksiyon ikonlarının şeridini boş bırakır — başlık
                      // artık onların altından başlıyor.
                      const SizedBox(height: kToolbarHeight),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _sinifAd ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Kompakt istatistik satırı
                      StreamBuilder<QuerySnapshot>(
                        stream: _ogrencilerAkisiBaslik,
                        builder: (context, snapshot) {
                          final total = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          final present = snapshot.hasData
                              ? snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['buradaMi'] ?? true).length
                              : 0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _miniStat(Icons.people_alt_rounded, "$total", "Toplam", Colors.white),
                                _miniDivider(),
                                _miniStat(Icons.check_circle_rounded, "$present", "Mevcut", Colors.greenAccent.shade100),
                                _miniDivider(),
                                _miniStat(Icons.cancel_rounded, "${total - present}", "Yok",
                                    (total - present) > 0 ? Colors.redAccent.shade100 : Colors.white.withAlpha(140)),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Aktif maç banner'ı
            if (MacDurumu().aktif && MacDurumu().sinifId == widget.sinifId) _aktifMacBanner(),
            // Arama çubuğu
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _aramaCtrl,
                onChanged: (val) => setState(() => _aramaMetni = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Öğrenci ara...",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
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
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButton<int>(
                        value: secilenTakimSayisi,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(12),
                        items: List.generate(
                          formaRenkleri.length > 1 ? formaRenkleri.length - 1 : 1,
                          (i) => i + 2,
                        ).map((e) => DropdownMenuItem(value: e, child: Text("$e Takım", style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                        onChanged: (val) => setState(() => secilenTakimSayisi = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTema.vurgu,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: _takimlariKur,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text("AI Takım Kur", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color renk) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: renk, size: 15),
            const SizedBox(width: 5),
            Text(value, style: TextStyle(color: renk, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _miniDivider() {
    return Container(width: 1, height: 28, color: Colors.white.withAlpha(60));
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
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text("Etkinlik devam ediyor",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Devam Et", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bulutListeInsaEt() {
    return StreamBuilder<QuerySnapshot>(
      stream: _ogrencilerAkisiListe,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTema.vurgu));
        List<Ogrenci> liste = snapshot.data!.docs
            .map((d) => Ogrenci.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();
        if (liste.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text("Henüz öğrenci yok", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTema.metinIkincil)),
                const SizedBox(height: 8),
                const Text("Sağ üstteki ⋮ menüsünden \"Hızlı Öğrenci Ekle\" ile başla",
                    textAlign: TextAlign.center, style: TextStyle(color: AppTema.metinUcuncul)),
              ],
            ),
          );
        }
        // Alfabetik sıralama
        liste.sort((a, b) => a.ad.toLowerCase().compareTo(b.ad.toLowerCase()));
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
              .where((o) => o.gorunenAd.toLowerCase().contains(_aramaMetni))
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

  Widget _liste(List<Ogrenci> liste, List<Ogrenci> tumOgrenciler) {
    _tumOgrenciler = tumOgrenciler;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: liste.length,
      itemBuilder: (context, i) {
        final o = liste[i];
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
              return false; // Kartı silme, sadece toggle
            },
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 24),
              decoration: BoxDecoration(
                color: o.buradaMi ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // green.shade700, green.shade100 zemin üzerinde 3,1:1
                  // veriyordu; AppTema.basari (green900) 5,9:1.
                  Icon(o.buradaMi ? Icons.cancel_rounded : Icons.check_circle_rounded,
                      color: o.buradaMi ? Colors.red.shade900 : AppTema.basari),
                  const SizedBox(width: 8),
                  Text(o.buradaMi ? "Yok Say" : "Geldi",
                      style: TextStyle(fontWeight: FontWeight.w700, color: o.buradaMi ? Colors.red.shade900 : AppTema.basari)),
                ],
              ),
            ),
            child: Material(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withAlpha(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _ogrenciKartiAc(o, tumOgrenciler),
                child: Row(
                  children: [
                    // Cinsiyet yalnızca renkle gösteriliyordu; ekran
                    // okuyucu için etiket eklendi.
                    Semantics(
                      label: o.isMale ? 'Erkek öğrenci' : 'Kız öğrenci',
                      child: Container(
                        width: 3.5,
                        height: 44,
                        decoration: BoxDecoration(
                          color: o.isMale ? Colors.blue.shade400 : Colors.pink.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(o.gorunenAd,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 14,
                                        decoration: o.buradaMi ? null : TextDecoration.lineThrough,
                                        color: o.buradaMi ? Colors.black87 : Colors.grey,
                                      )),
                                ),
                                if (!o.buradaMi) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                    child: Text("Yok", style: TextStyle(fontSize: 9, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                            if (o.rozetler.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  o.rozetler.map((r) => Ogrenci.rozetTanimlari[r['rozet']]?.split(' ').first ?? '').join(' '),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            // Not boşken hiç görünmüyordu, "buraya not
                            // eklenebilir" bilgisi listede hiç yoktu — bir
                            // ikon her zaman görünüyor ki tıklanabildiği
                            // belli olsun. AMA notun İÇERİĞİ listede
                            // GÖSTERİLMİYOR — ders sırasında ekran başkasına
                            // görünebilir, sadece "not var/yok" durumu ve
                            // sabit "Not" etiketi var (Sabri'nin isteği,
                            // 2026-08-28: önceki sürüm notu metin olarak
                            // gösteriyordu, mahremiyet sorunu).
                            // 11 px italik gri400 (1,9:1) ve 19 px'lik hedefti
                            // (denetim Y5): metinUcuncul, 12 px, 32 px hedef.
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              InkWell(
                                onTap: () => _notHizliDuzenle(o),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 9, 8, 9),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        o.not.isNotEmpty ? Icons.sticky_note_2_rounded : Icons.note_add_outlined,
                                        size: 15,
                                        color: o.not.isNotEmpty ? AppTema.uyari : AppTema.metinUcuncul,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        o.not.isNotEmpty ? "Not" : "Not ekle",
                                        style: TextStyle(
                                          color: o.not.isNotEmpty ? AppTema.metinIkincil : AppTema.metinUcuncul,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Eşleşme listede hiç görünmüyordu (denetim O4).
                              if (o.eslesenIdler.isNotEmpty)
                                Tooltip(
                                  message: 'Eşli: ${o.eslesenIdler.map((eid) => _tumOgrenciler.where((p) => p.id == eid).map((p) => p.gorunenAd).join()).where((a) => a.isNotEmpty).join(', ')}',
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.link_rounded, size: 15, color: AppTema.metinUcuncul),
                                    const SizedBox(width: 3),
                                    Text('Eşli', style: const TextStyle(color: AppTema.metinUcuncul, fontSize: 12, fontWeight: FontWeight.w500)),
                                  ]),
                                ),
                            ]),
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

  Widget _rozetGrubu(Ogrenci o) {
    final aktifler = <Widget>[
      for (final k in _kontrolKalemleri)
        if (o.kalemDeger(k.id) != 0)
          _rozet(
            kalemIkonu(k.ikon),
            k.id == 'sari_kart' && o.kalemDeger(k.id) >= 2 ? Colors.red : _kalemRengi(k),
            o.kalemDeger(k.id),
          ),
      if (o.saglikDurumu != 0) _rozet(Icons.medical_services_rounded, Colors.teal, o.saglikDurumu),
    ];

    // Kontrol kalemi girişinin asıl kapısı; GestureDetector olduğu için
    // semantik ağaçta hiç yoktu (denetim O9).
    return Semantics(
      button: true,
      label: aktifler.isEmpty ? 'Kontrol kalemleri, eksik yok' : 'Kontrol kalemleri, ${aktifler.length} işaret',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _ogrenciKartiAc(o, _tumOgrenciler),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: aktifler.isEmpty
              ? Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade300)
              : Row(mainAxisSize: MainAxisSize.min, children: aktifler),
        ),
      ),
    );
  }

  Widget _rozet(IconData icon, Color renk, int val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Badge(
        label: Text('${val.abs()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
        backgroundColor: val < 0 ? Colors.red : Colors.green,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: renk.withAlpha(40), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: renk),
        ),
      ),
    );
  }


  Color _kalemRengi(KontrolKalemi k) {
    if (k.tip == KalemTipi.sayac) return Colors.amber.shade700;
    final palet = [Colors.deepOrange, Colors.purple, Colors.teal, Colors.indigo, Colors.pink.shade400, Colors.green];
    return palet[k.id.hashCode.abs() % palet.length];
  }

  Widget _artieksi(IconData icon, Color renk, String label, int val, Function(int) onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: renk.withAlpha(25), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: renk),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ]),
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.remove_circle_rounded, color: AppTema.tehlike), tooltip: '$label azalt', onPressed: () => onEdit(-1), iconSize: 26),
            SizedBox(width: 28, child: Text("$val", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            IconButton(icon: const Icon(Icons.add_circle_rounded, color: AppTema.basari), tooltip: '$label artır', onPressed: () => onEdit(1), iconSize: 26),
          ]),
        ),
      ]),
    );
  }

  Widget _saglikSatiri(Ogrenci o, StateSetter setDialogState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(
          onTap: o.saglikNotlari.isEmpty ? null : () => _saglikGecmisiDialog(o),
          child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: Colors.teal.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.medical_services_rounded, size: 18, color: Colors.teal),
            ),
            const SizedBox(width: 8),
            Text("Sağlık", style: const TextStyle(fontSize: 14)),
            if (o.saglikNotlari.isNotEmpty) ...[
              const SizedBox(width: 4),
              const Icon(Icons.history_rounded, size: 16, color: Colors.teal),
            ],
          ]),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_rounded, color: AppTema.tehlike),
              tooltip: 'Sağlık puanını azalt',
              onPressed: () => setDialogState(() => o.saglikDurumu += -1),
              iconSize: 26,
            ),
            SizedBox(width: 28, child: Text("${o.saglikDurumu}", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: AppTema.basari),
              tooltip: 'Sağlık notu ekle',
              onPressed: () => _saglikNotuEkleDialog(o, setDialogState),
              iconSize: 26,
            ),
          ]),
        ),
      ]),
    );
  }

  void _saglikNotuEkleDialog(Ogrenci o, StateSetter setDialogState) {
    final notCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.medical_services_rounded, color: Colors.teal, size: 22),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                title: Text(kayit['not'] ?? '-', style: const TextStyle(fontSize: 14)),
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
      ),
    );
  }

  void _rozetVerDialog(Ogrenci o, StateSetter parentSetState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Mevcut Rozetler:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTema.uyari)),
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
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Rozet Sil"),
        content: Text("$tanim rozetini silmek istediğinize emin misiniz?"),
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
    final nC = TextEditingController(text: o.not);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTema.vurgu, width: 2)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTema.vurgu, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final adC = TextEditingController(text: o.ad);
    final pC = TextEditingController(text: o.puan.toString());
    final nC = TextEditingController(text: o.not);
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
      if (yeniAd.isNotEmpty) o.ad = yeniAd;
      o.puan = (int.tryParse(pC.text) ?? 100).clamp(0, 9999);
      o.not = nC.text;
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
              Icon(ikon, size: 15, color: AppTema.metinUcuncul),
              const SizedBox(width: 6),
            ],
            Text(metin,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1,
                    color: AppTema.metinUcuncul)),
          ]),
        );

    InputDecoration alanDeko(String etiket) => InputDecoration(
          labelText: etiket,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTema.ana, width: 2)),
        );

    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final cinsiyetRenk = o.isMale ? Colors.blue.shade500 : Colors.pink.shade500;
          final esAdlari = o.eslesenIdler
              .map((eid) => tumOgrenciler.where((p) => p.id == eid).map((p) => p.gorunenAd).join())
              .where((a) => a.isNotEmpty)
              .toList();
          final ozet = [
            '${o.puan} puan',
            if (o.element != null) '${ElementSistemi.sembol(o.element)} ${ElementSistemi.etiket(o.element)}',
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    // Başlık
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                      child: Row(children: [
                        Semantics(
                          label: o.isMale ? 'Erkek öğrenci' : 'Kız öğrenci',
                          excludeSemantics: true,
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: cinsiyetRenk.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cinsiyetRenk.withAlpha(120)),
                            ),
                            child: Center(child: Text(o.isMale ? "♂" : "♀",
                                style: TextStyle(color: cinsiyetRenk, fontSize: 20, fontWeight: FontWeight.w800))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(o.gorunenAd, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            Text(ozet, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: AppTema.metinIkincil)),
                          ]),
                        ),
                        IconButton(
                          tooltip: 'Kapat',
                          icon: const Icon(Icons.close_rounded, color: AppTema.metinIkincil),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ]),
                    ),
                    const Divider(height: 1),
                    // Gövde
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          // 1. Kontrol kalemleri — derste en sık dokunulan yer, en üstte.
                          bolumBasligi('KONTROL KALEMLERİ', ikon: Icons.fact_check_rounded),
                          if (_kontrolKalemleri.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Text('Bu sınıfta kontrol kalemi yok. ⋮ menüsünden ekleyebilirsin.',
                                  style: TextStyle(color: AppTema.metinIkincil, fontSize: 13)),
                            ),
                          for (final k in _kontrolKalemleri) ...[
                            _artieksi(
                              kalemIkonu(k.ikon),
                              _kalemRengi(k),
                              k.tip == KalemTipi.sayac ? k.ad : '${k.ad} (eksik)',
                              o.kalemDeger(k.id),
                              (v) => setSheetState(() => o.kalemArti(k.id, v)),
                            ),
                            const Divider(height: 1),
                          ],
                          _saglikSatiri(o, setSheetState),

                          // 2. Not
                          bolumBasligi('NOT', ikon: Icons.sticky_note_2_rounded),
                          TextField(
                            controller: nC,
                            maxLength: GirdiSiniri.ogrenciNotu,
                            buildCounter: gizliSayac,
                            minLines: 3,
                            maxLines: 3,
                            decoration: alanDeko('Özel Not').copyWith(
                              hintText: 'Yalnız sen görürsün',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),

                          // 3. Rozetler — anında yazılır
                          bolumBasligi('ROZETLER', ikon: Icons.emoji_events_rounded),
                          Wrap(spacing: 6, runSpacing: 6, children: [
                            ...o.rozetler.reversed.map((r) => Chip(
                                  label: Text(Ogrenci.rozetTanimlari[r['rozet']] ?? r['rozet'].toString(),
                                      style: const TextStyle(fontSize: 12)),
                                  backgroundColor: AppTema.uyariZemin,
                                  side: BorderSide.none,
                                  deleteButtonTooltipMessage: 'Rozeti kaldır',
                                  onDeleted: () => _rozetSilOnay(o, r, setSheetState),
                                )),
                            ActionChip(
                              avatar: const Icon(Icons.add, size: 16, color: AppTema.uyari),
                              label: const Text('Rozet Ver',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTema.uyari)),
                              side: BorderSide(color: Colors.amber.shade300),
                              onPressed: () => _rozetVerDialog(o, setSheetState),
                            ),
                          ]),

                          // 4. Takım kurma
                          bolumBasligi('TAKIM KURMA', ikon: Icons.groups_rounded),
                          Row(children: [
                            const SizedBox(width: 56, child: Text('İfade', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTema.metinIkincil))),
                            ...ElementSistemi.semboller.entries.map((e) {
                              final secili = o.element == e.key;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Semantics(
                                  button: true,
                                  selected: secili,
                                  label: 'İfade: ${ElementSistemi.etiketler[e.key] ?? e.key}',
                                  excludeSemantics: true,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => setSheetState(() => o.element = secili ? null : e.key),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 44, height: 44,
                                      decoration: BoxDecoration(
                                        color: secili ? AppTema.vurgu.withAlpha(25) : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: secili ? AppTema.vurgu : Colors.grey.shade300, width: secili ? 2 : 1),
                                      ),
                                      child: Center(child: Text(e.value, style: const TextStyle(fontSize: 18))),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ]),
                          const SizedBox(height: 10),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const SizedBox(width: 56, child: Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text('Eşleş', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTema.metinIkincil)),
                            )),
                            Expanded(
                              child: Wrap(spacing: 6, runSpacing: 6, children: [
                                ...o.eslesenIdler.map((eid) {
                                  final eslerAday = tumOgrenciler.where((p) => p.id == eid);
                                  final ad = eslerAday.isNotEmpty ? eslerAday.first.gorunenAd : "?";
                                  return Chip(
                                    avatar: const Icon(Icons.link_rounded, size: 16),
                                    label: Text(ad, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: AppTema.vurgu.withAlpha(20),
                                    side: BorderSide.none,
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
                                  label: const Text("Ekle", style: TextStyle(fontSize: 12)),
                                  onPressed: () => _eslesenSecDialog(
                                    sheetCtx, o, tumOgrenciler, setSheetState, dokunulanEslerinIdleri,
                                  ),
                                ),
                              ]),
                            ),
                          ]),
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('İfade çatışanları ayırır, eşleşme ikiliyi aynı takıma koyar.',
                                style: TextStyle(fontSize: 12, color: AppTema.metinUcuncul)),
                          ),

                          // 5. Kimlik — en nadir değişen alanlar en altta.
                          bolumBasligi('BİLGİLER', ikon: Icons.badge_rounded),
                          TextField(
                            controller: adC,
                            maxLength: GirdiSiniri.ogrenciAdi,
                            buildCounter: gizliSayac,
                            textCapitalization: TextCapitalization.words,
                            decoration: alanDeko('İsim'),
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
                            _genderChip("Erkek ♂", o.isMale, Colors.blue, () => setSheetState(() => o.isMale = true)),
                            const SizedBox(width: 6),
                            _genderChip("Kız ♀", !o.isMale, Colors.pink, () => setSheetState(() => o.isMale = false)),
                          ]),
                        ]),
                      ),
                    ),
                    // Alt eylem çubuğu
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(children: [
                        TextButton.icon(
                          onPressed: () => _ogrenciSilOnay(sheetCtx, o),
                          icon: const Icon(Icons.delete_rounded, color: AppTema.tehlike),
                          label: const Text("Sil", style: TextStyle(color: AppTema.tehlike, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          child: const Text("İptal", style: TextStyle(color: AppTema.metinIkincil)),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTema.vurgu, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          ),
                          onPressed: () => kaydet(sheetCtx),
                          child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.w700)),
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
      ..sort((a, b) => a.gorunenAd.toLowerCase().compareTo(b.gorunenAd.toLowerCase()));
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
              : adaylar.where((p) => p.gorunenAd.toLowerCase().contains(arama)).toList();
          return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Kiminle Eşleştir?"),
          content: SizedBox(
            width: 320,
            height: 400,
            child: adaylar.isEmpty
                ? const Center(child: Text("Sınıfta başka öğrenci yok"))
                : Column(children: [
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setPickerState(() => arama = v.toLowerCase()),
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
                                style: const TextStyle(fontSize: 12, color: AppTema.metinIkincil)),
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

  Widget _genderChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
        ),
        // Seçili olmayan taraf gri metin + gri zemin + gri kenarlıkla
        // okunmuyordu.
        child: Text(label, style: TextStyle(
            color: selected ? color : AppTema.metinIkincil,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }

  void _ogrenciSilOnay(BuildContext dialogContext, Ogrenci o) {
    showDialog(
      context: dialogContext,
      builder: (c2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Öğrenciyi Sil"),
        content: Text("${o.gorunenAd} isimli öğrenciyi kalıcı olarak silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c2), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white,
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
    List<TopluOgrenciSatiri> satirlar = List.generate(5, (i) => TopluOgrenciSatiri());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTema.ana50, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.group_add_rounded, color: AppTema.ana, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("Hızlı Öğrenci Ekle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                  ]),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    const SizedBox(width: 24),
                    const Expanded(flex: 5, child: Text("Ad Soyad", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTema.metinIkincil, letterSpacing: 0.3))),
                    const SizedBox(width: 52, child: Center(child: Text("♂ / ♀", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTema.metinIkincil)))),
                    const SizedBox(width: 54, child: Center(child: Text("Puan", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTema.metinIkincil, letterSpacing: 0.3)))),
                    const SizedBox(width: 36),
                  ]),
                ),
                const Divider(height: 12),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(sheetContext).viewInsets.bottom),
                    children: List.generate(satirlar.length, (i) {
                      final satir = satirlar[i];
                      void scrollToRow() {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final ctx = satir.rowKey.currentContext;
                          if (ctx != null) {
                            Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
                          }
                        });
                      }
                      return Padding(
                        key: satir.rowKey,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          SizedBox(width: 24, child: Text("${i + 1}", style: const TextStyle(color: AppTema.metinUcuncul, fontWeight: FontWeight.w600))),
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
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTema.vurgu, width: 1.5)),
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
                                    ? Colors.grey.shade100
                                    : (satir.isMale ? Colors.blue.shade400 : Colors.pink.shade400),
                                borderRadius: BorderRadius.circular(10),
                                border: !satir.cinsiyetSecildi ? Border.all(color: Colors.grey.shade300) : null,
                              ),
                              child: Center(
                                child: Text(
                                  !satir.cinsiyetSecildi ? "?" : (satir.isMale ? "♂" : "♀"),
                                  style: TextStyle(
                                    color: !satir.cinsiyetSecildi ? AppTema.metinUcuncul : Colors.white,
                                    fontSize: !satir.cinsiyetSecildi ? 14 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTema.vurgu, width: 1.5)),
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
                              foregroundColor: AppTema.vurgu,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: AppTema.ana.withAlpha(60), width: 1),
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
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, -2))],
                  ),
                  child: Row(children: [
                    Text("${satirlar.length} satır", style: const TextStyle(color: AppTema.metinIkincil, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTema.vurgu, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), elevation: 2,
                      ),
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text("Tümünü Kaydet", style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => _topluKaydet(satirlar, sheetContext),
                    ),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
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
  Future<void> _topluKaydet(
      List<TopluOgrenciSatiri> satirlar, BuildContext sheetContext) async {
    try {
      await _topluKaydetYurut(satirlar, sheetContext);
    } catch (_) {
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Öğrenciler eklenemedi. Bağlantını kontrol edip tekrar dene."),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  Future<void> _topluKaydetYurut(
      List<TopluOgrenciSatiri> satirlar, BuildContext sheetContext) async {
    int eklenen = 0;
    int atlanan = 0;

    // Tüm mevcut isimleri tek sorguda al
    final mevcutAdlar = await _db.mevcutOgrenciAdlari(widget.sinifId);

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
      await _db.ogrencilerTopluEkle(widget.sinifId, yeniOgrenciler);
      eklenen = yeniOgrenciler.length;
    }

    // Çakışanları sor
    if (cakisanlar.isNotEmpty && sheetContext.mounted) {
      final devamEt = await showDialog<bool>(
        context: sheetContext,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppTema.ana),
            const SizedBox(width: 8),
            const Text("Aynı İsim Var", style: TextStyle(fontWeight: FontWeight.w700)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("Bu isimlerle zaten kayıtlı öğrenci var:", style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            ...cakisanlar.map((ad) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                Icon(Icons.person, color: AppTema.ana, size: 18),
                const SizedBox(width: 8),
                Text(ad, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
            )),
            const SizedBox(height: 12),
            Text("Yine de eklemek ister misiniz?", style: TextStyle(color: Colors.grey.shade600)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text("Atla", style: TextStyle(color: Colors.grey.shade600))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTema.vurgu, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(c, true),
              child: const Text("Yine de Ekle", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

      if (devamEt == true) {
        final cakisanOgrenciler = cakisanSatirlar.map((s) => Ogrenci(
          id: '', ad: s.adCtrl.text.trim(), isMale: s.isMale,
          puan: int.tryParse(s.puanCtrl.text) ?? 100,
        )).toList();
        await _db.ogrencilerTopluEkle(widget.sinifId, cakisanOgrenciler);
        eklenen += cakisanOgrenciler.length;
      } else {
        atlanan = cakisanlar.length;
      }
    }

    // Not: controller dispose'u sheet kapanışındaki .then() içinde yapılıyor.
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(atlanan > 0 ? "$eklenen eklendi, $atlanan atlandı" : "$eklenen öğrenci eklendi!"),
        backgroundColor: Colors.green.shade700,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                decoration: InputDecoration(hintText: "Yeni Renk Ekle (Örn: Mor)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ]),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTema.vurgu, foregroundColor: Colors.white,
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
          content: const Text("Yeterli öğrenci yok."),
          backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("AI Takım Dağılımı", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text("${gelenler.length} oyuncu  •  $secilenTakimSayisi takım", style: const TextStyle(color: AppTema.metinIkincil)),
              ]),
              Material(
                color: AppTema.ana50, borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  icon: Icon(Icons.refresh_rounded, color: AppTema.ana, size: 28),
                  tooltip: "Yeniden Karıştır",
                  onPressed: () { Navigator.pop(sheetCtx); _takimlariKur(); },
                ),
              ),
            ]),
          ),
          const Divider(),
          // Yan yana takım kartları (grid)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: secilenTakimSayisi <= 3 ? secilenTakimSayisi : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: secilenTakimSayisi <= 2 ? 0.65 : 0.55,
                ),
                itemCount: takimBilgileri.length,
                itemBuilder: (context, i) {
                  final t = takimBilgileri[i];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.renk.withAlpha(80), width: 1.5),
                      color: t.renk.withAlpha(8),
                    ),
                    child: Column(
                      children: [
                        // Takım başlığı. Eskiden Container genişlik almadığı
                        // için içeriğe göre büzülüyordu: bant karta yaslanmıyor,
                        // yatay iç boşluk kalmıyor, iki takımın bandı farklı
                        // genişlikte duruyordu. Uzun takım adlarında
                        // ("X-Men Yok Biz Varız") satır da kırılıyordu.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [t.renk.withAlpha(180), t.renk]),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                          ),
                          child: Builder(builder: (_) {
                            // Sarı formada beyaz metin 1,6:1'di (denetim Y4).
                            final metin = AppTema.ustMetin(t.renk);
                            return Column(children: [
                              Icon(Icons.shield_rounded, color: metin, size: 22),
                              const SizedBox(height: 2),
                              Text(t.isim, textAlign: TextAlign.center,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: metin, fontWeight: FontWeight.w800, fontSize: 13)),
                              Text("${t.renkAdi}  •  ${t.oyuncular.length} kişi  •  (${t.oyuncular.fold<int>(0, (toplam, o) => toplam + (efektifPuan[o.id] ?? o.puan))} puan)",
                                  textAlign: TextAlign.center,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: metin.withAlpha(230), fontSize: 12)),
                            ]);
                          }),
                        ),
                        // Oyuncu listesi
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            itemCount: t.oyuncular.length,
                            itemBuilder: (context, j) {
                              final o = t.oyuncular[j];
                              final isKaptan = t.kaptan != null && o.id == t.kaptan!.id;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(children: [
                                  Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      color: o.isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(child: Text(o.isMale ? "♂" : "♀",
                                        style: TextStyle(color: o.isMale ? Colors.blue : Colors.pink, fontSize: 12))),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(o.gorunenAd,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isKaptan ? FontWeight.w800 : FontWeight.w500,
                                        color: isKaptan ? AppTema.uyari : Colors.black87,
                                      ))),
                                  // Eşleşme yalnız skor tablosunda görünüyordu (denetim O4).
                                  if (o.eslesenIdler.isNotEmpty)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.link_rounded, size: 14, color: AppTema.metinIkincil),
                                    ),
                                  if (isKaptan)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.star_rounded, size: 14, color: AppTema.uyari),
                                    ),
                                ]),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Oyunu Başlat butonu
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTema.panelKoyu1,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.sports_rounded, size: 26),
                label: const Text("Oyunu Başlat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
                onPressed: () async {
                  // Süren bir etkinlik varken onaysız üstüne yazılıyordu;
                  // Sınıflarım'daki "Etkinliği Bitir" ise onay istiyor (denetim O2).
                  if (MacDurumu().aktif) {
                    final onay = await showDialog<bool>(
                      context: sheetCtx,
                      builder: (c) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Süren etkinlik silinsin mi?'),
                        content: const Text('Devam eden etkinliğin skoru ve süresi silinip yeni oyun başlatılacak.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: TextButton.styleFrom(foregroundColor: AppTema.tehlike),
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
        ]),
      ),
    ).ignore();
  }
}
