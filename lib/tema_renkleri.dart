import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tema.dart';

/// Açık ve koyu temada değişen arayüz renkleri.
///
/// Uygulama 2026-10'a kadar açık temaya sabitti ve renkler ekranlarda elle
/// yazılıydı (`Colors.white`, `Colors.grey.shade100`, `AppTema.anaKoyu`…).
/// Koyu tema (Sabri'nin seçimi: "Koyu B — Charcoal", tasarım tuvali
/// `design/koyu-tema-tuvali/`) için yüzey ve metin renkleri buradan okunur:
/// `context.renk.kart`, `context.renk.metin`.
///
/// Değişmeyenler burada YOK, `AppTema`'da kalır: forma renkleri, element ve
/// cinsiyet renkleri, skor ekranının koyu paneli (`panelKoyu1/2` — skor
/// ekranı iki temada da aynı lacivert dünya), renkli zemin üstündeki beyaz
/// yazı.
@immutable
class CemberRenkleri extends ThemeExtension<CemberRenkleri> {
  const CemberRenkleri({
    required this.sayfa,
    required this.kart,
    required this.kartUstu,
    required this.yuzeyGri,
    required this.yuzeyAna,
    required this.cizgi,
    required this.cizgiAcik,
    required this.metin,
    required this.metinGovde,
    required this.metinIkincil,
    required this.metinUcuncul,
    required this.ikonAna,
    required this.ikonPasif,
    required this.bosDurumIkonu,
    required this.bar,
    required this.barKoyu,
    required this.barAcik,
    required this.barMetin,
    required this.vurgu,
    required this.vurguMetin,
    required this.vurguKoyu,
    required this.vurguZemin,
    required this.basari,
    required this.basariZemin,
    required this.uyari,
    required this.uyariZemin,
    required this.tehlike,
    required this.tehlikeZemin,
    required this.geldiZemin,
    required this.geldiCizgi,
    required this.geldiSerit,
    required this.yokZemin,
    required this.yokCizgi,
    required this.yokMetin,
    required this.yokSerit,
    required this.silDolgu,
    required this.golge,
  });

  /// Liste ekranlarının zemini (eski `Colors.grey.shade100`).
  final Color sayfa;

  /// Kart, liste satırı, alt çubuk (eski `Colors.white`).
  final Color kart;

  /// Diyalog ve alt sayfa; koyuda karttan bir ton açık ki üstte durduğu belli olsun.
  final Color kartUstu;

  /// Kart İÇİNDEKİ gri kutu: sayaç, açılır kutu, arama alanı (eski grey100).
  final Color yuzeyGri;

  /// `ana50` tonlu kutu: ikon karosu, kalem çipi, iskelet.
  final Color yuzeyAna;

  /// Çerçeve, ayırıcı, sürükleme tutamağı (eski grey300).
  final Color cizgi;

  /// İnce ayırıcı (eski grey200).
  final Color cizgiAcik;

  /// Başlık ve ana metin (eski `AppTema.anaKoyu`, `Colors.black87`).
  final Color metin;

  /// Diyalog gövdesi, uzun metin (eski `AppTema.ana` metin olarak, grey700).
  final Color metinGovde;
  final Color metinIkincil;
  final Color metinUcuncul;

  /// `AppTema.ana` renkli ikonlar.
  final Color ikonAna;

  /// Ok, pasif ikon (eski grey400).
  final Color ikonPasif;

  /// Boş durum ekranlarındaki büyük soluk ikon (eski grey300).
  final Color bosDurumIkonu;

  /// AppBar zemini ve başlık gradyanı.
  final Color bar;
  final Color barKoyu;
  final Color barAcik;
  final Color barMetin;

  /// Turkuaz ana eylem. Koyuda açılır; üstündeki yazı [vurguMetin].
  final Color vurgu;
  final Color vurguMetin;

  /// Zemin üstünde turkuaz METİN.
  final Color vurguKoyu;
  final Color vurguZemin;
  final Color basari;
  final Color basariZemin;
  final Color uyari;
  final Color uyariZemin;
  final Color tehlike;
  final Color tehlikeZemin;
  final Color geldiZemin;
  final Color geldiCizgi;
  final Color geldiSerit;
  final Color yokZemin;
  final Color yokCizgi;
  final Color yokMetin;
  final Color yokSerit;

  /// Dolgulu silme düğmesi ("Evet, Sil"), üstünde beyaz yazı.
  final Color silDolgu;
  final Color golge;

  bool get koyuMu => sayfa.computeLuminance() < 0.2;

  /// Bugünkü görünüm — değerler ekranlardaki eski elle yazılmış renklerin aynısı.
  static const acik = CemberRenkleri(
    sayfa: Color(0xFFF5F5F5),
    kart: Colors.white,
    kartUstu: Colors.white,
    yuzeyGri: Color(0xFFF5F5F5),
    yuzeyAna: Color(0xFFECEFF1),
    cizgi: Color(0xFFE0E0E0),
    cizgiAcik: Color(0xFFEEEEEE),
    metin: AppTema.anaKoyu,
    metinGovde: AppTema.ana,
    metinIkincil: AppTema.metinIkincil,
    metinUcuncul: AppTema.metinUcuncul,
    ikonAna: AppTema.ana,
    ikonPasif: Color(0xFFBDBDBD),
    bosDurumIkonu: Color(0xFFE0E0E0),
    bar: AppTema.ana,
    barKoyu: AppTema.anaKoyu,
    barAcik: AppTema.anaAcik,
    barMetin: Colors.white,
    vurgu: AppTema.vurgu,
    vurguMetin: Colors.white,
    vurguKoyu: AppTema.vurguKoyu,
    vurguZemin: AppTema.vurguZemin,
    basari: AppTema.basari,
    basariZemin: AppTema.basariZemin,
    uyari: AppTema.uyari,
    uyariZemin: AppTema.uyariZemin,
    tehlike: AppTema.tehlike,
    tehlikeZemin: AppTema.tehlikeZemin,
    geldiZemin: Color(0xFFE8F5E9),
    geldiCizgi: Color(0xFFA5D6A7),
    geldiSerit: Color(0xFF4CAF50),
    yokZemin: Color(0xFFFFEBEE),
    yokCizgi: Color(0xFFEF9A9A),
    yokMetin: Color(0xFFD32F2F),
    yokSerit: Color(0xFFE57373),
    silDolgu: Color(0xFFE53935),
    golge: Color(0x14000000),
  );

  /// Koyu B — Charcoal. Metin renkleri kendi zeminlerinde en az 4,5:1.
  static const koyu = CemberRenkleri(
    sayfa: Color(0xFF111517),
    kart: Color(0xFF1C2327),
    kartUstu: Color(0xFF232C31),
    yuzeyGri: Color(0xFF263238),
    yuzeyAna: Color(0xFF2A3439),
    cizgi: Color(0xFF3A474E),
    cizgiAcik: Color(0xFF2A3439),
    metin: Color(0xFFECEFF1),
    metinGovde: Color(0xFFCFD8DC),
    metinIkincil: Color(0xFFA7B4BB),
    metinUcuncul: Color(0xFF8D9AA1),
    ikonAna: Color(0xFFA7B4BB),
    ikonPasif: Color(0xFF718088),
    bosDurumIkonu: Color(0xFF3A474E),
    bar: Color(0xFF1C2327),
    barKoyu: Color(0xFF161C1F),
    barAcik: Color(0xFF263238),
    barMetin: Color(0xFFECEFF1),
    vurgu: Color(0xFF4DB6AC),
    vurguMetin: Color(0xFF062925),
    vurguKoyu: Color(0xFF80CBC4),
    vurguZemin: Color(0xFF12332F),
    basari: Color(0xFF81C784),
    basariZemin: Color(0xFF1B3322),
    uyari: Color(0xFFFFB74D),
    uyariZemin: Color(0xFF3A2A12),
    tehlike: Color(0xFFFF8A80),
    tehlikeZemin: Color(0xFF3A1D1D),
    geldiZemin: Color(0xFF1B3322),
    geldiCizgi: Color(0xFF2F5D3A),
    geldiSerit: Color(0xFF66BB6A),
    yokZemin: Color(0xFF3A1D1D),
    yokCizgi: Color(0xFF6E3434),
    yokMetin: Color(0xFFFF8A80),
    yokSerit: Color(0xFFE57373),
    silDolgu: Color(0xFFD32F2F),
    golge: Color(0x66000000),
  );

  @override
  CemberRenkleri copyWith() => this;

  @override
  CemberRenkleri lerp(CemberRenkleri? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return CemberRenkleri(
      sayfa: l(sayfa, other.sayfa),
      kart: l(kart, other.kart),
      kartUstu: l(kartUstu, other.kartUstu),
      yuzeyGri: l(yuzeyGri, other.yuzeyGri),
      yuzeyAna: l(yuzeyAna, other.yuzeyAna),
      cizgi: l(cizgi, other.cizgi),
      cizgiAcik: l(cizgiAcik, other.cizgiAcik),
      metin: l(metin, other.metin),
      metinGovde: l(metinGovde, other.metinGovde),
      metinIkincil: l(metinIkincil, other.metinIkincil),
      metinUcuncul: l(metinUcuncul, other.metinUcuncul),
      ikonAna: l(ikonAna, other.ikonAna),
      ikonPasif: l(ikonPasif, other.ikonPasif),
      bosDurumIkonu: l(bosDurumIkonu, other.bosDurumIkonu),
      bar: l(bar, other.bar),
      barKoyu: l(barKoyu, other.barKoyu),
      barAcik: l(barAcik, other.barAcik),
      barMetin: l(barMetin, other.barMetin),
      vurgu: l(vurgu, other.vurgu),
      vurguMetin: l(vurguMetin, other.vurguMetin),
      vurguKoyu: l(vurguKoyu, other.vurguKoyu),
      vurguZemin: l(vurguZemin, other.vurguZemin),
      basari: l(basari, other.basari),
      basariZemin: l(basariZemin, other.basariZemin),
      uyari: l(uyari, other.uyari),
      uyariZemin: l(uyariZemin, other.uyariZemin),
      tehlike: l(tehlike, other.tehlike),
      tehlikeZemin: l(tehlikeZemin, other.tehlikeZemin),
      geldiZemin: l(geldiZemin, other.geldiZemin),
      geldiCizgi: l(geldiCizgi, other.geldiCizgi),
      geldiSerit: l(geldiSerit, other.geldiSerit),
      yokZemin: l(yokZemin, other.yokZemin),
      yokCizgi: l(yokCizgi, other.yokCizgi),
      yokMetin: l(yokMetin, other.yokMetin),
      yokSerit: l(yokSerit, other.yokSerit),
      silDolgu: l(silDolgu, other.silDolgu),
      golge: l(golge, other.golge),
    );
  }
}

extension CemberRenkErisimi on BuildContext {
  /// Geçerli temanın renkleri. Tema kurulmamışsa (testte çıplak widget) açık.
  CemberRenkleri get renk =>
      Theme.of(this).extension<CemberRenkleri>() ?? CemberRenkleri.acik;
}

/// Uygulamanın [ThemeData]'sı. Açık tema bugünküyle birebir aynı.
ThemeData cemberTemasi(Brightness parlaklik) {
  final r = parlaklik == Brightness.dark
      ? CemberRenkleri.koyu
      : CemberRenkleri.acik;
  final temel = ColorScheme.fromSeed(
    seedColor: AppTema.vurgu,
    brightness: parlaklik,
  );
  final renkSemasi = parlaklik == Brightness.dark
      ? temel.copyWith(
          primary: r.vurgu,
          onPrimary: r.vurguMetin,
          surface: r.kart,
          onSurface: r.metin,
          onSurfaceVariant: r.metinIkincil,
          outline: r.cizgi,
          surfaceContainerHigh: r.kartUstu,
          surfaceContainerHighest: r.yuzeyGri,
          error: r.tehlike,
        )
      : temel.copyWith(primary: AppTema.vurgu);
  return ThemeData(
    brightness: parlaklik,
    colorScheme: renkSemasi,
    useMaterial3: true,
    scaffoldBackgroundColor: parlaklik == Brightness.dark ? r.sayfa : null,
    textTheme: parlaklik == Brightness.dark
        ? AppTema.textTheme
              .apply(bodyColor: r.metin, displayColor: r.metin)
              .copyWith(
                bodySmall: AppTema.textTheme.bodySmall!.copyWith(
                  color: r.metinIkincil,
                ),
                labelSmall: AppTema.textTheme.labelSmall!.copyWith(
                  color: r.metinUcuncul,
                ),
              )
        : AppTema.textTheme,
    extensions: [r],
    // Başlıklar tek ölçekten: AppBar 20/w800, diyalog 20/w800 (denetim
    // O12 — diyalog başlıkları 4 farklı ağırlıkta, 18 farklı fontSize).
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: r.barMetin,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: parlaklik == Brightness.dark ? r.kartUstu : null,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: r.metin,
      ),
      contentTextStyle: TextStyle(
        fontSize: 15,
        color: r.metinGovde,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: parlaklik == Brightness.dark
        ? BottomSheetThemeData(
            backgroundColor: r.kartUstu,
            modalBackgroundColor: r.kartUstu,
          )
        : null,
    // Web/masaüstünde varsayılan "compact" yoğunluk düğmeleri 4-8 px
    // kısaltıyordu; diyalog düğmeleri 32 px'te kalıyordu (denetim O11).
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: const Size(64, 44)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(minimumSize: const Size(64, 44)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 44)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: parlaklik == Brightness.dark ? r.kart : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}

/// Görünüm tercihi: Sistem (varsayılan, telefonun ayarına uyar) / Açık / Koyu.
/// Cihazda saklanır; hesaba bağlı değil (aynı öğretmen telefonda koyu,
/// okul bilgisayarında açık isteyebilir).
class TemaTercihi {
  TemaTercihi._();
  static const _anahtar = 'tema_tercihi';
  static final ValueNotifier<ThemeMode> mod = ValueNotifier(ThemeMode.system);

  static Future<void> yukle() async {
    try {
      final p = await SharedPreferences.getInstance();
      mod.value = switch (p.getString(_anahtar)) {
        'acik' => ThemeMode.light,
        'koyu' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Okunamazsa sistem ayarı.
    }
  }

  static Future<void> ayarla(ThemeMode yeni) async {
    mod.value = yeni;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_anahtar, switch (yeni) {
        ThemeMode.light => 'acik',
        ThemeMode.dark => 'koyu',
        ThemeMode.system => 'sistem',
      });
    } catch (_) {}
  }
}
