import '../tema.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ogrenci.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/mac_durumu.dart';
import 'skor_ekrani.dart';

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
];

class OgrenciListesiEkrani extends StatefulWidget {
  final String sinifId;
  const OgrenciListesiEkrani({super.key, required this.sinifId});
  @override
  State<OgrenciListesiEkrani> createState() => _OgrenciListesiEkraniState();
}

class _OgrenciListesiEkraniState extends State<OgrenciListesiEkrani> {
  late final FirestoreService _db;
  int secilenTakimSayisi = 2;
  List<String> formaRenkleri = ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Beyaz', 'Turuncu', 'Lacivert'];
  bool _renkleriYuklendi = false;
  final _random = Random();
  String _aramaMetni = '';

  List<String> _rastgeleTakimIsimleri(int adet) {
    final havuz = [..._takimIsimHavuzu]..shuffle(_random);
    return havuz.take(adet).toList();
  }

  @override
  void initState() {
    super.initState();
    _db = FirestoreService(uid: AuthService().uid);
    _formaRenkleriniYukle();
  }

  Future<void> _formaRenkleriniYukle() async {
    try {
      final data = await _db.sinifBilgisiGetir(widget.sinifId);
      if (data != null && data['formaRenkleri'] != null) {
        if (mounted) setState(() {
          formaRenkleri = List<String>.from(data['formaRenkleri']);
          _renkleriYuklendi = true;
        });
      } else {
        if (mounted) setState(() {
          formaRenkleri = ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Beyaz', 'Turuncu', 'Lacivert'];
          _renkleriYuklendi = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        formaRenkleri = ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Beyaz', 'Turuncu', 'Lacivert'];
        _renkleriYuklendi = true;
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
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTema.ana,
            foregroundColor: Colors.white,
            centerTitle: true,
            title: innerBoxIsScrolled
                ? Text(widget.sinifId, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))
                : null,
            actions: [
              IconButton(icon: const Icon(Icons.group_add_rounded), onPressed: _hizliSinifEkleDialog, tooltip: 'Hızlı Öğrenci Ekle'),
              IconButton(icon: const Icon(Icons.palette_outlined), onPressed: _renkYonetimi, tooltip: 'Takım Renkleri'),
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
                      Text(widget.sinifId, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      // Kompakt istatistik satırı
                      StreamBuilder<QuerySnapshot>(
                        stream: _db.ogrencilerStream(widget.sinifId),
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
                onChanged: (val) => setState(() => _aramaMetni = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Öğrenci ara...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
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
      bottomNavigationBar: Container(
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
                          backgroundColor: AppTema.ana,
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
        Text(label, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 10, letterSpacing: 0.5)),
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
          gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
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
              child: Text("Maç devam ediyor",
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
      stream: _db.ogrencilerStream(widget.sinifId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTema.ana));
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
                Text("Henüz öğrenci yok", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Text("Sağ üstteki butonla öğrenci ekleyin", style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }
        // Alfabetik sıralama
        liste.sort((a, b) => a.ad.toLowerCase().compareTo(b.ad.toLowerCase()));
        // Arama filtresi
        if (_aramaMetni.isNotEmpty) {
          liste = liste.where((o) => o.ad.toLowerCase().contains(_aramaMetni)).toList();
        }
        return _listeInsaEt(liste);
      },
    );
  }

  Widget _listeInsaEt(List<Ogrenci> liste) {
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
              _save(o);
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
                  Icon(o.buradaMi ? Icons.cancel_rounded : Icons.check_circle_rounded,
                      color: o.buradaMi ? Colors.red.shade700 : Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(o.buradaMi ? "Yok Say" : "Geldi",
                      style: TextStyle(fontWeight: FontWeight.w700, color: o.buradaMi ? Colors.red.shade700 : Colors.green.shade700)),
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
                onTap: () => _ogrenciDuzenle(o),
                child: Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 44,
                      decoration: BoxDecoration(
                        color: o.isMale ? Colors.blue.shade400 : Colors.pink.shade400,
                        borderRadius: BorderRadius.circular(2),
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
                            if (o.not.isNotEmpty)
                              Text(o.not, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
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
      if (o.ayakkabiEksik != 0) _rozet(Icons.do_not_step_rounded, Colors.deepOrange, o.ayakkabiEksik),
      if (o.kiyafetEksik != 0) _rozet(Icons.checkroom_rounded, Colors.purple, o.kiyafetEksik),
      if (o.sariKart != 0)
        _rozet(Icons.square_rounded, o.sariKart >= 2 ? Colors.red : Colors.amber.shade700, o.sariKart),
      if (o.saglikDurumu != 0) _rozet(Icons.medical_services_rounded, Colors.teal, o.saglikDurumu),
    ];

    return GestureDetector(
      onTap: () => _durumPopUp(o),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 32),
        child: aktifler.isEmpty
            ? Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade300)
            : Row(mainAxisSize: MainAxisSize.min, children: aktifler),
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

  void _save(Ogrenci o) => _db.ogrenciGuncelle(widget.sinifId, o);

  void _durumPopUp(Ogrenci o) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: o.isMale ? [Colors.blue.shade300, Colors.blue.shade500] : [Colors.pink.shade300, Colors.pink.shade500]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(o.isMale ? "♂" : "♀", style: const TextStyle(color: Colors.white, fontSize: 16))),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(o.gorunenAd, style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _artieksi(Icons.do_not_step_rounded, Colors.deepOrange, "Ayakkabı", o.ayakkabiEksik, (v) => setDialogState(() => o.ayakkabiEksik += v)),
            const Divider(height: 1),
            _artieksi(Icons.checkroom_rounded, Colors.purple, "Kıyafet", o.kiyafetEksik, (v) => setDialogState(() => o.kiyafetEksik += v)),
            const Divider(height: 1),
            _artieksi(Icons.square_rounded, Colors.amber.shade700, "Kart", o.sariKart, (v) => setDialogState(() => o.sariKart += v)),
            const Divider(height: 1),
            _saglikSatiri(o, setDialogState),
          ]),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTema.ana, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () { _save(o); Navigator.pop(context); },
                child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
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
            IconButton(icon: const Icon(Icons.remove_circle_rounded, color: Colors.red), onPressed: () => onEdit(-1), iconSize: 26),
            SizedBox(width: 28, child: Text("$val", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            IconButton(icon: const Icon(Icons.add_circle_rounded, color: Colors.green), onPressed: () => onEdit(1), iconSize: 26),
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
              icon: const Icon(Icons.remove_circle_rounded, color: Colors.red),
              onPressed: () => setDialogState(() => o.saglikDurumu += -1),
              iconSize: 26,
            ),
            SizedBox(width: 28, child: Text("${o.saglikDurumu}", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Colors.green),
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
          const Text("Sağlık Notu", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        content: TextField(
          controller: notCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: "Örn: tırnak batması, epilepsi...",
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
            separatorBuilder: (_, __) => const Divider(height: 1),
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
                    Text("Mevcut Rozetler:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade800)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4, runSpacing: 4,
                      children: o.rozetler.reversed.map((r) {
                        final tanim = Ogrenci.rozetTanimlari[r['rozet']] ?? r['rozet'];
                        return Chip(
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          label: Text("$tanim  ${r['tarih']}", style: const TextStyle(fontSize: 11)),
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
                    o.rozetler.add({'rozet': e.key, 'tarih': tarih});
                    _save(o);
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
        title: const Text("Rozet Sil", style: TextStyle(fontWeight: FontWeight.w700)),
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
              _save(o);
              parentSetState(() {});
              Navigator.pop(ctx);
            },
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  void _ogrenciDuzenle(Ogrenci o) {
    final adC = TextEditingController(text: o.ad);
    final pC = TextEditingController(text: o.puan.toString());
    final nC = TextEditingController(text: o.not);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Öğrenci Düzenle", style: TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: adC,
              decoration: InputDecoration(
                labelText: "İsim",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTema.ana, width: 2)),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _genderChip("Erkek ♂", o.isMale, Colors.blue, () => setDialogState(() => o.isMale = true)),
              const SizedBox(width: 10),
              _genderChip("Kız ♀", !o.isMale, Colors.pink, () => setDialogState(() => o.isMale = false)),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: pC,
              decoration: InputDecoration(
                labelText: "Yetenek Puanı",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTema.ana, width: 2)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nC,
              decoration: InputDecoration(
                labelText: "Özel Not",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTema.ana, width: 2)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            // Rozet ver butonu
            GestureDetector(
              onTap: () => _rozetVerDialog(o, setDialogState),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text("Rozet Ver", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.amber.shade800)),
                    if (o.rozetler.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(8)),
                        child: Text("${o.rozetler.length}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber.shade900)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Element seçici
            Row(
              children: [
                Text("İfade:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(width: 8),
                ...ElementSistemi.semboller.entries.map((e) {
                  final secili = o.element == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setDialogState(() => o.element = secili ? null : e.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: secili ? AppTema.ana.withAlpha(25) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: secili ? AppTema.ana : Colors.grey.shade300, width: secili ? 2 : 1),
                        ),
                        child: Center(child: Text(e.value, style: const TextStyle(fontSize: 18))),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ])),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton.icon(
              onPressed: () => _ogrenciSilOnay(dialogContext, o),
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              label: const Text("Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTema.ana, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                final yeniAd = adC.text.trim();
                if (yeniAd.isNotEmpty) o.ad = yeniAd;
                o.puan = int.tryParse(pC.text) ?? 100;
                o.not = nC.text;
                _save(o);
                Navigator.pop(dialogContext);
              },
              child: const Text("Kaydet", style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ).then((_) { adC.dispose(); pC.dispose(); nC.dispose(); });
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
        child: Text(label, style: TextStyle(color: selected ? color : Colors.grey, fontWeight: selected ? FontWeight.w700 : FontWeight.normal)),
      ),
    );
  }

  void _ogrenciSilOnay(BuildContext dialogContext, Ogrenci o) {
    showDialog(
      context: dialogContext,
      builder: (c2) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Öğrenciyi Sil", style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text("${o.gorunenAd} isimli öğrenciyi kalıcı olarak silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c2), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              await _db.ogrenciSil(widget.sinifId, o.id);
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
                    Expanded(flex: 5, child: Text("Ad Soyad", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.3))),
                    SizedBox(width: 44, child: Center(child: Text("♂ / ♀", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey.shade500)))),
                    SizedBox(width: 54, child: Center(child: Text("Puan", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.3)))),
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
                          SizedBox(width: 24, child: Text("${i + 1}", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600))),
                          Expanded(
                            flex: 5,
                            child: TextField(
                              controller: satir.adCtrl,
                              onTap: scrollToRow,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: "Ad Soyad",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTema.ana, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true,
                              ),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setSheetState(() {
                              if (!satir.cinsiyetSecildi) {
                                satir.cinsiyetSecildi = true;
                              } else {
                                satir.isMale = !satir.isMale;
                              }
                            }),
                            child: Container(
                              width: 36, height: 36,
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
                                    color: !satir.cinsiyetSecildi ? Colors.grey.shade400 : Colors.white,
                                    fontSize: !satir.cinsiyetSecildi ? 14 : 18,
                                    fontWeight: FontWeight.bold,
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
                              decoration: InputDecoration(
                                hintText: "100",
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTema.ana, width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), isDense: true,
                              ),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: Colors.red.shade300, size: 20),
                            onPressed: () { satir.dispose(); setSheetState(() => satirlar.removeAt(i)); },
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36),
                          ),
                        ]),
                      );
                    })..add(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () => setSheetState(() => satirlar.add(TopluOgrenciSatiri())),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text("Satır Ekle", style: TextStyle(fontWeight: FontWeight.w600)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTema.ana,
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
                    Text("${satirlar.length} satır", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () { for (var s in satirlar) { s.dispose(); } Navigator.pop(sheetContext); },
                      child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTema.ana, foregroundColor: Colors.white,
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
    );
  }

  Future<void> _topluKaydet(List<TopluOgrenciSatiri> satirlar, BuildContext sheetContext) async {
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTema.ana, foregroundColor: Colors.white,
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

    for (var s in satirlar) { s.dispose(); }
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
          title: const Text("Forma Renkleri", style: TextStyle(fontWeight: FontWeight.w700)),
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
                  onDeleted: () => setDialogState(() => formaRenkleri.remove(r)),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: c,
                decoration: InputDecoration(hintText: "Yeni Renk Ekle (Örn: Mor)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ]),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTema.ana, foregroundColor: Colors.white,
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

  Color _takimRenginiBul(String renkAdi) {
    switch (renkAdi.toLowerCase().trim()) {
      case 'kırmızı': return Colors.red;
      case 'mavi': return Colors.blue;
      case 'sarı': return Colors.amber.shade600;
      case 'yeşil': return Colors.green;
      case 'siyah': return Colors.black87;
      case 'beyaz': return Colors.grey.shade400;
      case 'turuncu': return AppTema.ana;
      case 'mor': return Colors.purple;
      case 'pembe': return Colors.pink;
      case 'lacivert': return Colors.indigo;
      case 'gri': return Colors.grey;
      default: return AppTema.ana;
    }
  }

  void _takimlariKur() async {
    final gelenler = (await _db.ogrencileriGetir(widget.sinifId)).where((o) => o.buradaMi).toList();

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

    // Takımdaki oyuncularla element çatışması var mı?
    bool elementCatismasi(int takimIdx, Ogrenci o) {
      if (o.element == null) return false;
      return takimlar[takimIdx].any((m) => ElementSistemi.catisir(o.element, m.element));
    }

    void dengeliDagit(List<Ogrenci> liste) {
      for (var o in liste) {
        // En az kişiye sahip takımları bul
        int minKisi = takimlar.map((t) => t.length).reduce((a, b) => a < b ? a : b);
        List<int> enAzKisiTakimlar = [];
        for (int t = 0; t < secilenTakimSayisi; t++) {
          if (takimlar[t].length == minKisi) enAzKisiTakimlar.add(t);
        }

        // Element çatışması olmayanları öncelikle tercih et
        List<int> uygunTakimlar = enAzKisiTakimlar.where((t) => !elementCatismasi(t, o)).toList();
        if (uygunTakimlar.isEmpty) {
          // Tüm en-az-kişili takımlarda çatışma var, tüm takımlar arasında çatışmasız ara
          uygunTakimlar = List.generate(secilenTakimSayisi, (i) => i)
              .where((t) => !elementCatismasi(t, o))
              .toList();
        }
        // Hâlâ bulunamazsa (kaçınılmaz çatışma), en az kişili takımlardan devam et
        if (uygunTakimlar.isEmpty) uygunTakimlar = enAzKisiTakimlar;

        // Bunlar arasından en düşük puanlı takıma ver (puan dengesi)
        int hedef = uygunTakimlar.reduce((a, b) => takimPuanlari[a] <= takimPuanlari[b] ? a : b);
        takimlar[hedef].add(o);
        takimPuanlari[hedef] += efektifPuan[o.id]!;
      }
    }

    dengeliDagit(kizlar);
    dengeliDagit(erkekler);

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

    AnalyticsService.takimKuruldu(takimSayisi: secilenTakimSayisi, oyuncuSayisi: gelenler.length);

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
                Text("${gelenler.length} oyuncu  •  $secilenTakimSayisi takım", style: TextStyle(color: Colors.grey.shade500)),
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
                        // Takım başlığı
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [t.renk.withAlpha(180), t.renk]),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                          ),
                          child: Column(children: [
                            Icon(Icons.shield_rounded, color: Colors.white, size: 22),
                            const SizedBox(height: 2),
                            Text(t.isim, textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            Text("${t.renkAdi}  •  ${t.oyuncular.length} kişi  •  (${t.oyuncular.fold<int>(0, (sum, o) => sum + (efektifPuan[o.id] ?? o.puan))} puan)",
                                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 10)),
                          ]),
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
                                        style: TextStyle(color: o.isMale ? Colors.blue : Colors.pink, fontSize: 11))),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(o.gorunenAd,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isKaptan ? FontWeight.w800 : FontWeight.w500,
                                        color: isKaptan ? Colors.amber.shade900 : Colors.black87,
                                      ))),
                                  if (isKaptan)
                                    Text("©", style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w900, fontSize: 12)),
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
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.sports_rounded, size: 26),
                label: const Text("Oyunu Başlat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1)),
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  MacDurumu().macBaslat(widget.sinifId, takimBilgileri);
                  AnalyticsService.macBasladi(takimSayisi: secilenTakimSayisi, oyuncuSayisi: gelenler.length);
                  Navigator.push<String>(context, MaterialPageRoute(
                    builder: (_) => SkorEkrani(takimlar: takimBilgileri),
                  )).then((sonuc) {
                    if (sonuc != 'geridon') MacDurumu().macBitir();
                    setState(() {});
                  });
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
