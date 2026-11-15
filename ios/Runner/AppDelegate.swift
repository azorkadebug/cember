import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CemberAlarm") {
      CemberAlarm.kaydet(registrar.messenger())
    }
  }
}

/// Mola ve maç süresi bitişini telefona bildirim olarak kurar
/// (lib/services/alarm_servisi.dart).
///
/// Tek komut `esitle`: Dart istenen bildirimlerin TAM listesini yollar
/// ([{id, zaman(ms), baslik, govde, ses}]). Listede olmayan bekleyen bildirim
/// iptal, eksik olan kurulur. Dönüş: "bildirim" | "yok".
///
/// Zamana duyarlı bildirim: Odak'ı deler; telefon sessizdeyse yalnız titreşim.
/// Ses dosyası Flutter varlıklarından Library/Sounds'a kopyalanır (iOS özel
/// bildirim sesini yalnız uygulama paketinden ya da oradan çalar).
///
/// AlarmKit (iOS 26) bilerek yok: sessiz modu deliyor ama alarm ekranı açıp
/// kapatılana kadar çalıyor; Sabri "alarm gibi değil, tok bir bildirim sesi"
/// istedi (2026-11-15).
enum CemberAlarm {
  static let bildirimOnEki = "cember.alarm."

  static func kaydet(_ messenger: FlutterBinaryMessenger) {
    let kanal = FlutterMethodChannel(name: "cember/alarm", binaryMessenger: messenger)
    kanal.setMethodCallHandler { call, result in
      guard call.method == "esitle" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let ham = ((call.arguments as? [String: Any])?["alarmlar"] as? [[String: Any]]) ?? []
      let istenen = ham.compactMap(Istenen.init)
      Task { @MainActor in
        let tamam = await bildirimleEsitle(istenen)
        result(tamam ? "bildirim" : "yok")
      }
    }
  }

  struct Istenen {
    let id: String
    let zaman: Date
    let baslik: String
    let govde: String
    let ses: String?
    let ms: Int64

    init?(_ m: [String: Any]) {
      guard let id = m["id"] as? String,
            let ms = (m["zaman"] as? NSNumber)?.int64Value,
            let baslik = m["baslik"] as? String,
            let govde = m["govde"] as? String else { return nil }
      self.id = id
      self.ms = ms
      self.zaman = Date(timeIntervalSince1970: Double(ms) / 1000)
      self.baslik = baslik
      self.govde = govde
      self.ses = m["ses"] as? String
    }

    /// Kimlik + zaman: zaman değişince (duraklat/devam) yeni kimlik çıkar,
    /// eskisi listede olmadığı için iptal edilir. Uygulama yeniden açılınca
    /// aynı kimlikler üretildiği için ayrıca kayıt tutmak gerekmez.
    var bildirimKimligi: String { "\(bildirimOnEki)\(id).\(ms)" }
  }

  /// assets/sounds/<ad> → Library/Sounds/<ad> (yoksa ya da boyu farklıysa).
  static func sesiHazirla(_ ad: String) -> UNNotificationSound {
    let fm = FileManager.default
    guard let lib = fm.urls(for: .libraryDirectory, in: .userDomainMask).first else { return .default }
    let klasor = lib.appendingPathComponent("Sounds", isDirectory: true)
    let hedef = klasor.appendingPathComponent(ad)
    let anahtar = FlutterDartProject.lookupKey(forAsset: "assets/sounds/\(ad)")
    guard let kaynak = Bundle.main.path(forResource: anahtar, ofType: nil) else {
      NSLog("CemberAlarm ses bulunamadı: \(anahtar)")
      return .default
    }
    do {
      try fm.createDirectory(at: klasor, withIntermediateDirectories: true)
      let kaynakBoy = (try? fm.attributesOfItem(atPath: kaynak))?[.size] as? NSNumber
      let hedefBoy = (try? fm.attributesOfItem(atPath: hedef.path))?[.size] as? NSNumber
      if kaynakBoy != hedefBoy {
        try? fm.removeItem(at: hedef)
        try fm.copyItem(atPath: kaynak, toPath: hedef.path)
      }
      return UNNotificationSound(named: UNNotificationSoundName(ad))
    } catch {
      NSLog("CemberAlarm ses: \(error)")
      return .default
    }
  }

  @MainActor
  static func bildirimleEsitle(_ istenen: [Istenen]) async -> Bool {
    let merkez = UNUserNotificationCenter.current()
    let bekleyen = await merkez.pendingNotificationRequests()
      .map(\.identifier)
      .filter { $0.hasPrefix(bildirimOnEki) }
    let hedef = Dictionary(istenen.map { ($0.bildirimKimligi, $0) }, uniquingKeysWith: { a, _ in a })
    let silinecek = bekleyen.filter { hedef[$0] == nil }
    if !silinecek.isEmpty { merkez.removePendingNotificationRequests(withIdentifiers: silinecek) }
    if istenen.isEmpty { return true }

    var ayar = await merkez.notificationSettings()
    if ayar.authorizationStatus == .notDetermined {
      // İzin yalnız gerçekten kurulacak bir bildirim varken sorulur (ilk mola).
      _ = try? await merkez.requestAuthorization(options: [.alert, .sound])
      ayar = await merkez.notificationSettings()
    }
    guard ayar.authorizationStatus == .authorized || ayar.authorizationStatus == .provisional else {
      return false
    }

    let bekleyenKume = Set(bekleyen)
    for (kimlik, a) in hedef where !bekleyenKume.contains(kimlik) {
      let saniye = a.zaman.timeIntervalSinceNow
      guard saniye > 0.5 else { continue }
      let icerik = UNMutableNotificationContent()
      icerik.title = a.baslik
      icerik.body = a.govde
      icerik.sound = a.ses.map(sesiHazirla) ?? .default
      icerik.interruptionLevel = .timeSensitive
      let tetik = UNTimeIntervalNotificationTrigger(timeInterval: saniye, repeats: false)
      do {
        try await merkez.add(UNNotificationRequest(identifier: kimlik, content: icerik, trigger: tetik))
      } catch {
        NSLog("CemberAlarm bildirim: \(error)")
        return false
      }
    }
    return true
  }
}
