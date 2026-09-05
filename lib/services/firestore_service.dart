import 'package:cloud_firestore/cloud_firestore.dart';
import '../tema.dart';
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
      'formaRenkleri': formaRenkleri ?? AppTema.formaRenkAdlari,
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
    // Varsayılan kaynak çevrimdışıyken/önbellek boşken boş dönüyor, sınıf
    // dokümanı siliniyor, öğrenciler yetim kalıyordu (denetim #3 Y4).
    // Sunucudan iste; olmazsa hata fırlasın, silme hiç başlamasın.
    final snap = await col.get(const GetOptions(source: Source.server));
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

  /// Listedeki "Yok yaz" kaydırması: bugünün yoklama dokümanına da işler,
  /// yoksa Yoklama ekranı ile sınıf listesi iki ayrı "yok" tutuyordu
  /// (denetim #4 Y1).
  Future<void> yoklamaTekOgrenci(String sinifId, String tarihKey, String ogrenciId, bool geldi) {
    return _db
        .collection('siniflar')
        .doc(sinifId)
        .collection('yoklamalar')
        .doc(tarihKey)
        .set({
      'tarih': tarihKey,
      'guncellendi': FieldValue.serverTimestamp(),
      'kayitlar': {ogrenciId: {'geldi': geldi}},
    }, SetOptions(merge: true));
  }

  Future<void> saglikNotuSil(String sinifId, String ogrenciId, Map<String, dynamic> not) {
    return _ogrenciRef(sinifId, ogrenciId).update({'saglikNotlari': FieldValue.arrayRemove([not])});
  }

  /// Firestore/ağ hatasını öğretmenin anlayacağı Türkçeye çevirir; ham
  /// "[cloud_firestore/permission-denied] ..." metni ekrana düşmesin
  /// (denetim #4 Y10).
  static String hataMesaji(Object e) {
    final m = e.toString();
    if (m.contains('permission-denied')) return 'Bu veriye erişim yetkin yok. Çıkıp tekrar girmeyi dene.';
    if (m.contains('resource-exhausted')) return 'Günlük kullanım sınırı doldu. Yarın tekrar dene.';
    if (m.contains('unavailable') || m.contains('network')) return 'Bağlantı yok. İnternetini kontrol edip tekrar dene.';
    if (m.contains('not-found')) return 'Kayıt bulunamadı; silinmiş olabilir.';
    return 'Bir şeyler ters gitti. Tekrar dene.';
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

  /// Öğrenci kartının tek Kaydet'i: yalnız DEĞİŞEN alanlar, sayaçlar ve
  /// sağlık FARK (FieldValue.increment), sağlık notu ve eşler arrayUnion /
  /// arrayRemove. İşlem (runTransaction) kullanılmıyor: işlem sunucu ister,
  /// çevrimdışı anında düşüyordu ve kayıt sessizce kayboluyordu (denetim #3
  /// K2). Artımlı yazma çevrimdışı kuyruğa girer, sunucuda atomik uygulanır;
  /// aynı anda iki cihazdan verilen sarı kartlar ikisi de sayılır. Mutlak
  /// yazma diğer cihazın ad/not/rozet/eş değişikliğini eziyordu (Y1).
  /// Tek WriteBatch: partner güncellemeleri de aynı anda gider.
  Future<void> ogrenciFarklariniYaz(
    String sinifId,
    String ogrenciId, {
    Map<String, dynamic> alanlar = const {},
    Map<String, int> kalemFarklari = const {},
    int saglikFarki = 0,
    List<Map<String, dynamic>> yeniSaglikNotlari = const [],
    List<String> esEkle = const [],
    List<String> esKaldir = const [],
  }) async {
    final ref = _ogrenciRef(sinifId, ogrenciId);
    final guncelleme = <String, dynamic>{
      ...alanlar,
      'sifrelendi': false,
    };
    // kalemSayaclari haritasındaki 3 PE kalemi v1.0/1.0.1 istemcileri için
    // düz alanlara da yansır.
    const eskiAd = {'sari_kart': 'sariKart', 'kiyafet': 'kiyafetEksik', 'ayakkabi': 'ayakkabiEksik'};
    kalemFarklari.forEach((id, d) {
      if (d == 0) return;
      guncelleme['kalemSayaclari.$id'] = FieldValue.increment(d);
      final eski = eskiAd[id];
      if (eski != null) guncelleme[eski] = FieldValue.increment(d);
    });
    if (saglikFarki != 0) guncelleme['saglikDurumu'] = FieldValue.increment(saglikFarki);
    if (yeniSaglikNotlari.isNotEmpty) {
      guncelleme['saglikNotlari'] = FieldValue.arrayUnion(yeniSaglikNotlari);
    }
    if (esEkle.isNotEmpty) guncelleme['eslesenIdler'] = FieldValue.arrayUnion(esEkle);

    final batch = _db.batch();
    batch.update(ref, guncelleme);
    for (final eid in esEkle) {
      batch.update(_ogrenciRef(sinifId, eid), {'eslesenIdler': FieldValue.arrayUnion([ogrenciId])});
    }
    for (final eid in esKaldir) {
      batch.update(_ogrenciRef(sinifId, eid), {'eslesenIdler': FieldValue.arrayRemove([ogrenciId])});
    }
    await batch.commit();
    // Aynı alana bir batch içinde hem union hem remove yazılamaz; kaldırma
    // ayrı, çok nadir (aynı kayıtta hem ekleme hem çıkarma).
    if (esKaldir.isNotEmpty) {
      await ref.update({'eslesenIdler': FieldValue.arrayRemove(esKaldir)});
    }
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

  /// [partnerIdler]: silinen öğrenciyle eşli olanlar; onların listesinden
  /// id aynı batch'te çıkarılır ki çöp "?" çipi kalmasın (denetim #3).
  Future<void> ogrenciSil(String sinifId, String ogrenciId,
      {List<String> partnerIdler = const []}) async {
    final batch = _db.batch();
    batch.delete(_ogrenciRef(sinifId, ogrenciId));
    for (final pid in partnerIdler) {
      batch.update(_ogrenciRef(sinifId, pid), {'eslesenIdler': FieldValue.arrayRemove([ogrenciId])});
    }
    await batch.commit();
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
