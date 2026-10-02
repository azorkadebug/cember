import 'package:flutter/material.dart';

import '../models/ogrenci.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../tema.dart';
import '../utils/egitim_yili.dart';
import '../utils/metin.dart';
import '../widgets/simgeler.dart';

/// Geçmiş bir yılın sınıfı, salt okunur.
///
/// Arşivdeki sınıfta yoklama alınmaz, takım kurulmaz: öğretmen yalnız
/// kimin olduğunu görür, sınıfı bu yıla geri alır ya da siler. Öğrencileri
/// yeni sınıfa taşımak hedef sınıftaki "Geçen Yıldan Ekle" ile yapılır.
class ArsivSinifEkrani extends StatefulWidget {
  final String sinifId;
  final String sinifAd;
  final String egitimYili;
  const ArsivSinifEkrani({super.key, required this.sinifId, required this.sinifAd, required this.egitimYili});

  @override
  State<ArsivSinifEkrani> createState() => _ArsivSinifEkraniState();
}

class _ArsivSinifEkraniState extends State<ArsivSinifEkrani> {
  late final FirestoreService _db = FirestoreService(uid: AuthService().uid);
  late Future<List<Ogrenci>> _ogrenciler = _getir();

  Future<List<Ogrenci>> _getir() async =>
      (await _db.ogrencileriGetir(widget.sinifId))..sort((a, b) => trKarsilastir(a.gorunenAd, b.gorunenAd));

  Future<void> _buYilaAl() async {
    try {
      await _db.sinifEgitimYiliniGuncelle(widget.sinifId, EgitimYili.simdiki);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${widget.sinifAd} bu yılın sınıflarına alındı."),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Taşınamadı. ${FirestoreService.hataMesaji(e)}"),
        backgroundColor: AppTema.tehlike,
      ));
    }
  }

  Future<void> _sil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade700),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text("Sınıf silinsin mi?", style: TextStyle(fontWeight: FontWeight.w700))),
        ]),
        content: Text(
            "${widget.sinifAd} (${widget.egitimYili}) sınıfı, öğrencileri ve yoklama geçmişiyle birlikte kalıcı olarak silinecek. "
            "Bu yıla aktardığın öğrenciler etkilenmez.",
            style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Evet, Sil"),
          ),
        ],
      ),
    );
    if (onay != true) return;
    try {
      await _db.sinifSil(widget.sinifId);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Silinemedi. ${FirestoreService.hataMesaji(e)}"),
        backgroundColor: AppTema.tehlike,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.sinifAd, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Text("Arşiv · ${widget.egitimYili}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
        ]),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sınıf işlemleri',
            onSelected: (s) => s == 'al' ? _buYilaAl() : _sil(),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'al',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.unarchive_rounded),
                  title: Text('Bu Yıla Geri Al'),
                ),
              ),
              PopupMenuItem(
                value: 'sil',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                  title: Text('Sınıfı Sil', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
          child: FutureBuilder<List<Ogrenci>>(
            future: _ogrenciler,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text("Öğrenciler okunamadı.", style: TextStyle(color: AppTema.tehlike)),
                    TextButton(
                      onPressed: () => setState(() => _ogrenciler = _getir()),
                      child: const Text("Tekrar Dene"),
                    ),
                  ]),
                );
              }
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppTema.vurgu));
              final liste = snap.data!;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTema.uyariZemin, borderRadius: BorderRadius.circular(12)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.inventory_2_rounded, size: 18, color: AppTema.uyari),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                            "Bu sınıf arşivde ve salt okunur. Öğrencilerini yeni sınıflarına aktarmak için o sınıfta ⋮ menüsünden \"Geçen Yıldan Ekle\"yi kullan.",
                            style: TextStyle(fontSize: 13, color: AppTema.uyari, height: 1.4)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text("${liste.length} öğrenci",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppTema.metinUcuncul)),
                  const SizedBox(height: 8),
                  if (liste.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: Text("Bu sınıfta öğrenci yok.", style: TextStyle(color: AppTema.metinUcuncul))),
                    ),
                  for (final o in liste)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          dense: true,
                          leading: CinsiyetSimgesi(o.isMale),
                          title: Text(o.gorunenAd, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          trailing: o.saglikNotlari.isEmpty
                              ? null
                              : const Icon(Icons.medical_services_rounded, size: 18, color: Colors.teal),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
