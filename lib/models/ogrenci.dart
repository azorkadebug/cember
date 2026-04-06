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
  String? element;

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
  });

  Map<String, dynamic> toMap() {
    final s = SifrelemeService.instance;
    return {
      'ad': s.sifrele(ad),
      'puan': puan,
      'ayakkabiEksik': ayakkabiEksik,
      'kiyafetEksik': kiyafetEksik,
      'sariKart': sariKart,
      'saglikDurumu': saglikDurumu,
      'not': s.sifrele(not),
      'isMale': isMale,
      'buradaMi': buradaMi,
      'sifrelendi': true,
      if (element != null) 'element': element,
    };
  }

  factory Ogrenci.fromMap(String id, Map<String, dynamic> map) {
    final s = SifrelemeService.instance;
    final sifrelendi = map['sifrelendi'] == true;
    return Ogrenci(
      id: id,
      ad: sifrelendi ? s.coz(map['ad'] ?? '') : (map['ad'] ?? ''),
      puan: map['puan'] ?? 100,
      buradaMi: map['buradaMi'] ?? true,
      ayakkabiEksik: map['ayakkabiEksik'] ?? 0,
      kiyafetEksik: map['kiyafetEksik'] ?? 0,
      sariKart: map['sariKart'] ?? 0,
      saglikDurumu: map['saglikDurumu'] ?? 0,
      not: sifrelendi ? s.coz(map['not'] ?? '') : (map['not'] ?? ''),
      isMale: map['isMale'] ?? true,
      element: map['element'],
    );
  }
}

class TopluOgrenciSatiri {
  final TextEditingController adCtrl = TextEditingController();
  final TextEditingController puanCtrl = TextEditingController(text: "100");
  bool isMale = true;

  void dispose() {
    adCtrl.dispose();
    puanCtrl.dispose();
  }
}
