import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ogrenci.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

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
  List<String> aiTakimIsimleri = [
    "Kopernik", "Zımbalar", "Gırlatanlar", "Atik Spor",
    "Pro Gamerlar", "Newton", "Zıpırlar", "Peder",
  ];
  bool _renkleriYuklendi = false;

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
      appBar: AppBar(
        title: Text(widget.sinifId),
        actions: [
          IconButton(
              icon: const Icon(Icons.group_add),
              onPressed: _hizliSinifEkleDialog,
              tooltip: 'Hızlı Sınıf Oluştur'),
          IconButton(
              icon: const Icon(Icons.palette_outlined),
              onPressed: _renkYonetimi,
              tooltip: 'Takım Renkleri'),
        ],
      ),
      body: _bulutListeInsaEt(),
      bottomNavigationBar: _renkleriYuklendi
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  DropdownButton<int>(
                    value: secilenTakimSayisi,
                    items: List.generate(
                            formaRenkleri.length > 1 ? formaRenkleri.length - 1 : 1,
                            (i) => i + 2)
                        .map((e) => DropdownMenuItem(value: e, child: Text("$e Takım")))
                        .toList(),
                    onChanged: (val) => setState(() => secilenTakimSayisi = val!),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white),
                    onPressed: _takimlariKur,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text("AI Takım Kur"),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _bulutListeInsaEt() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.ogrencilerStream(widget.sinifId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        List<Ogrenci> liste = snapshot.data!.docs
            .map((d) => Ogrenci.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();
        return _listeInsaEt(liste);
      },
    );
  }

  Widget _listeInsaEt(List<Ogrenci> liste) {
    int gelenler = liste.where((o) => o.buradaMi).length;
    return Column(
      children: [
        Chip(
            label: Text("Derse Katılan: $gelenler / ${liste.length}"),
            backgroundColor: Colors.orange.shade50),
        Expanded(
          child: ListView.builder(
            itemCount: liste.length,
            itemBuilder: (context, i) {
              final o = liste[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        o.isMale ? Colors.blue.shade50 : Colors.pink.shade50,
                    child: Text(o.isMale ? "♂" : "♀",
                        style: TextStyle(
                            color: o.isMale ? Colors.blue : Colors.pink)),
                  ),
                  title: Text(o.ad,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration:
                              o.buradaMi ? null : TextDecoration.lineThrough)),
                  subtitle: o.not.isNotEmpty
                      ? Text("📝 ${o.not}", maxLines: 1)
                      : null,
                  trailing: _rozetGrubu(o),
                  onTap: () => _ogrenciDuzenle(o),
                  onLongPress: () {
                    o.buradaMi = !o.buradaMi;
                    _save(o);
                  },
                ),
              );
            },
          ),
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(icon, style: const TextStyle(fontSize: 22)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Badge(
        label: Text('$val', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: val < 0 ? Colors.red : Colors.green,
        child: Text(icon, style: const TextStyle(fontSize: 22)),
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
          title: Text(o.ad),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _artieksi("👟 Ayakkabı", o.ayakkabiEksik,
                  (v) => setDialogState(() => o.ayakkabiEksik += v)),
              _artieksi("👕 Kıyafet", o.kiyafetEksik,
                  (v) => setDialogState(() => o.kiyafetEksik += v)),
              _artieksi("🟨 Kart", o.sariKart,
                  (v) => setDialogState(() => o.sariKart += v)),
              _artieksi("🏥 Sağlık", o.saglikDurumu,
                  (v) => setDialogState(() => o.saglikDurumu += v)),
            ],
          ),
          actions: [
            ElevatedButton(
                onPressed: () {
                  _save(o);
                  Navigator.pop(context);
                },
                child: const Text("Kapat ve Kaydet")),
          ],
        ),
      ),
    );
  }

  Widget _artieksi(String label, int val, Function(int) onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(children: [
          IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => onEdit(-1)),
          Text("$val",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              onPressed: () => onEdit(1)),
        ]),
      ],
    );
  }

  void _ogrenciDuzenle(Ogrenci o) {
    final pC = TextEditingController(text: o.puan.toString());
    final nC = TextEditingController(text: o.not);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(o.ad),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                        label: const Text("Erkek ♂"),
                        selected: o.isMale,
                        onSelected: (s) =>
                            setDialogState(() => o.isMale = true)),
                    const SizedBox(width: 10),
                    ChoiceChip(
                        label: const Text("Kız ♀"),
                        selected: !o.isMale,
                        onSelected: (s) =>
                            setDialogState(() => o.isMale = false)),
                  ]),
              const SizedBox(height: 10),
              TextField(
                  controller: pC,
                  decoration:
                      const InputDecoration(labelText: "Yetenek Puanı"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: nC,
                  decoration: const InputDecoration(labelText: "Özel Not"),
                  maxLines: 2),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: dialogContext,
                  builder: (c2) => AlertDialog(
                    title: const Text("Öğrenciyi Sil"),
                    content: Text(
                        "${o.ad} isimli öğrenciyi kalıcı olarak silmek istediğinize emin misiniz?"),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(c2),
                          child: const Text("İptal")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white),
                        onPressed: () async {
                          await _db.ogrenciSil(widget.sinifId, o.id);
                          if (c2.mounted) Navigator.pop(c2);
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                        },
                        child: const Text("Evet, Sil"),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text("Sil", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                o.puan = int.tryParse(pC.text) ?? 100;
                o.not = nC.text;
                _save(o);
                Navigator.pop(dialogContext);
              },
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    ).then((_) {
      pC.dispose();
      nC.dispose();
    });
  }

  void _hizliSinifEkleDialog() {
    List<TopluOgrenciSatiri> satirlar =
        List.generate(5, (i) => TopluOgrenciSatiri());
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDState) => AlertDialog(
          title: const Text("Hızlı Sınıf Oluştur"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: satirlar.length,
              itemBuilder: (context, i) => Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: satirlar[i].adCtrl,
                          decoration:
                              const InputDecoration(hintText: "Ad Soyad"))),
                  IconButton(
                      icon: Text(satirlar[i].isMale ? "♂" : "♀"),
                      onPressed: () => setDState(
                          () => satirlar[i].isMale = !satirlar[i].isMale)),
                  SizedBox(
                      width: 45,
                      child: TextField(
                          controller: satirlar[i].puanCtrl,
                          keyboardType: TextInputType.number)),
                  IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        satirlar[i].dispose();
                        setDState(() => satirlar.removeAt(i));
                      }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () =>
                    setDState(() => satirlar.add(TopluOgrenciSatiri())),
                child: const Text("Satır Ekle")),
            ElevatedButton(
                onPressed: () async {
                  for (var s in satirlar) {
                    if (s.adCtrl.text.isNotEmpty) {
                      await _db.ogrenciEkle(
                        widget.sinifId,
                        Ogrenci(
                            id: '',
                            ad: s.adCtrl.text.trim(),
                            isMale: s.isMale,
                            puan: int.tryParse(s.puanCtrl.text) ?? 100),
                      );
                    }
                  }
                  for (var s in satirlar) {
                    s.dispose();
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Kaydet")),
          ],
        ),
      ),
    );
  }

  void _renkYonetimi() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Forma Renkleri"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                          spacing: 8,
                          children: formaRenkleri
                              .map((r) => Chip(
                                  label: Text(r),
                                  onDeleted: () => setDialogState(
                                      () => formaRenkleri.remove(r))))
                              .toList()),
                      const SizedBox(height: 10),
                      TextField(
                          controller: c,
                          decoration: const InputDecoration(
                              hintText: "Yeni Renk Ekle (Örn: Mor)")),
                    ]),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (c.text.isNotEmpty) {
                      setDialogState(() {
                        formaRenkleri.add(c.text);
                      });
                      c.clear();
                      setState(() {});
                    }
                  },
                  child: const Text("Ekle"),
                ),
                TextButton(
                    onPressed: () {
                      _db.formaRenkleriniGuncelle(
                          widget.sinifId, formaRenkleri);
                      Navigator.pop(context);
                    },
                    child: const Text("Kaydet ve Kapat")),
              ],
            );
          },
        );
      },
    ).then((_) => c.dispose());
  }

  Color _takimRenginiBul(String renkAdi) {
    switch (renkAdi.toLowerCase().trim()) {
      case 'kırmızı':
        return Colors.red;
      case 'mavi':
        return Colors.blue;
      case 'sarı':
        return Colors.amber.shade600;
      case 'yeşil':
        return Colors.green;
      case 'siyah':
        return Colors.black87;
      case 'beyaz':
        return Colors.grey.shade400;
      case 'turuncu':
        return Colors.orange;
      case 'mor':
        return Colors.purple;
      case 'pembe':
        return Colors.pink;
      case 'lacivert':
        return Colors.indigo;
      case 'gri':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _takimlariKur() async {
    final gelenler = (await _db.ogrencileriGetir(widget.sinifId))
        .where((o) => o.buradaMi)
        .toList();

    if (gelenler.length < secilenTakimSayisi) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yeterli öğrenci yok.")),
        );
      }
      return;
    }

    // Puana göre sırala (yüksekten düşüğe)
    gelenler.sort((a, b) => b.puan.compareTo(a.puan));

    // Snake draft: dengeli takım dağılımı
    // Tur 0: 0,1,2 | Tur 1: 2,1,0 | Tur 2: 0,1,2 | ...
    List<List<Ogrenci>> takimlar =
        List.generate(secilenTakimSayisi, (_) => []);
    for (int i = 0; i < gelenler.length; i++) {
      int round = i ~/ secilenTakimSayisi;
      int index = round.isEven
          ? i % secilenTakimSayisi
          : (secilenTakimSayisi - 1) - (i % secilenTakimSayisi);
      takimlar[index].add(gelenler[i]);
    }

    List<String> karisikIsimler = [...aiTakimIsimleri]..shuffle();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("AI Takım Dağılımı",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.orange, size: 28),
                  tooltip: "Takımları Yeniden Karıştır",
                  onPressed: () {
                    Navigator.pop(context);
                    _takimlariKur();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
                child: ListView.builder(
              itemCount: secilenTakimSayisi,
              itemBuilder: (context, i) {
                String takimRenkAdi =
                    formaRenkleri.length > i ? formaRenkleri[i] : 'Siyah';
                Color gorselRenk = _takimRenginiBul(takimRenkAdi);
                String komikIsim = karisikIsimler.length > i
                    ? karisikIsimler[i]
                    : "Atik Spor";

                final takim = takimlar[i];
                takim.sort((a, b) => b.puan.compareTo(a.puan));
                Ogrenci? kaptan = takim.isNotEmpty ? takim.first : null;

                return Card(
                  color: gorselRenk.withAlpha(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                        color: gorselRenk.withAlpha(128), width: 1.5),
                  ),
                  child: ExpansionTile(
                    leading:
                        Icon(Icons.shield, color: gorselRenk, size: 30),
                    title: Text("$takimRenkAdi $komikIsim",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: gorselRenk == Colors.grey.shade400
                                ? Colors.black87
                                : gorselRenk,
                            fontSize: 17)),
                    subtitle: Text("${takimlar[i].length} Oyuncu"),
                    children: takim.map((o) {
                      String kaptanSimgesi =
                          (kaptan != null && o.id == kaptan.id) ? " ©" : "";
                      return ListTile(
                        dense: true,
                        title: Text(o.ad + kaptanSimgesi,
                            style: TextStyle(
                                fontWeight: kaptanSimgesi.isNotEmpty
                                    ? FontWeight.bold
                                    : null,
                                color: kaptanSimgesi.isNotEmpty
                                    ? Colors.amber.shade900
                                    : null)),
                        leading: Text(o.isMale ? "♂" : "♀",
                            style: TextStyle(
                                color:
                                    o.isMale ? Colors.blue : Colors.pink,
                                fontSize: 14)),
                      );
                    }).toList(),
                  ),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}
