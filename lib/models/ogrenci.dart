import 'package:flutter/material.dart';

class Ogrenci {
  String id, ad, not;
  int puan, ayakkabiEksik, kiyafetEksik, sariKart, saglikDurumu;
  bool buradaMi, isMale;

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
  });

  Map<String, dynamic> toMap() => {
        'ad': ad,
        'puan': puan,
        'ayakkabiEksik': ayakkabiEksik,
        'kiyafetEksik': kiyafetEksik,
        'sariKart': sariKart,
        'saglikDurumu': saglikDurumu,
        'not': not,
        'isMale': isMale,
        'buradaMi': buradaMi,
      };

  factory Ogrenci.fromMap(String id, Map<String, dynamic> map) => Ogrenci(
        id: id,
        ad: map['ad'] ?? '',
        puan: map['puan'] ?? 100,
        buradaMi: map['buradaMi'] ?? true,
        ayakkabiEksik: map['ayakkabiEksik'] ?? 0,
        kiyafetEksik: map['kiyafetEksik'] ?? 0,
        sariKart: map['sariKart'] ?? 0,
        saglikDurumu: map['saglikDurumu'] ?? 0,
        not: map['not'] ?? "",
        isMale: map['isMale'] ?? true,
      );
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
