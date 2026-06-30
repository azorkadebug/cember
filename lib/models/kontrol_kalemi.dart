import 'package:flutter/material.dart';

/// Bir kontrol/yoklama kaleminin türü.
/// - [gunluk]: her ders "getirdi mi?" → ✓/✗ (kitap, boya, forma...)
/// - [sayac]: sezon boyu birikir (sarı kart, olumsuz davranış...)
enum KalemTipi { gunluk, sayac }

/// Öğretmenin sınıf için tanımladığı kontrol/yoklama kalemi.
class KontrolKalemi {
  final String id;
  final String ad;
  final String ikon; // ikon anahtarı — bkz. [kalemIkonu]
  final KalemTipi tip;
  final int sira;

  const KontrolKalemi({
    required this.id,
    required this.ad,
    this.ikon = 'check',
    this.tip = KalemTipi.gunluk,
    this.sira = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'ad': ad,
        'ikon': ikon,
        'tip': tip.name,
        'sira': sira,
      };

  factory KontrolKalemi.fromMap(Map<String, dynamic> m) => KontrolKalemi(
        id: (m['id'] ?? '').toString(),
        ad: (m['ad'] ?? '').toString(),
        ikon: (m['ikon'] ?? 'check').toString(),
        tip: m['tip'] == 'sayac' ? KalemTipi.sayac : KalemTipi.gunluk,
        sira: (m['sira'] as num?)?.toInt() ?? 0,
      );

  KontrolKalemi copyWith({String? ad, String? ikon, KalemTipi? tip, int? sira}) =>
      KontrolKalemi(
        id: id,
        ad: ad ?? this.ad,
        ikon: ikon ?? this.ikon,
        tip: tip ?? this.tip,
        sira: sira ?? this.sira,
      );
}

/// Kalem ikon anahtarını Material ikonuna çevirir.
IconData kalemIkonu(String anahtar) {
  switch (anahtar) {
    case 'shirt':
      return Icons.checkroom_rounded;
    case 'shoe':
      return Icons.directions_run_rounded;
    case 'card':
      return Icons.style_rounded;
    case 'brush':
      return Icons.brush_rounded;
    case 'palette':
      return Icons.palette_rounded;
    case 'book':
      return Icons.menu_book_rounded;
    case 'notebook':
      return Icons.book_rounded;
    case 'music':
      return Icons.music_note_rounded;
    case 'homework':
      return Icons.assignment_rounded;
    case 'pencil':
      return Icons.edit_rounded;
    case 'ruler':
      return Icons.straighten_rounded;
    default:
      return Icons.check_circle_outline_rounded;
  }
}

/// Bir öğretmen branşı + o branşın varsayılan kalemleri.
class Brans {
  final String id;
  final String ad;
  final IconData ikon;
  final List<KontrolKalemi> varsayilanKalemler;

  const Brans({
    required this.id,
    required this.ad,
    required this.ikon,
    required this.varsayilanKalemler,
  });
}

/// Hazır branş şablonları. Sınıf oluşturulurken kalemler buradan tohumlanır,
/// sonra sınıf bazında düzenlenebilir.
const List<Brans> bransSablonlari = [
  Brans(
    id: 'beden_egitimi',
    ad: 'Beden Eğitimi',
    ikon: Icons.sports_soccer_rounded,
    varsayilanKalemler: [
      KontrolKalemi(id: 'kiyafet', ad: 'Kıyafet', ikon: 'shirt', sira: 0),
      KontrolKalemi(id: 'ayakkabi', ad: 'Ayakkabı', ikon: 'shoe', sira: 1),
      KontrolKalemi(id: 'sari_kart', ad: 'Sarı Kart', ikon: 'card', tip: KalemTipi.sayac, sira: 2),
    ],
  ),
  Brans(
    id: 'resim',
    ad: 'Resim',
    ikon: Icons.palette_rounded,
    varsayilanKalemler: [
      KontrolKalemi(id: 'boya', ad: 'Boya', ikon: 'palette', sira: 0),
      KontrolKalemi(id: 'firca', ad: 'Fırça', ikon: 'brush', sira: 1),
      KontrolKalemi(id: 'resim_defteri', ad: 'Resim Defteri', ikon: 'notebook', sira: 2),
    ],
  ),
  Brans(
    id: 'turkce',
    ad: 'Türkçe',
    ikon: Icons.menu_book_rounded,
    varsayilanKalemler: [
      KontrolKalemi(id: 'kitap', ad: 'Kitap', ikon: 'book', sira: 0),
      KontrolKalemi(id: 'defter', ad: 'Defter', ikon: 'notebook', sira: 1),
    ],
  ),
  Brans(
    id: 'muzik',
    ad: 'Müzik',
    ikon: Icons.music_note_rounded,
    varsayilanKalemler: [
      KontrolKalemi(id: 'enstruman', ad: 'Enstrüman/Flüt', ikon: 'music', sira: 0),
    ],
  ),
  Brans(
    id: 'matematik',
    ad: 'Matematik',
    ikon: Icons.calculate_rounded,
    varsayilanKalemler: [
      KontrolKalemi(id: 'defter', ad: 'Defter', ikon: 'notebook', sira: 0),
      KontrolKalemi(id: 'odev', ad: 'Ödev', ikon: 'homework', sira: 1),
    ],
  ),
  Brans(
    id: 'ozel',
    ad: 'Özel (boş)',
    ikon: Icons.tune_rounded,
    varsayilanKalemler: [],
  ),
];

/// Branş id'sinden şablonu döndürür; bulunamazsa Beden Eğitimi'ne düşer
/// (mevcut veri göçü: branşı olmayan eski sınıflar Beden Eğitimi sayılır).
Brans bransSablonu(String? id) => bransSablonlari.firstWhere(
      (b) => b.id == id,
      orElse: () => bransSablonlari.first,
    );
