import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding, WidgetsBindingObserver, AppLifecycleState;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ogrenci.dart';
import '../screens/skor_ekrani.dart';
import 'alarm_servisi.dart';
import 'firestore_service.dart';

/// Skor ekranındaki 2 dakikalık molanın kaydı: hangi takımdan hangi oyuncu,
/// ne zaman bitiyor. Skor ekranından çıkınca molalar siliniyordu (denetim
/// #5 D7); artık süre gibi burada tutuluyor.
class MacMolasi {
  final int takimIndex;
  final String oyuncuId;
  final DateTime bitis;
  const MacMolasi({required this.takimIndex, required this.oyuncuId, required this.bitis});
}

/// Yarım kalan maçın cihazda saklanması.
///
/// GÜVENLİK NOTU: Buraya öğrenci ADI veya NOTU yazılmaz — yalnızca öğrenci
/// id'si ve maça özgü alanlar (puan, takım, skor, süre). İsimler yüklerken
/// Firestore'dan tazelenir.
///
/// Nedeni: SharedPreferences web'de `localStorage`'dır ve aynı origin'de
/// çalışan her JS onu düz metin okuyabilir; Android'de ise cihaz yedeğine
/// çıkar. Ayrıca kayıt kullanıcı bazlı anahtarda tutulur ve çıkışta
/// silinir — yoksa okulda paylaşılan bir tablette sonraki öğretmen
/// öncekinin öğrencilerini görür.
///
/// SÜRE: Tek doğruluk kaynağı burası (denetim #5 Y2/Y3/O3). Çalışan süre
/// bitiş anı (duvar saati) olarak tutulur, kalan = bitiş − şimdi. Eskiden
/// skor ekranı kendi sayacını tutuyor, buraya yalnız ekrandan çıkarken
/// "kalan + çıkış anı" yazıyordu: sayfa yenilenince süre son girişe geri
/// sarılıyor, bant ⏸ yalnız bayrak değiştiriyor, ekran dışında biten süre
/// alarm çalmıyordu. Her değişim (başlat, durdur, sıfırla, süre seçimi,
/// duraklat) anında diske yazılır; her saniye yazılmaz.
class MacDurumu extends ChangeNotifier with WidgetsBindingObserver {
  static final MacDurumu _instance = MacDurumu._();
  factory MacDurumu() => _instance;
  MacDurumu._();

  static const String _anahtarOnEki = 'aktif_mac';

  /// v1.1.1 öncesi kullanılan, kullanıcıya göre ayrılmamış ve öğrenci
  /// adlarını düz metin tutan anahtar.
  static const String _eskiAnahtar = 'aktif_mac';

  static String? _aktifUid;

  static String? get _anahtar =>
      _aktifUid == null ? null : '${_anahtarOnEki}_$_aktifUid';

  /// Saat. Testte sahte saat verilir; süre hesabı DateTime.now'ı doğrudan
  /// çağırmaz.
  static DateTime Function() saat = DateTime.now;

  /// Süre bitince bir kez çağrılır (düdük + titreşim). Skor ekranı açık
  /// olmasa da çalar; testte sayaçla değiştirilir.
  @visibleForTesting
  static void Function() alarmCal = _varsayilanAlarm;

  /// Mola bitince "dı dı dın" (düdükten ayrı; Sabri seçti, 2026-11-15).
  /// Skor ekranı da bunu çağırır; testte sayaçla değiştirilir.
  static void Function() molaSesiCal = _varsayilanMolaSesi;

  /// Skor ekranı açıkken molayı o yönetir (sayaç, "Mola bitti" penceresi).
  /// Kapalıyken biten molayı burası düşürür ve [molaBittiDuyuru] ile haber
  /// verir; eskiden ekran dışında biten mola sessizce kayboluyordu.
  static int skorEkraniSayisi = 0;
  static bool get skorEkraniAcik => skorEkraniSayisi > 0;

  /// Skor ekranı dışında biten mola için uygulama içi duyuru (takım rengi,
  /// oyuncunun görünen adı). main.dart genel bildirim şeridine bağlar.
  static void Function(String renkAdi, Ogrenci oyuncu)? molaBittiDuyuru;

  /// Geri yüklemede öğrenci adlarının çözüldüğü kaynak (Firestore).
  @visibleForTesting
  static Future<List<Ogrenci>> Function(String uid, String sinifId) ogrenciKaynagi =
      (uid, sinifId) => FirestoreService(uid: uid).ogrencileriGetir(sinifId);

  List<TakimBilgi>? _takimlar;
  String? _sinifId;
  /// Sınıflar Arası Yarışma'da deplasman sınıfı. Eskiden kaydedilmiyordu,
  /// geri yüklemede deplasman kadrosu boş geliyordu (denetim #5 O2).
  List<String> _ekSinifIdler = const [];
  bool _duraklatildi = false;
  /// Bant ⏸ çalışan bir süreyi durdurduysa ▶ onu yeniden başlatır; süre
  /// zaten duruyorsa ▶ kendiliğinden başlatmaz.
  bool _bantDurdurdu = false;

  int _toplamSaniye = 0;
  /// Süre dururken kalan saniye.
  int _durKalan = 0;
  /// Süre çalışırken bitiş anı; duruyorsa null.
  DateTime? _bitis;
  bool _timerBitti = false;
  final List<MacMolasi> _molalar = [];

  Timer? _bitisZamanlayici;
  final Map<MacMolasi, Timer> _molaZamanlayicilari = {};
  bool _gozlemciEklendi = false;

  List<TakimBilgi>? get takimlar => _takimlar;
  String? get sinifId => _sinifId;
  List<String> get ekSinifIdler => List.unmodifiable(_ekSinifIdler);
  bool get aktif => _takimlar != null;
  bool get duraklatildi => _duraklatildi;

  int get toplamSaniye => _toplamSaniye;
  bool get timerCalisiyor => _bitis != null;
  bool get timerBitti => _timerBitti;
  int get kalanSaniye {
    final b = _bitis;
    if (b == null) return _durKalan;
    final ms = b.difference(saat()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  List<MacMolasi> get molalar => List.unmodifiable(_molalar);

  void macBaslat(String sinifId, List<TakimBilgi> takimlar, {List<String> ekSinifIdler = const []}) {
    _bellegiSifirla();
    _sinifId = sinifId;
    _ekSinifIdler = List.of(ekSinifIdler);
    _takimlar = takimlar;
    kaydet();
    notifyListeners();
  }

  // --- Süre ---

  /// Hazır süre seçildi: süre durur, seçilen değere kurulur.
  void sureAyarla(int saniye) {
    _zamanlayiciIptal();
    _toplamSaniye = saniye;
    _durKalan = saniye;
    _bitis = null;
    _timerBitti = false;
    _bantDurdurdu = false;
    _degisti();
  }

  void baslat() {
    if (_timerBitti || _bitis != null) return;
    // Süre seçilmeden BAŞLAT'a basınca varsayılan 1 dakika (eskiden düğme
    // basılıyor ama hiçbir şey olmuyordu).
    if (_durKalan <= 0) {
      _toplamSaniye = 60;
      _durKalan = 60;
    }
    _bitis = saat().add(Duration(seconds: _durKalan));
    _duraklatildi = false;
    _bantDurdurdu = false;
    _zamanlayiciKur();
    _degisti();
  }

  void durdur() {
    if (_bitis == null || kontrolEt()) return;
    _durKalan = kalanSaniye;
    _bitis = null;
    _zamanlayiciIptal();
    _degisti();
  }

  void baslaDurdur() => timerCalisiyor ? durdur() : baslat();

  /// Seçili süreye geri döner, süre durur.
  void sifirla() {
    _zamanlayiciIptal();
    _durKalan = _toplamSaniye;
    _bitis = null;
    _timerBitti = false;
    _bantDurdurdu = false;
    _degisti();
  }

  /// Sınıflarım bandındaki ⏸: eskiden yalnız bayraktı, süre akmaya devam
  /// ediyordu (denetim #5 Y2). Artık süreyi gerçekten durdurur.
  void duraklat() {
    kontrolEt();
    _duraklatildi = true;
    if (_bitis != null) {
      _durKalan = kalanSaniye;
      _bitis = null;
      _bantDurdurdu = true;
      _zamanlayiciIptal();
    }
    _degisti();
  }

  void devamEt() {
    _duraklatildi = false;
    if (_bantDurdurdu && !_timerBitti && _durKalan > 0) {
      baslat();
      return;
    }
    _bantDurdurdu = false;
    _degisti();
  }

  /// Süre dolduysa bitmiş duruma geçer, alarmı BİR KEZ çalar. Bitiş
  /// zamanlayıcısı, skor ekranının saniye sayacı ve uygulamanın öne gelişi
  /// bunu çağırır; hangisi önce görürse o bitirir. Bittiyse true.
  bool kontrolEt({bool alarm = true}) {
    final b = _bitis;
    if (b == null || saat().isBefore(b)) return false;
    _zamanlayiciIptal();
    _bitis = null;
    _durKalan = 0;
    _timerBitti = true;
    _bantDurdurdu = false;
    if (alarm && uygulamaIciSesGerekir(b)) alarmCal();
    _degisti();
    return true;
  }

  void _zamanlayiciKur() {
    _bitisZamanlayici?.cancel();
    final b = _bitis;
    if (b == null) return;
    final kalan = b.difference(saat());
    _bitisZamanlayici = Timer(kalan.isNegative ? Duration.zero : kalan, () {
      // Timer duvar saatinden biraz erken uyanabilir; bitmediyse yeniden kur.
      if (!kontrolEt() && _bitis != null) _zamanlayiciKur();
    });
    // iOS arka planda Timer'ı donduruyor; öne gelince hemen kontrol et ki
    // arka planda biten süre dönüşte bir kez alarm çalsın (denetim #4 Y4).
    if (!_gozlemciEklendi) {
      WidgetsBinding.instance.addObserver(this);
      _gozlemciEklendi = true;
    }
  }

  void _zamanlayiciIptal() {
    _bitisZamanlayici?.cancel();
    _bitisZamanlayici = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) kontrolEt();
  }

  void _degisti() {
    kaydet();
    notifyListeners();
  }

  /// Telefon bildirimi zaten çaldıysa uygulama içi ses ikinci kez
  /// çalmasın. Bildirim uygulama öndeyken görünmez → uygulama çalar; yalnız
  /// bitişten epey sonra (arka plandan dönüş) fark edildiyse çalmaz, o an
  /// bildirim zaten duyurmuştu.
  static bool uygulamaIciSesGerekir(DateTime bitis) {
    switch (AlarmServisi.yol) {
      case AlarmYolu.bildirim:
        return saat().difference(bitis) < const Duration(seconds: 3);
      case AlarmYolu.yok:
        return true;
    }
  }

  // --- Mola ---

  MacMolasi molaEkle(int takimIndex, String oyuncuId) {
    final m = MacMolasi(
      takimIndex: takimIndex,
      oyuncuId: oyuncuId,
      bitis: saat().add(const Duration(seconds: 120)),
    );
    _molalar.add(m);
    _molaZamanlayicisiKur(m);
    kaydet();
    return m;
  }

  void molaKaldir(MacMolasi m) {
    _molaZamanlayicilari.remove(m)?.cancel();
    if (_molalar.remove(m)) kaydet();
  }

  void _molaZamanlayicisiKur(MacMolasi m) {
    _molaZamanlayicilari.remove(m)?.cancel();
    final kalan = m.bitis.difference(saat());
    _molaZamanlayicilari[m] = Timer(kalan.isNegative ? Duration.zero : kalan, () => _molaBitti(m));
  }

  /// Mola süresi doldu. Skor ekranı açıksa o kendi sayacıyla bitirir (aynı
  /// saniyede; burada bir şey yapılmaz). Kapalıysa mola düşer, düdük
  /// (gerekirse) çalar, uygulama içi duyuru gösterilir.
  void _molaBitti(MacMolasi m) {
    _molaZamanlayicilari.remove(m);
    if (!_molalar.contains(m)) return;
    if (saat().isBefore(m.bitis)) {
      _molaZamanlayicisiKur(m); // Timer erken uyandı
      return;
    }
    if (skorEkraniAcik) return;
    molaKaldir(m);
    final takimlar = _takimlar;
    if (takimlar == null || m.takimIndex >= takimlar.length) return;
    final takim = takimlar[m.takimIndex];
    final oyuncu = takim.oyuncular.where((o) => o.id == m.oyuncuId).firstOrNull;
    if (oyuncu == null) return;
    if (uygulamaIciSesGerekir(m.bitis)) molaSesiCal();
    molaBittiDuyuru?.call(takim.renkAdi, oyuncu);
  }

  /// Telefonun çalacağı alarmlar: çalışan süre ve süren molalar. Bildirim
  /// kilit ekranında görünür; öğrenci adı yazılmaz (bkz. AlarmServisi).
  List<PlanliAlarm> planliAlarmlar() {
    final takimlar = _takimlar;
    if (takimlar == null) return const [];
    return [
      if (_bitis != null)
        PlanliAlarm(
            id: 'sure', zaman: _bitis!, baslik: 'Süre bitti', govde: 'Maç süresi doldu.', ses: 'sure_bitti.wav'),
      for (final m in _molalar)
        PlanliAlarm(
          id: 'mola_${m.oyuncuId}',
          zaman: m.bitis,
          baslik: 'Mola bitti',
          ses: 'mola_bitti.wav',
          govde: m.takimIndex < takimlar.length && takimlar[m.takimIndex].renkAdi.isNotEmpty
              ? '${takimlar[m.takimIndex].renkAdi} takımındaki oyuncu oyuna dönebilir.'
              : 'Moladaki oyuncu oyuna dönebilir.',
        ),
    ];
  }

  void _alarmlariEsitle() => unawaited(AlarmServisi.esitle(planliAlarmlar()));

  /// Düdük skor ekranı açık olmasa da sessiz modda çalsın (playback) ama
  /// Bluetooth'tan çalan müziği kesmesin: duckOthers müziği kısar, düdük
  /// bitince geri getirir (denetim #4 Y5). Web'de desteklenmez, sessizce
  /// geçilir.
  static Future<void> sesBaglaminiKur() => AudioPlayer.global
      .setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.duckOthers},
        ),
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.gainTransientMayDuck),
      ))
      .catchError((_) {});

  static AudioPlayer? _alarmCalar;

  static void _varsayilanAlarm() {
    unawaited(() async {
      await sesBaglaminiKur();
      final p = _alarmCalar ??= AudioPlayer();
      await p.play(AssetSource('sounds/sure_bitti.wav')).catchError((_) {});
    }());
    unawaited(() async {
      for (var i = 0; i < 3; i++) {
        unawaited(HapticFeedback.heavyImpact());
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }());
  }

  static void _varsayilanMolaSesi() {
    unawaited(() async {
      await sesBaglaminiKur();
      final p = _alarmCalar ??= AudioPlayer();
      await p.play(AssetSource('sounds/mola_bitti.wav')).catchError((_) {});
    }());
    unawaited(HapticFeedback.heavyImpact());
  }

  void macBitir() {
    _bellegiSifirla();
    _alarmlariEsitle();
    _temizle();
    notifyListeners();
  }

  void _bellegiSifirla() {
    _zamanlayiciIptal();
    for (final t in _molaZamanlayicilari.values) {
      t.cancel();
    }
    _molaZamanlayicilari.clear();
    _takimlar = null;
    _sinifId = null;
    _ekSinifIdler = const [];
    _duraklatildi = false;
    _bantDurdurdu = false;
    _toplamSaniye = 0;
    _durKalan = 0;
    _bitis = null;
    _timerBitti = false;
    _molalar.clear();
  }

  // --- Yerel depolama ---

  /// Giriş yapan kullanıcıyı bildirir. `yukle()` bunu kendisi yapar;
  /// ayrıca çağırmak gerekmez.
  static void kullaniciAyarla(String uid) => _aktifUid = uid;

  Future<void> kaydet() async {
    // Her kayıt bir durum değişimidir: telefon alarmlarını da eşitle
    // (duraklat, sıfırla, mola iptali, maç bitişi dahil).
    _alarmlariEsitle();
    final anahtar = _anahtar;
    if (_takimlar == null || anahtar == null) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'uid': _aktifUid,
      'sinifId': _sinifId,
      if (_ekSinifIdler.isNotEmpty) 'ekSinifIdler': _ekSinifIdler,
      'toplamSaniye': _toplamSaniye,
      'kalanSaniye': kalanSaniye,
      'timerCalisiyor': timerCalisiyor,
      'timerBitti': _timerBitti,
      // Çalışırken bitiş anı; kalan her okumada bundan hesaplanır.
      'bitis': _bitis?.millisecondsSinceEpoch,
      'duraklatildi': _duraklatildi,
      'bantDurdurdu': _bantDurdurdu,
      if (_molalar.isNotEmpty)
        'molalar': _molalar
            .map((m) => {
                  'takim': m.takimIndex,
                  'id': m.oyuncuId,
                  'bitis': m.bitis.millisecondsSinceEpoch,
                })
            .toList(),
      'takimlar': _takimlar!
          .map((t) => {
                'isim': t.isim,
                'renkAdi': t.renkAdi,
                'renk': t.renk.toARGB32(),
                'skor': t.skor,
                'kaptanId': t.kaptan?.id,
                // Öğrenci adı ve notu BİLEREK yazılmıyor — yüklerken
                // Firestore'dan tazeleniyor.
                'oyuncular': t.oyuncular
                    .map((o) => {
                          'id': o.id,
                          'puan': o.puan,
                          'isMale': o.isMale,
                          'buradaMi': o.buradaMi,
                          if (o.element != null) 'element': o.element,
                          if (o.eslesenIdler.isNotEmpty) 'eslesenIdler': o.eslesenIdler,
                        })
                    .toList(),
              })
          .toList(),
    };
    await prefs.setString(anahtar, jsonEncode(data));
  }

  Future<void> _temizle() async {
    final prefs = await SharedPreferences.getInstance();
    final anahtar = _anahtar;
    if (anahtar != null) await prefs.remove(anahtar);
  }

  /// Çıkışta çağrılır: bellek + diskteki TÜM maç kayıtlarını siler.
  /// Eski sürümden kalan, kullanıcıya göre ayrılmamış kaydı da temizler.
  static Future<void> tamTemizlik([String? uid]) async {
    _instance._bellegiSifirla();
    _instance._alarmlariEsitle();
    try {
      final prefs = await SharedPreferences.getInstance();
      final silinecek = prefs
          .getKeys()
          .where((k) => k == _eskiAnahtar || k.startsWith('${_anahtarOnEki}_'))
          .toList();
      for (final k in silinecek) {
        await prefs.remove(k);
      }
    } catch (_) {
      // Depolama erişilemezse çıkışın kendisi engellenmemeli.
    }
    _aktifUid = null;
    _instance.notifyListeners();
  }

  /// Giriş sonrası yarım kalan maçı geri yükler.
  ///
  /// Öğrenci adları yerelde tutulmadığı için Firestore'dan tazelenir;
  /// silinmiş öğrenciler maç kadrosundan düşer.
  Future<bool> yukle(String uid) async {
    _aktifUid = uid;
    final prefs = await SharedPreferences.getInstance();

    var json = prefs.getString(_anahtar!);

    // v1.1.1 öncesi kayıt: içinde düz metin öğrenci adları var.
    // Maçı kaybettirmemek için id'lerinden geri kuruyoruz, ardından
    // eski anahtarı siliyoruz.
    if (json == null) {
      final eski = prefs.getString(_eskiAnahtar);
      if (eski != null) {
        json = eski;
        await prefs.remove(_eskiAnahtar);
      }
    }
    if (json == null) return false;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;

      // Başka bir hesaba ait kayıt: yükleme, sil.
      final kayitUid = data['uid'];
      if (kayitUid != null && kayitUid != uid) {
        await prefs.remove(_anahtar!);
        return false;
      }

      final sinifId = data['sinifId'] as String?;
      if (sinifId == null) {
        await _temizle();
        return false;
      }
      final ekSinifIdler =
          (data['ekSinifIdler'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

      // Adları Firestore'dan getir. Yarışmada deplasman sınıfınınkiler de
      // (denetim #5 O2); o sınıf okunamazsa maçı kaybetmektense o kadro
      // boş gelsin.
      final ogrenciler = [
        ...await ogrenciKaynagi(uid, sinifId),
        for (final ek in ekSinifIdler)
          ...await ogrenciKaynagi(uid, ek).catchError((_) => <Ogrenci>[]),
      ];
      final adaGore = {for (final o in ogrenciler) o.id: o};

      _zamanlayiciIptal();
      _sinifId = sinifId;
      _ekSinifIdler = ekSinifIdler;
      _sureyiCoz(data);
      _duraklatildi = data['duraklatildi'] == true;
      _bantDurdurdu = data['bantDurdurdu'] == true;

      final takimlarData = (data['takimlar'] as List).cast<Map<String, dynamic>>();
      _takimlar = takimlarData.map((t) {
        final oyuncularData =
            (t['oyuncular'] as List).cast<Map<String, dynamic>>();
        final oyuncular = oyuncularData
            .map((o) {
              final kayit = adaGore[o['id']];
              if (kayit == null) return null; // öğrenci silinmiş
              return Ogrenci(
                id: kayit.id,
                // Ad ve not yerelde tutulmuyor — Firestore'dan tazelendi.
                ad: kayit.ad,
                not: kayit.not,
                puan: (o['puan'] as num?)?.toInt() ?? kayit.puan,
                isMale: o['isMale'] as bool? ?? kayit.isMale,
                buradaMi: o['buradaMi'] as bool? ?? true,
                element: o['element'] as String? ?? kayit.element,
                eslesenIdler: (o['eslesenIdler'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    kayit.eslesenIdler,
              );
            })
            .whereType<Ogrenci>()
            .toList();

        final kaptanId = t['kaptanId'] as String?;
        Ogrenci? kaptan;
        if (kaptanId != null) {
          kaptan = oyuncular.where((o) => o.id == kaptanId).firstOrNull;
        }

        return TakimBilgi(
          isim: t['isim'] as String? ?? '',
          renkAdi: t['renkAdi'] as String? ?? '',
          renk: Color((t['renk'] as num?)?.toInt() ?? 0xFF9E9E9E),
          oyuncular: oyuncular,
          kaptan: kaptan,
          skor: (t['skor'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      _molalar
        ..clear()
        ..addAll(((data['molalar'] as List?) ?? const []).map((m) {
          final mm = m as Map<String, dynamic>;
          return MacMolasi(
            takimIndex: (mm['takim'] as num).toInt(),
            oyuncuId: mm['id'] as String,
            bitis: DateTime.fromMillisecondsSinceEpoch((mm['bitis'] as num).toInt()),
          );
        }).where((m) => m.bitis.isAfter(saat())));
      for (final t in _molaZamanlayicilari.values) {
        t.cancel();
      }
      _molaZamanlayicilari.clear();
      _molalar.forEach(_molaZamanlayicisiKur);

      // Kadro tamamen boşaldıysa (sınıf silinmiş vb.) maçı kapat.
      if (_takimlar!.every((t) => t.oyuncular.isEmpty)) {
        macBitir();
        return false;
      }

      // Uygulama kapalıyken süre dolduysa "süre bitti" durumunda açılır;
      // alarm çalınmaz (saatler sonra açılmış olabilir). Dolmadıysa bitiş
      // zamanlayıcısı yeniden kurulur.
      if (!kontrolEt(alarm: false) && _bitis != null) _zamanlayiciKur();

      // Yeni biçimde ve doğru anahtarla tekrar yaz (eski kayıttan geldiyse).
      await kaydet();
      notifyListeners();
      return true;
    } catch (_) {
      _bellegiSifirla();
      await _temizle();
      return false;
    }
  }

  /// Kayıttaki süre alanlarını okur. Yeni biçim bitiş anını (`bitis`)
  /// tutar; 2.0.1 ve öncesi "kalan saniye + ekrandan çıkış anı"
  /// (`cikisZamani`) tutuyordu — bitiş = çıkış + kalan diye çevrilir.
  /// Çalışıyor deyip ikisi de yoksa (eski sürümde skor değişince yazılan
  /// bayat kayıt) süre durmuş kabul edilir.
  void _sureyiCoz(Map<String, dynamic> data) {
    _toplamSaniye = (data['toplamSaniye'] as num?)?.toInt() ?? 0;
    final kalan = (data['kalanSaniye'] as num?)?.toInt() ?? 0;
    _timerBitti = data['timerBitti'] == true;
    _durKalan = kalan < 0 ? 0 : kalan;
    _bitis = null;
    if (data['timerCalisiyor'] == true && !_timerBitti) {
      final bitisMs = (data['bitis'] as num?)?.toInt();
      final cikisMs = (data['cikisZamani'] as num?)?.toInt();
      if (bitisMs != null) {
        _bitis = DateTime.fromMillisecondsSinceEpoch(bitisMs);
      } else if (cikisMs != null) {
        _bitis = DateTime.fromMillisecondsSinceEpoch(cikisMs).add(Duration(seconds: _durKalan));
      }
    }
  }
}
