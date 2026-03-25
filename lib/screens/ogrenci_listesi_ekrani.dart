import '../tema.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ogrenci.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
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
  List<String> formaRenkleri = [];
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
    final data = await _db.sinifBilgisiGetir(widget.sinifId);
    if (data != null && data['formaRenkleri'] != null) {
      setState(() {
        formaRenkleri = List<String>.from(data['formaRenkleri']);
        _renkleriYuklendi = true;
      });
    } else {
      setState(() {
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _miniStat(Icons.people_alt_rounded, "$total"),
                                _miniDivider(),
                                _miniStat(Icons.check_circle_rounded, "$present"),
                                _miniDivider(),
                                _miniStat(Icons.cancel_rounded, "${total - present}"),
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
      bottomNavigationBar: _renkleriYuklendi
          ? Container(
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
            )
          : null,
    );
  }

  Widget _miniStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 15),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _miniDivider() {
    return Container(width: 1, height: 14, color: Colors.white.withAlpha(60));
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
                                  child: Text(o.ad,
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
    return GestureDetector(
      onTap: () => _durumPopUp(o),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rozet(Icons.do_not_step_rounded, Colors.deepOrange, o.ayakkabiEksik),
          _rozet(Icons.checkroom_rounded, Colors.purple, o.kiyafetEksik),
          _rozet(o.sariKart >= 2 ? Icons.square_rounded : Icons.square_rounded,
              o.sariKart >= 2 ? Colors.red : Colors.amber.shade700, o.sariKart),
          _rozet(Icons.medical_services_rounded, Colors.teal, o.saglikDurumu),
        ],
      ),
    );
  }

  Widget _rozet(IconData icon, Color renk, int val) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: val == 0
          ? Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: renk.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: renk.withAlpha(120)),
            )
          : Badge(
              label: Text('$val', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9)),
              backgroundColor: val < 0 ? Colors.red : Colors.green,
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: renk.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: renk),
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
            Flexible(child: Text(o.ad, style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            _artieksi(Icons.do_not_step_rounded, Colors.deepOrange, "Ayakkabı", o.ayakkabiEksik, (v) => setDialogState(() => o.ayakkabiEksik += v)),
            const Divider(height: 1),
            _artieksi(Icons.checkroom_rounded, Colors.purple, "Kıyafet", o.kiyafetEksik, (v) => setDialogState(() => o.kiyafetEksik += v)),
            const Divider(height: 1),
            _artieksi(Icons.square_rounded, Colors.amber.shade700, "Kart", o.sariKart, (v) => setDialogState(() => o.sariKart += v)),
            const Divider(height: 1),
            _artieksi(Icons.medical_services_rounded, Colors.teal, "Sağlık", o.saglikDurumu, (v) => setDialogState(() => o.saglikDurumu += v)),
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

  void _ogrenciDuzenle(Ogrenci o) {
    final pC = TextEditingController(text: o.puan.toString());
    final nC = TextEditingController(text: o.not);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(o.ad, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
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
          ]),
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
    ).then((_) { pC.dispose(); nC.dispose(); });
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
        content: Text("${o.ad} isimli öğrenciyi kalıcı olarak silmek istediğinize emin misiniz?"),
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
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTema.ana50, borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.group_add_rounded, color: AppTema.ana, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("Hızlı Öğrenci Ekle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                    TextButton.icon(
                      onPressed: () => setSheetState(() => satirlar.add(TopluOgrenciSatiri())),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text("Satır"),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    const SizedBox(width: 24),
                    const Expanded(flex: 5, child: Text("Ad Soyad", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                    SizedBox(width: 44, child: Center(child: Text("C", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)))),
                    SizedBox(width: 54, child: Center(child: Text("Puan", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)))),
                    const SizedBox(width: 36),
                  ]),
                ),
                const Divider(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: List.generate(satirlar.length, (i) {
                      final satir = satirlar[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            SizedBox(width: 24, child: Text("${i + 1}", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600))),
                            Expanded(
                              flex: 5,
                              child: TextField(
                                controller: satir.adCtrl,
                                decoration: const InputDecoration(hintText: "Ad Soyad", border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12), isDense: true),
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setSheetState(() => satir.isMale = !satir.isMale),
                              child: Container(
                                width: 38, height: 38,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: satir.isMale ? [Colors.blue.shade200, Colors.blue.shade400] : [Colors.pink.shade200, Colors.pink.shade400]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(child: Text(satir.isMale ? "♂" : "♀", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 54,
                              child: TextField(
                                controller: satir.puanCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                        ),
                      );
                    }),
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
    List<String> cakisanlar = [];

    for (var s in satirlar) {
      final ad = s.adCtrl.text.trim();
      if (ad.isEmpty) continue;

      final varMi = await _db.ogrenciVarMi(widget.sinifId, ad);
      if (varMi) {
        cakisanlar.add(ad);
        continue; // Şimdilik atla, sonra soracağız
      }

      await _db.ogrenciEkle(widget.sinifId, Ogrenci(
        id: '', ad: ad, isMale: s.isMale,
        puan: int.tryParse(s.puanCtrl.text) ?? 100,
      ));
      eklenen++;
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
        for (var s in satirlar) {
          final ad = s.adCtrl.text.trim();
          if (cakisanlar.contains(ad)) {
            await _db.ogrenciEkle(widget.sinifId, Ogrenci(
              id: '', ad: ad, isMale: s.isMale,
              puan: int.tryParse(s.puanCtrl.text) ?? 100,
            ));
            eklenen++;
          }
        }
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

    // Önce kızları snake draft ile dağıt, sonra erkekleri
    List<List<Ogrenci>> takimlar = List.generate(secilenTakimSayisi, (_) => []);

    void snakeDraft(List<Ogrenci> liste) {
      for (int i = 0; i < liste.length; i++) {
        int round = i ~/ secilenTakimSayisi;
        int index = round.isEven ? i % secilenTakimSayisi : (secilenTakimSayisi - 1) - (i % secilenTakimSayisi);
        takimlar[index].add(liste[i]);
      }
    }

    snakeDraft(kizlar);
    snakeDraft(erkekler);

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
        kaptan = takim.reduce((a, b) => efektifPuan[a.id]! >= efektifPuan[b.id]! ? a : b);
      }
      takimBilgileri.add(TakimBilgi(
        isim: komikIsim, renkAdi: takimRenkAdi, renk: gorselRenk,
        oyuncular: takim, kaptan: kaptan,
      ));
    }

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
                            Text("${t.renkAdi}  •  ${t.oyuncular.length} kişi",
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
                                  Expanded(child: Text(o.ad,
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
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SkorEkrani(takimlar: takimBilgileri),
                  ));
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
