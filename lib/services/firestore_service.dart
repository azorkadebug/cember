import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ogrenci.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  // --- Sınıflar ---

  Stream<QuerySnapshot> siniflarStream() {
    return _db
        .collection('siniflar')
        .where('ownerId', isEqualTo: uid)
        .snapshots();
  }

  Future<void> sinifEkle(String sinifAdi, {List<String>? formaRenkleri}) async {
    await _db.collection('siniflar').doc(sinifAdi).set({
      'created': FieldValue.serverTimestamp(),
      'ownerId': uid,
      'formaRenkleri': formaRenkleri ?? ['Kırmızı', 'Mavi', 'Sarı', 'Yeşil', 'Siyah', 'Beyaz', 'Turuncu', 'Lacivert'],
    });
  }

  Future<void> sinifSil(String sinifId) async {
    final batch = _db.batch();
    final ogrencilerSnap = await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .get();
    for (var doc in ogrencilerSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('siniflar').doc(sinifId));
    await batch.commit();
  }

  Future<Map<String, dynamic>?> sinifBilgisiGetir(String sinifId) async {
    final doc = await _db.collection('siniflar').doc(sinifId).get();
    return doc.data();
  }

  Future<void> formaRenkleriniGuncelle(String sinifId, List<String> renkler) async {
    await _db.collection('siniflar').doc(sinifId).update({'formaRenkleri': renkler});
  }

  // --- Öğrenciler ---

  Stream<QuerySnapshot> ogrencilerStream(String sinifId) {
    return _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .snapshots();
  }

  Future<bool> ogrenciVarMi(String sinifId, String ad) async {
    final snap = await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .where('ad', isEqualTo: ad)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> ogrenciEkle(String sinifId, Ogrenci ogrenci) async {
    await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .add(ogrenci.toMap());
  }

  Future<void> ogrenciGuncelle(String sinifId, Ogrenci ogrenci) async {
    await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .doc(ogrenci.id)
        .update(ogrenci.toMap());
  }

  Future<void> ogrenciSil(String sinifId, String ogrenciId) async {
    await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .doc(ogrenciId)
        .delete();
  }

  Future<List<Ogrenci>> ogrencileriGetir(String sinifId) async {
    final snap = await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .get();
    return snap.docs
        .map((d) => Ogrenci.fromMap(d.id, d.data()))
        .toList();
  }
}
