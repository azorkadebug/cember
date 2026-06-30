import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ogrenci.dart';
import '../models/kontrol_kalemi.dart';

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

  Future<QuerySnapshot> siniflarGetir() {
    return _db
        .collection('siniflar')
        .where('ownerId', isEqualTo: uid)
        .get();
  }

  /// Sınıf adındaki / karakteri Firestore doc ID'sinde kullanılamaz (legacy).
  /// Yeni sınıflar artık auto-id ile oluşturuluyor (aşağıya bakın), ama eski
  /// belgeler hâlâ name-based ID kullanıyor olabilir.
  static String _safeDocId(String ad) => ad.replaceAll('/', '-');

  /// Yeni sınıf oluştur. Firestore'un otomatik ID'sini kullanır — sınıf
  /// adını doc ID yapmak yerine `ad` field'ında saklar.
  ///
  /// ÖNCEKİ HATA: doc ID = sınıf adı (örn. "5A") global namespace'teydi.
  /// İki farklı öğretmen aynı adda sınıf oluşturmak isteyince ikinci'sinde
  /// Firestore rules write'ı engelliyordu (mevcut sahip yok) → sessiz fail.
  Future<void> sinifEkle(String sinifAdi,
      {String brans = 'beden_egitimi',
      List<String>? formaRenkleri,
      List<KontrolKalemi>? kontrolKalemleri}) async {
    final kalemler = kontrolKalemleri ?? bransSablonu(brans).varsayilanKalemler;
    await _db.collection('siniflar').add({
      'created': FieldValue.serverTimestamp(),
      'ownerId': uid,
      'ad': sinifAdi,
      'brans': brans,
      'kontrolKalemleri': kalemler.map((k) => k.toMap()).toList(),
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

  /// Birden fazla öğrenciyi tek batch'te ekler (max 500).
  Future<void> ogrencilerTopluEkle(String sinifId, List<Ogrenci> ogrenciler) async {
    final batch = _db.batch();
    final col = _db.collection('siniflar').doc(sinifId).collection('ogrenciler');
    for (final o in ogrenciler) {
      batch.set(col.doc(), o.toMap());
    }
    await batch.commit();
  }

  /// Sınıftaki mevcut öğrenci adlarını döndürür.
  Future<Set<String>> mevcutOgrenciAdlari(String sinifId) async {
    final snap = await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .get();
    return snap.docs.map((d) => (d.data()['ad'] as String? ?? '').trim()).toSet();
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

  /// Kullanıcıya ait tüm verileri (sınıflar + öğrenciler + profil) kalıcı
  /// olarak siler. Hesap silme akışının Firestore tarafı — geri alınamaz.
  /// Auth hesabı ayrıca silinmeli.
  Future<void> tumVerileriSil() async {
    final siniflar = await _db
        .collection('siniflar')
        .where('ownerId', isEqualTo: uid)
        .get();

    for (final sinif in siniflar.docs) {
      final ogrenciler = await sinif.reference.collection('ogrenciler').get();

      // Firestore batch sınırı 500 — chunk'lara böl
      for (var i = 0; i < ogrenciler.docs.length; i += 450) {
        final batch = _db.batch();
        final son = (i + 450 < ogrenciler.docs.length)
            ? i + 450
            : ogrenciler.docs.length;
        for (var j = i; j < son; j++) {
          batch.delete(ogrenciler.docs[j].reference);
        }
        await batch.commit();
      }

      await sinif.reference.delete();
    }

    // Profil dokümanı en son
    await _db.collection('users').doc(uid).delete();
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
