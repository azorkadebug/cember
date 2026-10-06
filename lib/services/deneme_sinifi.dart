import '../models/ogrenci.dart';

/// Yeni öğretmen Sınıflarım'ı bomboş görmesin diye kurulan "Deneme Sınıfı"
/// (Sabri, 2026-10-06). Adlar uydurma; her özelliğin bir örneği var:
/// element (ateş/su), eşli ikili, sarı kart, kıyafet eksiği, rozet, not.
class DenemeSinifi {
  static const ad = 'Deneme Sınıfı';

  /// [idler] en az 12 benzersiz belge kimliği (eşleştirme için önceden
  /// üretilir).
  static List<Ogrenci> ogrenciler(List<String> idler) {
    assert(idler.length >= 12);
    Ogrenci o(int i, String ad, bool erkek, int puan,
            {String? element, List<String>? es, Map<String, int>? kalem, String not = '', List<Map<String, dynamic>>? rozet}) =>
        Ogrenci(
          id: idler[i],
          ad: ad,
          isMale: erkek,
          puan: puan,
          element: element,
          eslesenIdler: es,
          kalemSayaclari: kalem,
          not: not,
          rozetler: rozet,
        );
    return [
      o(0, 'Elif Yıldırım', false, 112, element: 'su'),
      o(1, 'Zeynep Aksoy', false, 100,
          not: 'Bu bir örnek not. Notlar yalnız sende görünür; listede öğrencinin satırına basılı tutarak hızlı not ekleyebilirsin.'),
      o(2, 'Defne Kaya', false, 95, element: 'su'),
      o(3, 'Ecrin Demir', false, 105, rozet: [{'rozet': 'lider', 'tarih': '01.10.2026'}]),
      o(4, 'Ada Şahin', false, 98, es: [idler[5]]),
      o(5, 'Nehir Polat', false, 103, es: [idler[4]]),
      o(6, 'Kerem Arslan', true, 120, element: 'ates', kalem: {'sari_kart': 1}),
      o(7, 'Emir Koç', true, 108, element: 'ates'),
      o(8, 'Yusuf Öztürk', true, 97, kalem: {'kiyafet': 1}),
      o(9, 'Mert Erdoğan', true, 115),
      o(10, 'Arda Kurt', true, 101),
      o(11, 'Baran Aydın', true, 92),
    ];
  }

  /// Dünkü yoklama: Arda gelmemiş, Yusuf'un forması eksik.
  static Map<String, dynamic> dunkuYoklama(List<String> idler) => {
        for (var i = 0; i < 12; i++)
          idler[i]: {
            'geldi': i != 10,
            if (i == 8) 'kalemler': {'kiyafet': false},
          },
      };

  /// Sınıf ekranında gösterilen açıklama.
  static const aciklama =
      'Bu bir deneme sınıfı: öğrenciler uydurma. Yoklama al, öğrenciye dokun, takım kur, kura çek; '
      'istediğin gibi kurcala. İşin bitince Sınıflarım\'da kartın ⋯ menüsünden silebilirsin.';
}
