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

  /// Firestore batch sınırı 500 — güvenli tarafta 450'lik parçalar.
  static const int _batchBoyutu = 450;

  /// Bir alt koleksiyonun tamamını parçalar hâlinde siler.
  ///
  /// Firestore'da üst dokümanı silmek alt koleksiyonlarını SİLMEZ; tek tek
  /// temizlenmezlerse yetim kalırlar. Üstelik yetkilendirme kuralı üst
  /// dokümanın `ownerId`'sine baktığı için üst silindikten sonra bu
  /// kayıtlar okunamaz ama silinemez hâle gelir.
  Future<void> _altKoleksiyonuSil(CollectionReference<Map<String, dynamic>> col) async {
    final snap = await col.get();
    for (var i = 0; i < snap.docs.length; i += _batchBoyutu) {
      final batch = _db.batch();
      final son = (i + _batchBoyutu < snap.docs.length)
          ? i + _batchBoyutu
          : snap.docs.length;
      for (var j = i; j < son; j++) {
        batch.delete(snap.docs[j].reference);
      }
      await batch.commit();
    }
  }

  Future<void> sinifSil(String sinifId) async {
    final sinifRef = _db.collection('siniflar').doc(sinifId);
    await _altKoleksiyonuSil(sinifRef.collection('ogrenciler'));
    await _altKoleksiyonuSil(sinifRef.collection('yoklamalar'));
    await sinifRef.delete();
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

  /// Sınıfın kontrol/yoklama kalemlerini günceller.
  Future<void> kontrolKalemleriGuncelle(String sinifId, List<KontrolKalemi> kalemler) async {
    await _db.collection('siniflar').doc(sinifId).update({
      'kontrolKalemleri': kalemler.map((k) => k.toMap()).toList(),
    });
  }

  // --- Yoklama (günlük tarihli kayıt) ---

  /// Belirli bir günün yoklama kaydını getirir (yoksa null).
  Future<Map<String, dynamic>?> yoklamaGetir(String sinifId, String tarihKey) async {
    final doc = await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('yoklamalar')
        .doc(tarihKey)
        .get();
    return doc.data();
  }

  /// Bir günün yoklamasını kaydeder. [kayitlar]: { ogrenciId: {geldi, kalemler} }.
  Future<void> yoklamaKaydet(
      String sinifId, String tarihKey, Map<String, dynamic> kayitlar) async {
    await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('yoklamalar')
        .doc(tarihKey)
        .set({
      'tarih': tarihKey,
      'guncellendi': FieldValue.serverTimestamp(),
      'kayitlar': kayitlar,
    },
            // merge: aynı sınıfı iki cihazdan işaretlerken son yazanın
            // diğerinin kayıtlarını silmesini engeller.
            SetOptions(merge: true));
  }

  /// Bir öğrencinin geçmiş yoklama kayıtlarını (tarih sıralı) getirir.
  Future<List<Map<String, dynamic>>> yoklamaGecmisi(String sinifId) async {
    final snap = await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('yoklamalar')
        .orderBy('tarih', descending: true)
        .limit(60)
        .get();
    return snap.docs.map((d) => {'tarih': d.id, ...d.data()}).toList();
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

  Future<void> ogrenciEkle(String sinifId, Ogrenci ogrenci) async {
    await _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('ogrenciler')
        .add(ogrenci.toMap());
  }

  /// Birden fazla öğrenciyi ekler. Firestore'un 500'lük batch sınırı
  /// aşılmasın diye parçalara bölünür — tek batch'te gönderilirse 500'ü
  /// aşan girişte hiçbir kayıt yazılmaz.
  Future<void> ogrencilerTopluEkle(String sinifId, List<Ogrenci> ogrenciler) async {
    final col = _db.collection('siniflar').doc(sinifId).collection('ogrenciler');
    for (var i = 0; i < ogrenciler.length; i += _batchBoyutu) {
      final batch = _db.batch();
      final son = (i + _batchBoyutu < ogrenciler.length)
          ? i + _batchBoyutu
          : ogrenciler.length;
      for (var j = i; j < son; j++) {
        batch.set(col.doc(), ogrenciler[j].toMap());
      }
      await batch.commit();
    }
  }

  /// Sınıftaki mevcut öğrenci adlarını döndürür (mükerrer kontrolü için).
  ///
  /// Eski kayıtlar şifreli yazılmıştı; ham `ad` alanını okumak şifreli
  /// metni düz metinle karşılaştırmak demekti ve mükerrer kontrolü
  /// sessizce hiç çalışmıyordu. `Ogrenci.fromMap` bayrağa göre çözüyor.
  Future<Set<String>> mevcutOgrenciAdlari(String sinifId) async {
    final ogrenciler = await ogrencileriGetir(sinifId);
    return ogrenciler.map((o) => o.ad.trim()).where((a) => a.isNotEmpty).toSet();
  }

  DocumentReference<Map<String, dynamic>> _ogrenciRef(
          String sinifId, String ogrenciId) =>
      _db
          .collection('siniflar')
          .doc(sinifId)
          .collection('ogrenciler')
          .doc(ogrenciId);

  /// Tek bir alanı günceller — tüm dokümanı geri yazmaz.
  ///
  /// Öğrencinin "burada mı" durumu gibi tek alanlık değişikliklerde tüm
  /// dokümanı yazmak, aynı sınıfı ikinci bir cihazdan yöneten öğretmenin
  /// o sırada girdiği puan/sayaç/not değişikliklerini siler.
  Future<void> buradaMiGuncelle(
      String sinifId, String ogrenciId, bool buradaMi) async {
    await _ogrenciRef(sinifId, ogrenciId).update({'buradaMi': buradaMi});
  }

  /// Rozet ekler/çıkarır. `arrayUnion`/`arrayRemove` sunucu tarafında
  /// çalıştığı için listenin tamamını geri yazmaya gerek kalmaz.
  Future<void> rozetEkle(
      String sinifId, String ogrenciId, Map<String, dynamic> rozet) async {
    await _ogrenciRef(sinifId, ogrenciId)
        .update({'rozetler': FieldValue.arrayUnion([rozet])});
  }

  Future<void> rozetSil(
      String sinifId, String ogrenciId, Map<String, dynamic> rozet) async {
    await _ogrenciRef(sinifId, ogrenciId)
        .update({'rozetler': FieldValue.arrayRemove([rozet])});
  }

  /// Kontrol kalemi sayaçlarını FARK olarak uygular.
  ///
  /// Oku-değiştir-yaz yerine işlem (transaction) kullanılıyor: iki cihazdan
  /// aynı anda sarı kart verildiğinde ikisi de sayılır, son yazan diğerini
  /// silmez. 0-999 kırpması ve eski PE alanlarının (sariKart, kiyafetEksik,
  /// ayakkabiEksik) yansıtılması sunucudan okunan güncel değer üzerinden
  /// yapılır — v1.0/1.0.1 istemcileri hâlâ o alanları okuyor.
  Future<void> kalemSayaclariniUygula(
    String sinifId,
    String ogrenciId,
    Map<String, int> farklar, {
    List<Map<String, dynamic>>? saglikNotlari,
  }) async {
    final temizFarklar = Map<String, int>.from(farklar)
      ..removeWhere((_, v) => v == 0);
    if (temizFarklar.isEmpty && saglikNotlari == null) return;

    final ref = _ogrenciRef(sinifId, ogrenciId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? <String, dynamic>{};

      final mevcut = <String, int>{};
      final raw = data['kalemSayaclari'];
      if (raw is Map) {
        raw.forEach((k, v) => mevcut[k.toString()] = (v as num?)?.toInt() ?? 0);
      }

      temizFarklar.forEach((id, delta) {
        final yeni = ((mevcut[id] ?? 0) + delta).clamp(0, 999);
        if (yeni == 0) {
          mevcut.remove(id);
        } else {
          mevcut[id] = yeni;
        }
      });

      tx.update(ref, {
        'kalemSayaclari': mevcut,
        // Geriye dönük uyumluluk alanları
        'sariKart': mevcut['sari_kart'] ?? 0,
        'kiyafetEksik': mevcut['kiyafet'] ?? 0,
        'ayakkabiEksik': mevcut['ayakkabi'] ?? 0,
        if (saglikNotlari != null)
          'saglikNotlari': saglikNotlari.length > Ogrenci.saglikNotuMaxAdet
              ? saglikNotlari
                  .sublist(saglikNotlari.length - Ogrenci.saglikNotuMaxAdet)
              : saglikNotlari,
      });
    });
  }

  /// Öğrenci kartından kaydederken sayaçlar (kalemSayaclari + geriye dönük
  /// sariKart/kiyafetEksik/ayakkabiEksik) FARK olarak ayrı işlemde yazılır;
  /// burada mutlak değerleriyle üzerine yazılmasın diye dışarıda bırakılır.
  Future<void> ogrenciAlanlariniGuncelle(
      String sinifId, String ogrenciId, Map<String, dynamic> alanlar) async {
    final temiz = Map<String, dynamic>.from(alanlar)
      ..remove('kalemSayaclari')
      ..remove('sariKart')
      ..remove('kiyafetEksik')
      ..remove('ayakkabiEksik');
    await _ogrenciRef(sinifId, ogrenciId).update(temiz);
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

  /// Eski şifreli kayıtları (`sifrelendi: true`) düz metne göç ettirir.
  ///
  /// Yön v1.1.1'de tersine döndü: şifreleme koruma sağlamadığı hâlde
  /// sunucu tarafı sorguları bozuyordu (bkz. sifreleme_service.dart).
  /// Göç, kayıt okunurken çözülüp düz metin geri yazılarak yapılıyor.
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
      if (data['sifrelendi'] == true) {
        // Şifreli veriyi çöz, model üzerinden düz metin yaz
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
      await _altKoleksiyonuSil(sinif.reference.collection('ogrenciler'));
      // Yoklama kayıtları da silinmeli — yoksa öğrencilerin devamsızlık ve
      // ceza kayıtları hesap silindikten sonra veritabanında kalır.
      await _altKoleksiyonuSil(sinif.reference.collection('yoklamalar'));
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
