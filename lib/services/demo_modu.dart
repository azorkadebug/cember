class DemoModu {
  static bool aktif = false;

  static const _kizIsimleri = [
    'Elif Yıldız', 'Zeynep Kaya', 'Defne Arslan', 'Ecrin Demir', 'Azra Çelik',
    'Mira Şahin', 'Asya Öztürk', 'Lina Aydın', 'Nisa Koç', 'Selin Erdoğan',
    'Duru Polat', 'Ada Özkan', 'Nehir Aksoy', 'Ela Kurt', 'Ceren Yılmaz',
    'İpek Doğan', 'Beren Kılıç', 'Nazlı Çetin', 'Ece Güneş', 'Melis Aktaş',
  ];

  static const _erkekIsimleri = [
    'Yusuf Akar', 'Kerem Tunç', 'Burak Yıldırım', 'Emir Karaca', 'Arda Korkmaz',
    'Mert Özdemir', 'Baran Şen', 'Kuzey Turan', 'Deniz Bulut', 'Alp Güler',
    'Çınar Başar', 'Atlas Erdem', 'Rüzgar Çoban', 'Toprak Sezer', 'Doruk Ünal',
    'Poyraz Avcı', 'Ayaz Kaplan', 'Ege Sönmez', 'Can Tekin', 'Onur Yalçın',
  ];

  static int _kizSayac = 0;
  static int _erkekSayac = 0;
  static final Map<String, String> _esleme = {};

  static void sifirla() {
    _kizSayac = 0;
    _erkekSayac = 0;
    _esleme.clear();
  }

  static String isimGetir(String gercekIsim, bool isMale) {
    if (!aktif) return gercekIsim;
    if (_esleme.containsKey(gercekIsim)) return _esleme[gercekIsim]!;

    String sahteIsim;
    if (isMale) {
      sahteIsim = _erkekIsimleri[_erkekSayac % _erkekIsimleri.length];
      _erkekSayac++;
    } else {
      sahteIsim = _kizIsimleri[_kizSayac % _kizIsimleri.length];
      _kizSayac++;
    }
    _esleme[gercekIsim] = sahteIsim;
    return sahteIsim;
  }
}
