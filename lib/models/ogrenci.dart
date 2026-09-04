import 'package:flutter/material.dart';
import '../services/demo_modu.dart';
import '../services/sifreleme_service.dart';

/// Öğrencilere atanabilecek elementler ve çatışma kuralları.
/// Aynı takıma düşmemeleri gereken çiftler: ateş↔su, toprak↔hava.
class ElementSistemi {
  static const Map<String, String> semboller = {
    'ates': '🔥',
    'su': '💧',
    'toprak': '🌱',
    'hava': '💨',
  };

  static const Map<String, String> etiketler = {
    'ates': 'Ateş',
    'su': 'Su',
    'toprak': 'Toprak',
    'hava': 'Hava',
  };

  static const Map<String, String> catismalar = {
    'ates': 'su',
    'su': 'ates',
    'toprak': 'hava',
    'hava': 'toprak',
  };

  static String? sembol(String? element) => element != null ? semboller[element] : null;
  static String? etiket(String? element) => element != null ? etiketler[element] : null;
  static bool catisir(String? a, String? b) {
    if (a == null || b == null) return false;
    return catismalar[a] == b;
  }
}

class Ogrenci {
  String id, ad, not;
  String get gorunenAd => DemoModu.isimGetir(ad, isMale);
  int puan, ayakkabiEksik, kiyafetEksik, sariKart, saglikDurumu;
  bool buradaMi, isMale;
  /// Kontrol kalemi değerleri — kalem id'sine göre (yeni branş-bağımsız sistem).
  Map<String, int> kalemSayaclari;
  String? element;
  /// Takım kurarken hep aynı takıma düşmesi istenen öğrencilerin id'leri
  /// (karşılıklı — A, B'nin listesindeyse B de A'nın listesindedir).
  /// Element sisteminden bağımsız: elementler kavgalı öğrencileri AYIRMAK
  /// için, bu ise tam tersi bir ihtiyaç için (Sabri'nin isteği, 2026-08-31).
  List<String> eslesenIdler;
  List<Map<String, dynamic>> saglikNotlari;
  List<Map<String, dynamic>> rozetler;

  static const Map<String, String> rozetTanimlari = {
    'cevre_dostu': '🌿 Çevre Dostu',
    'yardimci_antrenor': '🏅 Yardımcı Antrenör',
    'centilmen': '🤝 Centilmen',
    'lider': '👑 Lider',
    'fair_play': '🕊️ Fair Play',
    'guler_yuz': '😊 Güler Yüz',
    'takim_ruhu': '💪 Takım Ruhu',
    'strateji_ustasi': '🧠 Strateji Ustası',
  };

  Ogrenci({
    required this.id,
    required this.ad,
    this.puan = 100,
    this.buradaMi = true,
    this.ayakkabiEksik = 0,
    this.kiyafetEksik = 0,
    this.sariKart = 0,
    this.saglikDurumu = 0,
    this.not = "",
    this.isMale = true,
    this.element,
    List<String>? eslesenIdler,
    List<Map<String, dynamic>>? saglikNotlari,
    List<Map<String, dynamic>>? rozetler,
    Map<String, int>? kalemSayaclari,
  }) : eslesenIdler = eslesenIdler ?? [],
       saglikNotlari = saglikNotlari ?? [],
       rozetler = rozetler ?? [],
       kalemSayaclari = kalemSayaclari ?? {};

  /// Bir kontrol kaleminin mevcut değeri.
  int kalemDeger(String id) => kalemSayaclari[id] ?? 0;

  /// Kalem değerini değiştir; 0'ın altına düşmez (eksi sayaç engellenir),
  /// 0 olunca haritadan temizlenir.
  void kalemArti(String id, int delta) {
    final yeni = ((kalemSayaclari[id] ?? 0) + delta).clamp(0, 999);
    if (yeni == 0) {
      kalemSayaclari.remove(id);
    } else {
      kalemSayaclari[id] = yeni;
    }
  }

  /// Alan üst sınırları. Firestore doküman limiti 1 MiB; sınırsız serbest
  /// metin ve sınırsız büyüyen liste, dokümanı bir noktadan sonra
  /// güncellenemez hâle getirir.
  static const int adMaxUzunluk = 60;
  static const int notMaxUzunluk = 500;
  static const int saglikNotuMaxUzunluk = 1000;
  static const int saglikNotuMaxAdet = 50;
  static const int rozetMaxAdet = 50;

  static String _kirp(String s, int maks) =>
      s.length <= maks ? s : s.substring(0, maks);

  Map<String, dynamic> toMap() {
    return {
      // Düz metin. Eskiden AES-CBC ile şifreleniyordu, ama anahtar
      // kullanıcının UID'sinden türetiliyordu ve aynı UID sınıf
      // dokümanında `ownerId` alanında düz metin duruyor — yani şifreli
      // kaydı okuyabilen anahtarı da elde ediyordu. Koruma Firestore
      // kurallarından geliyor. Ayrıntı: sifreleme_service.dart
      'ad': _kirp(ad, adMaxUzunluk),
      'puan': puan.clamp(0, 9999),
      // Eski PE alanları geriye dönük uyumluluk için yeni haritadan senkronlanır
      // (v1.0/1.0.1 iOS istemcileri bu alanları okuyor).
      'ayakkabiEksik': kalemSayaclari['ayakkabi'] ?? ayakkabiEksik,
      'kiyafetEksik': kalemSayaclari['kiyafet'] ?? kiyafetEksik,
      'sariKart': kalemSayaclari['sari_kart'] ?? sariKart,
      'saglikDurumu': saglikDurumu,
      'kalemSayaclari': kalemSayaclari,
      'not': _kirp(not, notMaxUzunluk),
      'isMale': isMale,
      'buradaMi': buradaMi,
      // Artık şifrelenmiyor. Bayrak açıkça false yazılıyor ki eski
      // istemciler (v1.0/1.0.1) bu kaydı çözmeye çalışmasın.
      'sifrelendi': false,
      if (element != null) 'element': element,
      // element'in aksine koşulsuz yazılıyor: boş liste de gerçek bir
      // değerdir ve son eşi kaldırıldığında Firestore'daki eski değeri
      // silmesi gerekir (update() olmayan alanı değiştirmeden bırakır).
      'eslesenIdler': eslesenIdler,
      'saglikNotlari': _sonN(saglikNotlari, saglikNotuMaxAdet),
      'rozetler': _sonN(rozetler, rozetMaxAdet),
    };
  }

  /// Listenin son [n] kaydı — sınırsız birikmeyi engeller.
  static List<Map<String, dynamic>> _sonN(
          List<Map<String, dynamic>> liste, int n) =>
      liste.length <= n ? liste : liste.sublist(liste.length - n);

  factory Ogrenci.fromMap(String id, Map<String, dynamic> map) {
    // `sifrelendi: true` olan ESKİ kayıtlar çözülür; yeni kayıtlar düz metin.
    return Ogrenci(
      id: id,
      ad: SifrelemeService.alanCoz(map, 'ad'),
      puan: map['puan'] ?? 100,
      buradaMi: map['buradaMi'] ?? true,
      ayakkabiEksik: map['ayakkabiEksik'] ?? 0,
      kiyafetEksik: map['kiyafetEksik'] ?? 0,
      sariKart: map['sariKart'] ?? 0,
      saglikDurumu: map['saglikDurumu'] ?? 0,
      not: SifrelemeService.alanCoz(map, 'not'),
      isMale: map['isMale'] ?? true,
      element: map['element'],
      eslesenIdler: (map['eslesenIdler'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      saglikNotlari: (map['saglikNotlari'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      rozetler: (map['rozetler'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      kalemSayaclari: _kalemSayaclariCoz(map),
    );
  }

  /// `kalemSayaclari` yoksa (eski belge), branşı olmayan = Beden Eğitimi
  /// varsayımıyla eski PE alanlarından tohumlar.
  static Map<String, int> _kalemSayaclariCoz(Map<String, dynamic> map) {
    final raw = map['kalemSayaclari'];
    if (raw is Map) {
      final m = raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
      m.removeWhere((k, v) => v == 0);
      return m;
    }
    final m = <String, int>{};
    final kiyafet = (map['kiyafetEksik'] as num?)?.toInt() ?? 0;
    final ayakkabi = (map['ayakkabiEksik'] as num?)?.toInt() ?? 0;
    final kart = (map['sariKart'] as num?)?.toInt() ?? 0;
    if (kiyafet != 0) m['kiyafet'] = kiyafet;
    if (ayakkabi != 0) m['ayakkabi'] = ayakkabi;
    if (kart != 0) m['sari_kart'] = kart;
    return m;
  }
}

class TopluOgrenciSatiri {
  final TextEditingController adCtrl = TextEditingController();
  final TextEditingController puanCtrl = TextEditingController();
  final GlobalKey rowKey = GlobalKey();
  bool isMale = true;
  bool cinsiyetSecildi = false;

  bool _disposed = false;
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    adCtrl.dispose();
    puanCtrl.dispose();
  }
}
