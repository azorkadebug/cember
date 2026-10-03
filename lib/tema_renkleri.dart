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
    required this.kenar,
    required this.sertGolge,
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

  /// "Teneffüs" çıkartma kenarı: kart, düğme, çip, diyalog çerçevesi.
  /// Koyuda zemine karşı en az 3:1.
  final Color kenar;

  /// Bulanıklıksız, kaydırılmış "çıkartma" gölgesi (`Offset(4, 4)`).
  final Color sertGolge;

  bool get koyuMu => sayfa.computeLuminance() < 0.2;

  /// Bugünkü görünüm — değerler ekranlardaki eski elle yazılmış renklerin aynısı.
  /// "Teneffüs" açık: krem sayfa, beyaz kart, mürekkep yazı ve kenar.
  static const acik = CemberRenkleri(
    sayfa: Color(0xFFFFF6EA),
    kart: Colors.white,
    kartUstu: Colors.white,
    yuzeyGri: Color(0xFFF7EEDF),
    yuzeyAna: AppTema.ana50,
    cizgi: Color(0xFFE6DACA),
    cizgiAcik: Color(0xFFF0E7D9),
    metin: AppTema.ana,
    metinGovde: AppTema.anaAcik,
    metinIkincil: AppTema.metinIkincil,
    metinUcuncul: AppTema.metinUcuncul,
    ikonAna: AppTema.ana,
    ikonPasif: Color(0xFF7E828E),
    bosDurumIkonu: Color(0xFFE6DACA),
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
    geldiZemin: Color(0xFFE3F6E7),
    geldiCizgi: Color(0xFF63C77A),
    geldiSerit: Color(0xFF2E9E4F),
    yokZemin: Color(0xFFFFE9E5),
    yokCizgi: Color(0xFFFF8A7A),
    yokMetin: Color(0xFFC62828),
    yokSerit: Color(0xFFE5483A),
    silDolgu: Color(0xFFC62828),
    golge: Color(0x1A1F2430),
    kenar: AppTema.ana,
    sertGolge: AppTema.ana,
  );

  /// "Teneffüs" koyu: mürekkep gecesi. Metin renkleri kendi zeminlerinde en
  /// az 4,5:1; kenar karta karşı 3:1.
  static const koyu = CemberRenkleri(
    sayfa: Color(0xFF171A21),
    kart: Color(0xFF222632),
    kartUstu: Color(0xFF2A2F3D),
    yuzeyGri: Color(0xFF2E3443),
    yuzeyAna: Color(0xFF323849),
    cizgi: Color(0xFF444B5E),
    cizgiAcik: Color(0xFF303646),
    metin: Color(0xFFF4F1EA),
    metinGovde: Color(0xFFDAD6CE),
    metinIkincil: Color(0xFFB4B8C4),
    metinUcuncul: Color(0xFF9DA2AF),
    ikonAna: Color(0xFFB4B8C4),
    ikonPasif: Color(0xFF7D8392),
    bosDurumIkonu: Color(0xFF444B5E),
    bar: Color(0xFF222632),
    barKoyu: Color(0xFF1A1D26),
    barAcik: Color(0xFF2E3443),
    barMetin: Color(0xFFF4F1EA),
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
    kenar: Color(0xFF6B7389),
    sertGolge: Color(0xFF0B0C10),
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
      kenar: l(kenar, other.kenar),
      sertGolge: l(sertGolge, other.sertGolge),
    );
  }
}

extension CemberRenkErisimi on BuildContext {
  /// Geçerli temanın renkleri. Tema kurulmamışsa (testte çıplak widget) açık.
  CemberRenkleri get renk =>
      Theme.of(this).extension<CemberRenkleri>() ?? CemberRenkleri.acik;
}

/// Uygulamanın [ThemeData]'sı: "Teneffüs" görünümü (2026-10-04). Düğme,
/// kart, çip, diyalog ve girdiler mürekkep kenarlı "çıkartma"; başlıklar
/// Fredoka, gövde Nunito.
ThemeData cemberTemasi(Brightness parlaklik) {
  final koyu = parlaklik == Brightness.dark;
  final r = koyu ? CemberRenkleri.koyu : CemberRenkleri.acik;
  final temel = ColorScheme.fromSeed(seedColor: AppTema.vurgu, brightness: parlaklik);
  // Seed'den gelen yeşilimsi yüzeyler diyalog ve kartlara sızıyordu
  // (denetim #3); yüzeyler iki temada da bizim tablomuzdan.
  final renkSemasi = temel.copyWith(
    primary: r.vurgu,
    onPrimary: r.vurguMetin,
    secondary: r.vurgu,
    onSecondary: r.vurguMetin,
    secondaryContainer: r.vurguZemin,
    onSecondaryContainer: r.metin,
    surface: r.kart,
    onSurface: r.metin,
    onSurfaceVariant: r.metinIkincil,
    outline: r.kenar,
    outlineVariant: r.cizgi,
    surfaceContainerLowest: r.kart,
    surfaceContainerLow: r.kart,
    surfaceContainer: r.kart,
    surfaceContainerHigh: r.kartUstu,
    surfaceContainerHighest: r.yuzeyGri,
    surfaceTint: Colors.transparent,
    error: r.tehlike,
  );
  final kenar = BorderSide(color: r.kenar, width: 2);
  const hap = StadiumBorder();
  final dugmeYazisi = const TextStyle(
      fontFamily: AppTema.baslikFontu, fontSize: 17, fontWeight: FontWeight.w600);
  final metinTemasi = AppTema.textTheme.apply(bodyColor: r.metin, displayColor: r.metin).copyWith(
    bodySmall: AppTema.textTheme.bodySmall!.copyWith(color: r.metinIkincil),
    labelSmall: AppTema.textTheme.labelSmall!.copyWith(color: r.metinUcuncul),
  );
  return ThemeData(
    brightness: parlaklik,
    colorScheme: renkSemasi,
    useMaterial3: true,
    fontFamily: AppTema.govdeFontu,
    scaffoldBackgroundColor: r.sayfa,
    canvasColor: r.sayfa,
    textTheme: metinTemasi,
    extensions: [r],
    // Üst çubuklar krem; renkli başlık isteyen ekran (öğrenci listesi)
    // kendi rengini ve yazı rengini açıkça verir.
    appBarTheme: AppBarTheme(
      backgroundColor: r.sayfa,
      foregroundColor: r.metin,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: AppTema.baslikFontu,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: r.metin,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: r.kartUstu,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        side: kenar,
      ),
      titleTextStyle: TextStyle(
        fontFamily: AppTema.baslikFontu,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: r.metin,
      ),
      contentTextStyle: TextStyle(
        fontFamily: AppTema.govdeFontu,
        fontSize: 15,
        color: r.metinGovde,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: r.kartUstu,
      modalBackgroundColor: r.kartUstu,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: r.cizgi,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: kenar,
      ),
    ),
    // Web/masaüstünde varsayılan "compact" yoğunluk düğmeleri 4-8 px
    // kısaltıyordu; diyalog düğmeleri 32 px'te kalıyordu (denetim O11).
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(64, 44),
        shape: hap,
        foregroundColor: r.vurguKoyu,
        textStyle: dugmeYazisi.copyWith(fontSize: 16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        backgroundColor: r.vurgu,
        foregroundColor: r.vurguMetin,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: hap.copyWith(side: kenar),
        textStyle: dugmeYazisi,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        backgroundColor: r.vurgu,
        foregroundColor: r.vurguMetin,
        shape: hap.copyWith(side: kenar),
        textStyle: dugmeYazisi,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        foregroundColor: r.metin,
        backgroundColor: r.kart,
        side: kenar,
        shape: hap,
        textStyle: dugmeYazisi,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: r.vurgu,
      foregroundColor: r.vurguMetin,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: hap.copyWith(side: kenar),
      extendedTextStyle: dugmeYazisi.copyWith(fontSize: 18),
    ),
    chipTheme: ChipThemeData(
      shape: hap.copyWith(side: kenar),
      side: kenar,
      backgroundColor: r.kart,
      labelStyle: TextStyle(fontFamily: AppTema.govdeFontu, fontWeight: FontWeight.w700, color: r.metin),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        side: kenar,
        selectedBackgroundColor: r.vurguZemin,
        selectedForegroundColor: r.metin,
        foregroundColor: r.metin,
        textStyle: const TextStyle(fontFamily: AppTema.govdeFontu, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: r.kart,
      hintStyle: TextStyle(color: r.metinUcuncul),
      border: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(16)), borderSide: kenar),
      enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(16)), borderSide: kenar),
      focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: r.vurgu, width: 2.5)),
    ),
    // Yazı rengi açıkça beyaz: koyu temada M3 varsayılanı yeşil/kırmızı zemin
    // üstünde koyu yazıydı, 2–3:1 (denetim #3).
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: koyu ? const Color(0xFF3A4152) : AppTema.ana,
      contentTextStyle: const TextStyle(
          fontFamily: AppTema.govdeFontu, fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
      actionTextColor: const Color(0xFFFFD84D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: r.kart,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        side: kenar,
      ),
    ),
    dividerTheme: DividerThemeData(color: r.cizgi, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: r.vurgu),
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
