import 'dart:async';

/// Bir yazmanın sonucunu "ilk hangisi gelirse" mantığıyla bildirir.
///
/// Yazma [sure] içinde sunucudan onaylanırsa: yalnız [onay] (gec: false).
/// Onaylanmazsa (çevrimdışı) [sure] dolunca BİR kez [bekliyor] çağrılır;
/// sonradan onay gelirse [onay] yine çağrılır ama gec: true ile (arayüz
/// ikinci bir "kaydedildi" göstermemeli), ret gelirse [hata] çağrılır.
/// Neden: çevrimdışıyken Firestore yazma Future'ı bağlantı gelene kadar
/// tamamlanmaz; kart kapanıp hiç geri bildirim kalmıyordu.
class KayitOnayi<T> {
  KayitOnayi({
    required Future<T> yazim,
    required bool Function() aktif,
    required void Function(T sonuc, bool gec) onay,
    required void Function() bekliyor,
    required void Function(Object hata) hata,
    Duration sure = const Duration(seconds: 2),
  }) : _aktif = aktif {
    _zamanlayici = Timer(sure, () {
      _bekledi = true;
      if (_aktif()) bekliyor();
    });
    yazim.then<void>((v) {
      _zamanlayici?.cancel();
      if (_aktif()) onay(v, _bekledi);
    }, onError: (Object e) {
      _zamanlayici?.cancel();
      hata(e);
    });
  }

  final bool Function() _aktif;
  Timer? _zamanlayici;
  bool _bekledi = false;

  /// Ekran kapanırken: bekleme iletisi artık gösterilmesin.
  void iptal() => _zamanlayici?.cancel();
}
