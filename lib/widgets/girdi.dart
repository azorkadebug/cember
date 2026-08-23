import 'package:flutter/widgets.dart';

/// Metin girişi üst sınırları.
///
/// Firestore doküman limiti 1 MiB. Sınırsız serbest metin ve sınırsız
/// büyüyen listeler, dokümanı bir noktadan sonra kalıcı olarak
/// güncellenemez hâle getirir; ayrıca çok uzun isimler listelerde ve skor
/// tablosunda düzeni bozar.
class GirdiSiniri {
  const GirdiSiniri._();

  static const int ogrenciAdi = 60;
  static const int ogrenciNotu = 500;
  static const int saglikNotu = 1000;
  static const int sinifAdi = 40;
  static const int kalemAdi = 40;
  static const int renkAdi = 24;
  static const int profilAlani = 80;
  static const int puanBasamak = 4;
  static const int onayKelimesi = 10;

  /// Toplu eklemede tek seferde kabul edilen en fazla satır.
  static const int topluEklemeMaxSatir = 200;
}

/// `maxLength` sayacını gizler — sınır uygulanır ama ekranda "0/60" görünmez.
Widget? gizliSayac(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  required int? maxLength,
}) =>
    null;
