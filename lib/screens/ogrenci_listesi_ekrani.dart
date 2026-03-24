import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ogrenci.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// Geniş absürt komik takım isim havuzu
const List<String> _takimIsimHavuzu = [
  "Uçan Lahmacunlar", "Gökteki Patatesler", "Kaçak Bezelye", "Çılgın Simitleri",
  "Uzay Mantısı", "Ninja Kaplumbağalar", "Galaktik Börekler", "Ejder Çorapları",
  "Roket Tavukları", "Turbo Salyangozlar", "Atom Karıncaları", "Megafonlu Cırcırlar",
  "Süper Kalemler", "Deli Çikolata", "Fırtına Fındıkları", "Yıldız Pideciler",
  "Buldozer Kelebekler", "Gizli Ajanlar FC", "Patlayan Mısırlar", "Meteor Kurabiyeler",
  "Viking Kedileri", "Şimşek Hamsterlar", "Nükleer Cevizler", "Korsan Papağanlar",
  "Perişan Penguenler", "Uçan Halıcılar", "Süpersonik Sincaplar", "Çaydanlık United",
  "Tsunami Tavşanları", "Kızgın Bamyalar", "Lazer Koyunları", "Kaptan Patlıcan",
  "Dinamit Domatesler", "Hızlı Kurbağalar", "Gökgürültüsü FC", "Ayı Lokumu Spor",
  "Çekiç Balıkları", "Havuç Gladyatörleri", "Turşu Yıldızları", "Kaçak Lokumlar",
  "Panik Ahtapotlar", "Disko Arıları", "Biber Gazı Spor", "Sihirli Noktalar",
  "Kozmik Köfteciler", "Karambol Kedileri", "Torpido Tilkileri", "Fantom Peynirler",
  "Karga Takımı", "Yıkılmaz Yumurtalar", "Bumerang Balıkları", "Dalga Delileri",
  "Fırtınalı Fasulye", "Gürültücü Gofretler", "Haylaz Hıyarlar", "İnatçı İgloolar",
  "Jetler FC", "Kudretli Kurabiye", "Lav Lalesi", "Müthiş Muhallebi",
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
      appBar: AppBar(
        title: Text(widget.sinifId, style: const TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            onPressed: _hizliSinifEkleDialog,
            tooltip: 'Hızlı Sınıf Oluştur',
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: _renkYonetimi,
            tooltip: 'Takım Renkleri',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _bulutListeInsaEt()),
        ],
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
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                          backgroundColor: Colors.orange.shade700,
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange.shade700, Colors.orange.shade500],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db.ogrencilerStream(widget.sinifId),
        builder: (context, snapshot) {
          final total = snapshot.hasData ? snapshot.data!.docs.length : 0;
          final present = snapshot.hasData
              ? snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['buradaMi'] ?? true).length
              : 0;
          return Row(
            children: [
              _statCard("Toplam", "$total", Icons.people_alt_rounded),
              const SizedBox(width: 12),
              _statCard("Katılan", "$present", Icons.check_circle_rounded),
              const SizedBox(width: 12),
              _statCard("Gelmeyen", "${total - present}", Icons.cancel_rounded),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _bulutListeInsaEt() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.ogrencilerStream(widget.sinifId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
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
                Text("Henüz öğrenci yok",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Text("Sağ üstteki butonla öğrenci ekleyin",
                    style: TextStyle(color: Colors.grey.shade400)),
              ],
            ),
          );
        }
        return _listeInsaEt(liste);
      },
    );
  }

  Widget _listeInsaEt(List<Ogrenci> liste) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: liste.length,
      itemBuilder: (context, i) {
        final o = liste[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            elevation: 1,
            shadowColor: Colors.black.withAlpha(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _ogrenciDuzenle(o),
              onLongPress: () {
                o.buradaMi = !o.buradaMi;
                _save(o);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: o.isMale
                              ? [Colors.blue.shade300, Colors.blue.shade500]
                              : [Colors.pink.shade300, Colors.pink.shade500],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(o.isMale ? "♂" : "♀",
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(o.ad,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700, fontSize: 15,
                                      decoration: o.buradaMi ? null : TextDecoration.lineThrough,
                                      color: o.buradaMi ? Colors.black87 : Colors.grey,
                                    )),
                              ),
                              if (!o.buradaMi) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: Text("Yok", style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ],
                          ),
                          if (o.not.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(o.not, maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                    _rozetGrubu(o),
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
          _rozet('👟', o.ayakkabiEksik),
          _rozet('👕', o.kiyafetEksik),
          _rozet(o.sariKart >= 2 ? '🟥' : '🟨', o.sariKart),
          _rozet('🏥', o.saglikDurumu),
        ],
      ),
    );
  }

  Widget _rozet(String icon, int val) {
    if (val == 0) {
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(icon, style: const TextStyle(fontSize: 20)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Badge(
        label: Text('$val', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
        backgroundColor: val < 0 ? Colors.red : Colors.green,
        child: Text(icon, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  void _save(Ogrenci o) {
    _db.ogrenciGuncelle(widget.sinifId, o);
  }

  void _durumPopUp(Ogrenci o) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: o.isMale
                        ? [Colors.blue.shade300, Colors.blue.shade500]
                        : [Colors.pink.shade300, Colors.pink.shade500],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(o.isMale ? "♂" : "♀", style: const TextStyle(color: Colors.white, fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Flexible(child: Text(o.ad, style: const TextStyle(fontWeight: FontWeight.w700))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _artieksi("👟 Ayakkabı", o.ayakkabiEksik, (v) => setDialogState(() => o.ayakkabiEksik += v)),
              const Divider(height: 1),
              _artieksi("👕 Kıyafet", o.kiyafetEksik, (v) => setDialogState(() => o.kiyafetEksik += v)),
              const Divider(height: 1),
              _artieksi("🟨 Kart", o.sariKart, (v) => setDialogState(() => o.sariKart += v)),
              const Divider(height: 1),
              _artieksi("🏥 Sağlık", o.saglikDurumu, (v) => setDialogState(() => o.saglikDurumu += v)),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white,
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

  Widget _artieksi(String label, int val, Function(int) onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.remove_circle_rounded, color: Colors.red), onPressed: () => onEdit(-1), iconSize: 28),
              SizedBox(width: 32, child: Text("$val", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
              IconButton(icon: const Icon(Icons.add_circle_rounded, color: Colors.green), onPressed: () => onEdit(1), iconSize: 28),
            ]),
          ),
        ],
      ),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _genderChip("Erkek ♂", o.isMale, Colors.blue, () => setDialogState(() => o.isMale = true)),
                  const SizedBox(width: 10),
                  _genderChip("Kız ♀", !o.isMale, Colors.pink, () => setDialogState(() => o.isMale = false)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pC,
                decoration: InputDecoration(
                  labelText: "Yetenek Puanı",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange.shade700, width: 2)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nC,
                decoration: InputDecoration(
                  labelText: "Özel Not",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.orange.shade700, width: 2)),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton.icon(
              onPressed: () => _ogrenciSilOnay(dialogContext, o),
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              label: const Text("Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white,
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
        child: Text(label, style: TextStyle(
          color: selected ? color : Colors.grey,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
        )),
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

  // --- HIZLI SINIF OLUŞTUR (Yeni tasarım - bottom sheet) ---
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
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.group_add_rounded, color: Colors.orange.shade700, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text("Hızlı Öğrenci Ekle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                      TextButton.icon(
                        onPressed: () => setSheetState(() => satirlar.add(TopluOgrenciSatiri())),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text("Satır"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Column headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Expanded(flex: 5, child: Text("Ad Soyad", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey))),
                      SizedBox(width: 44, child: Center(child: Text("C", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)))),
                      SizedBox(width: 54, child: Center(child: Text("Puan", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade500)))),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),
                const Divider(height: 12),
                // Student rows
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: List.generate(satirlar.length, (i) {
                      final satir = satirlar[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Sıra no
                              SizedBox(
                                width: 24,
                                child: Text("${i + 1}", style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                              ),
                              // Ad Soyad
                              Expanded(
                                flex: 5,
                                child: TextField(
                                  controller: satir.adCtrl,
                                  decoration: const InputDecoration(
                                    hintText: "Ad Soyad",
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              // Cinsiyet
                              GestureDetector(
                                onTap: () => setSheetState(() => satir.isMale = !satir.isMale),
                                child: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: satir.isMale
                                          ? [Colors.blue.shade200, Colors.blue.shade400]
                                          : [Colors.pink.shade200, Colors.pink.shade400],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(satir.isMale ? "♂" : "♀",
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Puan
                              SizedBox(
                                width: 54,
                                child: TextField(
                                  controller: satir.puanCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              // Sil
                              IconButton(
                                icon: Icon(Icons.close_rounded, color: Colors.red.shade300, size: 20),
                                onPressed: () { satir.dispose(); setSheetState(() => satirlar.removeAt(i)); },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 36),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Bottom save bar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      Text("${satirlar.length} satır",
                          style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          for (var s in satirlar) { s.dispose(); }
                          Navigator.pop(sheetContext);
                        },
                        child: Text("İptal", style: TextStyle(color: Colors.grey.shade600)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.save_rounded, size: 20),
                        label: const Text("Tümünü Kaydet", style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () async {
                          int eklenen = 0;
                          for (var s in satirlar) {
                            if (s.adCtrl.text.trim().isNotEmpty) {
                              await _db.ogrenciEkle(widget.sinifId, Ogrenci(
                                id: '', ad: s.adCtrl.text.trim(), isMale: s.isMale,
                                puan: int.tryParse(s.puanCtrl.text) ?? 100,
                              ));
                              eklenen++;
                            }
                          }
                          for (var s in satirlar) { s.dispose(); }
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("$eklenen öğrenci eklendi!"),
                                backgroundColor: Colors.green.shade700,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  decoration: InputDecoration(
                    hintText: "Yeni Renk Ekle (Örn: Mor)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (c.text.isNotEmpty) {
                  setDialogState(() => formaRenkleri.add(c.text));
                  c.clear();
                  setState(() {});
                }
              },
              child: const Text("Ekle"),
            ),
            TextButton(
              onPressed: () {
                _db.formaRenkleriniGuncelle(widget.sinifId, formaRenkleri);
                Navigator.pop(context);
              },
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
      case 'turuncu': return Colors.orange;
      case 'mor': return Colors.purple;
      case 'pembe': return Colors.pink;
      case 'lacivert': return Colors.indigo;
      case 'gri': return Colors.grey;
      default: return Colors.orange;
    }
  }

  // --- TAKıM KURMA: puan + rastgele varyasyon (-4/+4) ---
  void _takimlariKur() async {
    final gelenler = (await _db.ogrencileriGetir(widget.sinifId))
        .where((o) => o.buradaMi).toList();

    if (gelenler.length < secilenTakimSayisi) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Yeterli öğrenci yok."),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    // Her öğrenciye -4 ile +4 arası rastgele varyasyon ekle
    final Map<String, int> efektifPuan = {};
    for (var o in gelenler) {
      efektifPuan[o.id] = o.puan + _random.nextInt(9) - 4; // -4 ile +4
    }

    // Efektif puana göre sırala
    gelenler.sort((a, b) => efektifPuan[b.id]!.compareTo(efektifPuan[a.id]!));

    // Snake draft
    List<List<Ogrenci>> takimlar = List.generate(secilenTakimSayisi, (_) => []);
    for (int i = 0; i < gelenler.length; i++) {
      int round = i ~/ secilenTakimSayisi;
      int index = round.isEven
          ? i % secilenTakimSayisi
          : (secilenTakimSayisi - 1) - (i % secilenTakimSayisi);
      takimlar[index].add(gelenler[i]);
    }

    // Rastgele komik takım isimleri
    final takimIsimleri = _rastgeleTakimIsimleri(secilenTakimSayisi);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("AI Takım Dağılımı", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      Text("${gelenler.length} oyuncu  •  $secilenTakimSayisi takım",
                          style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                  Material(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      icon: Icon(Icons.refresh_rounded, color: Colors.orange.shade700, size: 28),
                      tooltip: "Yeniden Karıştır",
                      onPressed: () { Navigator.pop(context); _takimlariKur(); },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: secilenTakimSayisi,
                itemBuilder: (context, i) {
                  String takimRenkAdi = formaRenkleri.length > i ? formaRenkleri[i] : 'Siyah';
                  Color gorselRenk = _takimRenginiBul(takimRenkAdi);
                  String komikIsim = takimIsimleri.length > i ? takimIsimleri[i] : "Bilinmeyen Takım";
                  final takim = takimlar[i];

                  // Kaptan: takımdaki rastgele efektif puana göre en yüksek
                  // (varyasyon sayesinde her seferinde farklı olabilir)
                  Ogrenci? kaptan;
                  if (takim.isNotEmpty) {
                    kaptan = takim.reduce((a, b) => efektifPuan[a.id]! >= efektifPuan[b.id]! ? a : b);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 2,
                      shadowColor: gorselRenk.withAlpha(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: gorselRenk.withAlpha(80), width: 1.5),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [gorselRenk.withAlpha(180), gorselRenk]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                        ),
                        title: Text(komikIsim,
                            style: TextStyle(fontWeight: FontWeight.w800, color: gorselRenk == Colors.grey.shade400 ? Colors.black87 : gorselRenk, fontSize: 16)),
                        subtitle: Text("$takimRenkAdi  •  ${takim.length} Oyuncu",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        children: takim.map((o) {
                          bool isKaptan = kaptan != null && o.id == kaptan.id;
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: o.isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(child: Text(o.isMale ? "♂" : "♀",
                                  style: TextStyle(color: o.isMale ? Colors.blue : Colors.pink, fontSize: 14))),
                            ),
                            title: Row(
                              children: [
                                Text(o.ad, style: TextStyle(
                                    fontWeight: isKaptan ? FontWeight.w800 : FontWeight.w500,
                                    color: isKaptan ? Colors.amber.shade900 : null)),
                                if (isKaptan) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber.shade300),
                                    ),
                                    child: Text("© Kaptan", style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
