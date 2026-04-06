import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ogrenci.dart';
import '../screens/skor_ekrani.dart';

class MacDurumu extends ChangeNotifier {
  static final MacDurumu _instance = MacDurumu._();
  factory MacDurumu() => _instance;
  MacDurumu._();

  List<TakimBilgi>? _takimlar;
  String? _sinifId;
  bool _duraklatildi = false;

  // Timer & skor durumu
  int kalanSaniye = 0;
  int toplamSaniye = 0;
  bool timerCalisiyor = false;
  bool timerBitti = false;
  /// Timer'ın duraklatıldığı (ekrandan çıkıldığı) zaman
  DateTime? _timerCikisZamani;

  List<TakimBilgi>? get takimlar => _takimlar;
  String? get sinifId => _sinifId;
  bool get aktif => _takimlar != null;
  bool get duraklatildi => _duraklatildi;

  void macBaslat(String sinifId, List<TakimBilgi> takimlar) {
    _sinifId = sinifId;
    _takimlar = takimlar;
    _duraklatildi = false;
    kalanSaniye = 0;
    toplamSaniye = 0;
    timerCalisiyor = false;
    timerBitti = false;
    _timerCikisZamani = null;
    kaydet();
    notifyListeners();
  }

  void duraklat() {
    _duraklatildi = true;
    notifyListeners();
  }

  void devamEt() {
    _duraklatildi = false;
    notifyListeners();
  }

  /// Skor ekranından çıkarken durumu kaydet
  void durumKaydet({
    required int kalanSn,
    required int toplamSn,
    required bool calisiyor,
    required bool bitti,
  }) {
    kalanSaniye = kalanSn;
    toplamSaniye = toplamSn;
    timerBitti = bitti;
    // Timer çalışıyorsa çıkış zamanını kaydet, geri dönünce farkı hesaplayalım
    if (calisiyor && !bitti) {
      timerCalisiyor = true;
      _timerCikisZamani = DateTime.now();
    } else {
      timerCalisiyor = false;
      _timerCikisZamani = null;
    }
    kaydet();
  }

  /// Skor ekranına dönerken geçen süreyi hesapla
  int kalanSaniyeHesapla() {
    if (_timerCikisZamani != null && timerCalisiyor) {
      final gecenSaniye = DateTime.now().difference(_timerCikisZamani!).inSeconds;
      final yeniKalan = kalanSaniye - gecenSaniye;
      kalanSaniye = yeniKalan > 0 ? yeniKalan : 0;
      if (kalanSaniye <= 0) {
        timerCalisiyor = false;
        timerBitti = true;
      }
      _timerCikisZamani = null;
    }
    return kalanSaniye;
  }

  void macBitir() {
    _takimlar = null;
    _sinifId = null;
    _duraklatildi = false;
    kalanSaniye = 0;
    toplamSaniye = 0;
    timerCalisiyor = false;
    timerBitti = false;
    _timerCikisZamani = null;
    _temizle();
    notifyListeners();
  }

  // --- LocalStorage ---

  Future<void> kaydet() async {
    if (_takimlar == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'sinifId': _sinifId,
      'toplamSaniye': toplamSaniye,
      'kalanSaniye': kalanSaniye,
      'timerCalisiyor': timerCalisiyor,
      'timerBitti': timerBitti,
      'cikisZamani': _timerCikisZamani?.millisecondsSinceEpoch,
      'takimlar': _takimlar!.map((t) => {
        'isim': t.isim,
        'renkAdi': t.renkAdi,
        'renk': t.renk.toARGB32(),
        'skor': t.skor,
        'kaptanId': t.kaptan?.id,
        'oyuncular': t.oyuncular.map((o) => {
          'id': o.id,
          'ad': o.ad,
          'puan': o.puan,
          'isMale': o.isMale,
          'buradaMi': o.buradaMi,
          'not': o.not,
          if (o.element != null) 'element': o.element,
        }).toList(),
      }).toList(),
    };
    await prefs.setString('aktif_mac', jsonEncode(data));
  }

  Future<void> _temizle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('aktif_mac');
  }

  /// Uygulama açılışında localStorage'dan maç durumunu yükle
  Future<bool> yukle() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('aktif_mac');
    if (json == null) return false;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      _sinifId = data['sinifId'];
      toplamSaniye = data['toplamSaniye'] ?? 0;
      kalanSaniye = data['kalanSaniye'] ?? 0;
      timerCalisiyor = data['timerCalisiyor'] ?? false;
      timerBitti = data['timerBitti'] ?? false;
      if (data['cikisZamani'] != null) {
        _timerCikisZamani = DateTime.fromMillisecondsSinceEpoch(data['cikisZamani']);
      }

      final takimlarData = data['takimlar'] as List;
      _takimlar = takimlarData.map((t) {
        final oyuncularData = t['oyuncular'] as List;
        final oyuncular = oyuncularData.map((o) => Ogrenci(
          id: o['id'],
          ad: o['ad'],
          puan: o['puan'] ?? 100,
          isMale: o['isMale'] ?? true,
          buradaMi: o['buradaMi'] ?? true,
          not: o['not'] ?? '',
          element: o['element'],
        )).toList();

        final kaptanId = t['kaptanId'];
        Ogrenci? kaptan;
        if (kaptanId != null) {
          kaptan = oyuncular.where((o) => o.id == kaptanId).firstOrNull;
        }

        return TakimBilgi(
          isim: t['isim'],
          renkAdi: t['renkAdi'],
          renk: Color(t['renk']),
          oyuncular: oyuncular,
          kaptan: kaptan,
          skor: t['skor'] ?? 0,
        );
      }).toList();

      // Geçen süreyi hesapla
      kalanSaniyeHesapla();

      notifyListeners();
      return true;
    } catch (_) {
      await _temizle();
      return false;
    }
  }
}
