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

  /// Sınıf adındaki / karakteri Firestore doc ID'sinde kullanılamaz
  static String _safeDocId(String ad) => ad.replaceAll('/', '-');

  Future<void> sinifEkle(String sinifAdi, {List<String>? formaRenkleri}) async {
    await _db.collection('siniflar').doc(_safeDocId(sinifAdi)).set({
      'created': FieldValue.serverTimestamp(),
      'ownerId': uid,
      'ad': sinifAdi,
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

  Future<void> sinifAdiniGuncelle(String sinifId, String yeniAd) async {
    await _db.collection('siniflar').doc(sinifId).update({'ad': yeniAd});
  }

  // --- Profil ---

  Future<Map<String, dynamic>?> profilGetir() async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> profilKaydet(Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> profilVarMi() async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists && (doc.data()?['ad'] ?? '').toString().isNotEmpty;
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

  /// Şifrelenmemiş öğrenci verilerini tespit edip şifreler
  Future<int> sifrelemeyiMigrate(String sinifId) async {
    final snap = await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .get();
    int sayac = 0;
    final batch = _db.batch();
    for (var doc in snap.docs) {
      final data = doc.data();
      if (data['sifrelendi'] != true) {
        // Eski veriyi oku (şifresiz), model üzerinden şifreli yaz
        final ogrenci = Ogrenci.fromMap(doc.id, data);
        batch.update(doc.reference, ogrenci.toMap());
        sayac++;
      }
    }
    if (sayac > 0) await batch.commit();
    return sayac;
  }

  /// Tüm sınıflardaki öğrencileri migrate eder
  Future<int> tumSiniflariMigrate() async {
    final siniflar = await _db
        .collection('siniflar')
        .where('ownerId', isEqualTo: uid)
        .get();
    int toplam = 0;
    for (var sinif in siniflar.docs) {
      toplam += await sifrelemeyiMigrate(sinif.id);
    }
    return toplam;
  }
}
