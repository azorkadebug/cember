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
      appBar: AppBar(
        title: const Text('Sınıflarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.siniflarStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text("Henüz sınıf yok. Sağ alttaki + ile ekleyin."));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: snapshot.data!.docs
                .map((doc) => _sinifKarti(context, doc.id))
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _sinifEkle(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _sinifKarti(BuildContext context, String ad) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
            backgroundColor: Colors.orange,
            child: Icon(Icons.groups, color: Colors.white)),
        title: Text(ad, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _sinifSilOnay(context, ad),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OgrenciListesiEkrani(sinifId: ad)),
        ),
      ),
    );
  }

  void _sinifEkle(BuildContext context) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Sınıf Ekle'),
        content: TextField(
            controller: c,
            decoration: const InputDecoration(hintText: 'Örn: 8/B'),
            textCapitalization: TextCapitalization.characters),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () {
                if (c.text.isNotEmpty) {
                  _db.sinifEkle(c.text.toUpperCase());
                  Navigator.pop(context);
                }
              },
              child: const Text('Ekle')),
        ],
      ),
    );
  }

  void _sinifSilOnay(BuildContext context, String sinifId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sınıfı Sil"),
        content: Text(
            "$sinifId sınıfını ve içindeki tüm öğrencileri silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _db.sinifSil(sinifId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Evet, Sil"),
          ),
        ],
      ),
    );
  }
}
