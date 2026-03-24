import '../tema.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'ogrenci_listesi_ekrani.dart';

class SiniflarEkrani extends StatelessWidget {
  const SiniflarEkrani({super.key});

  FirestoreService get _db => FirestoreService(uid: AuthService().uid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Sınıflarım', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTema.ana, AppTema.anaAcik],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hoş geldiniz!",
                    style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14)),
                const SizedBox(height: 4),
                Text(AuthService().currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.class_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("Henüz sınıf eklenmedi",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                        const SizedBox(height: 8),
                        Text("Sağ alttaki + butonuyla başlayın",
                            style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, i) => _sinifKarti(context, snapshot.data!.docs[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _sinifEkle(context),
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Sınıf Ekle", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _sinifKarti(BuildContext context, QueryDocumentSnapshot doc) {
    final ad = doc.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OgrenciListesiEkrani(sinifId: ad)),
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
                      colors: [AppTema.anaAcik, AppTema.anaKoyu],
                    ),
                    borderRadius: BorderRadius.circular(14),
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
                      // Öğrenci sayısını göster
                      StreamBuilder<QuerySnapshot>(
                        stream: FirestoreService(uid: AuthService().uid)
                            .ogrencilerStream(ad),
                        builder: (context, snap) {
                          final count = snap.hasData ? snap.data!.docs.length : 0;
                          return Text("$count öğrenci",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13));
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300),
                  onPressed: () => _sinifSilOnay(context, ad),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sinifEkle(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
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
            onPressed: () {
              if (c.text.isNotEmpty) {
                _db.sinifEkle(c.text.toUpperCase());
                Navigator.pop(context);
              }
            },
            child: const Text('Ekle', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
