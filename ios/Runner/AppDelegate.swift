import CryptoKit
import Flutter
import SwiftUI
import UIKit
import UserNotifications

#if canImport(AlarmKit)
import AlarmKit
#endif

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

/// Mola ve maç süresi bitişini telefonun kendisine çaldırır (lib/services/alarm_servisi.dart).
///
/// Tek komut `esitle`: Dart istenen alarmların TAM listesini yollar
/// ([{id, zaman(ms), baslik, govde}]). Listede olmayan eski alarm iptal,
/// eksik olan kurulur. Dönüş: "alarmkit" | "bildirim" | "yok".
///
/// iOS 26+: AlarmKit (sessiz modu ve Odak'ı deler; ilk kullanımda izin ister).
/// Daha eski iOS ya da AlarmKit izni reddedildiyse: zamana duyarlı yerel bildirim.
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
        let yol = await esitle(istenen)
        result(yol)
      }
    }
  }

  struct Istenen {
    let id: String
    let zaman: Date
    let baslik: String
    let govde: String
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
    }

    /// Kimlik + zaman → sabit UUID. Zaman değişince (duraklat/devam) farklı
    /// UUID çıkar; eski alarm listede olmadığı için iptal edilir. Uygulama
    /// yeniden açılınca da aynı UUID'ler üretildiği için kayıt tutmak gerekmez.
    var uuid: UUID {
      let ozet = SHA256.hash(data: Data("cember|\(id)|\(ms)".utf8))
      var b = Array(ozet.prefix(16))
      b[6] = (b[6] & 0x0F) | 0x50  // sürüm 5 biçimi
      b[8] = (b[8] & 0x3F) | 0x80
      return UUID(uuid: (b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                         b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]))
    }

    var bildirimKimligi: String { "\(bildirimOnEki)\(id).\(ms)" }
  }

  @MainActor
  static func esitle(_ istenen: [Istenen]) async -> String {
    #if canImport(AlarmKit)
    if #available(iOS 26.0, *) {
      if await alarmKitIleEsitle(istenen) {
        await bildirimleEsitle([])  // eski yoldan kalanları temizle
        return "alarmkit"
      }
    }
    #endif
    return await bildirimleEsitle(istenen) ? "bildirim" : "yok"
  }

  // MARK: AlarmKit (iOS 26+)

  #if canImport(AlarmKit)
  @available(iOS 26.0, *)
  struct CemberMeta: AlarmMetadata {}

  /// true: AlarmKit kullanılabildi (izin var). false: bildirim yoluna düş.
  @available(iOS 26.0, *)
  @MainActor
  static func alarmKitIleEsitle(_ istenen: [Istenen]) async -> Bool {
    let yonetici = AlarmManager.shared
    var durum = yonetici.authorizationState
    if durum == .notDetermined {
      // İzin yalnız gerçekten kurulacak bir alarm varken sorulur (ilk mola).
      if istenen.isEmpty { return false }
      durum = (try? await yonetici.requestAuthorization()) ?? .denied
    }
    guard durum == .authorized else { return false }

    let hedef = Dictionary(istenen.map { ($0.uuid, $0) }, uniquingKeysWith: { a, _ in a })
    let mevcut = (try? yonetici.alarms) ?? []
    for alarm in mevcut where hedef[alarm.id] == nil {
      // Çalmakta olan alarm (kullanıcı henüz kapatmadı) iptal edilmez.
      if alarm.state == .alerting { continue }
      try? yonetici.cancel(id: alarm.id)
    }
    let mevcutKimlikler = Set(mevcut.map(\.id))
    for (uuid, a) in hedef where !mevcutKimlikler.contains(uuid) {
      guard a.zaman > Date() else { continue }
      let uyari: AlarmPresentation.Alert
      if #available(iOS 26.1, *) {
        uyari = AlarmPresentation.Alert(title: LocalizedStringResource(stringLiteral: a.baslik))
      } else {
        uyari = AlarmPresentation.Alert(
          title: LocalizedStringResource(stringLiteral: a.baslik),
          stopButton: AlarmButton(text: "Tamam", textColor: .white, systemImageName: "checkmark"))
      }
      let nitelik = AlarmAttributes<CemberMeta>(
        presentation: AlarmPresentation(alert: uyari),
        metadata: CemberMeta(),
        tintColor: Color(red: 0, green: 0.47, blue: 0.42))
      do {
        _ = try await yonetici.schedule(
          id: uuid,
          configuration: .alarm(schedule: .fixed(a.zaman), attributes: nitelik))
      } catch {
        NSLog("CemberAlarm AlarmKit: \(error)")
        return false
      }
    }
    return true
  }
  #endif

  // MARK: Yerel bildirim (iOS 16–25 ya da AlarmKit izni yok)

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
      icerik.sound = .default
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
