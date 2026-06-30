# Çember App Store Submission — Nerede Kaldık?

Son güncelleme: **24 Mayıs 2026**

---

## ✅ Bugün tamamlanan işler

### 1. iOS Yapılandırma
- **Bundle ID:** `org.cember.cember` (Flutter default `com.example.cember`'dan değiştirildi)
- **Display Name:** "Çember" (Info.plist'te `CFBundleDisplayName`, Türkçe ç ile)
- **İkon:** Mevcut rengarenk küre tasarımı `flutter_launcher_icons` ile tüm 21 iOS boyutuna yeniden üretildi (alpha kanalı yok, App Store uyumlu)

### 2. Apple Sign-In (App Store zorunluluğu — Guideline 4.8)
- **Kod:** `lib/screens/giris_ekrani.dart` içinde resmi `SignInWithAppleButton` widget'ı eklendi (Google'ın üstüne)
- **Entitlement:** `ios/Runner/Runner.entitlements` oluşturuldu, `com.apple.developer.applesignin` capability eklendi
- **project.pbxproj:** 3 build config'e `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;` eklendi

### 3. Hesap Silme Özelliği (Apple Guideline 5.1.1(v))
- **`auth_service.dart`:** `deleteAccount()` metodu eklendi
- **`firestore_service.dart`:** `tumVerileriSil()` metodu — sınıflar + öğrenciler + profil cascading delete (450'lik batch'ler)
- **`profil_ekrani.dart`:** "Tehlikeli Bölge" bölümü — iki aşamalı onay (SIL yazma), loading dialog, `requires-recent-login` yeniden giriş yönlendirmesi

### 4. Takım Algoritması — Bug Fix + İyileştirme
- **Bug:** 15 öğrencide 9-6 dengesiz dağılım (element çatışma fallback'i count balance'ı bozuyordu)
- **Fix:** `ogrenci_listesi_ekrani.dart` `_takimlariKur` → element uyumu skorlama tabanlı:
  - Aynı element üye: **+10** birleştirme bonusu
  - Çatışan element üye: **-100** ayırma cezası
  - Eşit kişi sayısı **hard constraint** (max 1 fark)
  - Skor dengesi tiebreaker

### 5. Gizlilik Politikası (KVKK + Apple zorunluluğu)
- **URL canlı:** https://cemberapp-2a101.web.app/privacy.html
- **Dosya:** `web/privacy.html` (Türkçe ana, İngilizce özet alt)
- Kapsam: veri sorumlusu, toplanan veriler, üçüncü taraf servisler, admin erişimi şeffaflığı, çocuk verisi + veli onayı, KVKK 11. madde hakları

### 6. Web Deploy
- `https://cemberapp-2a101.web.app` güncellendi — hesap silme + Apple Sign-In düğmesi canlı
- Privacy URL erişilebilir
- **NOT:** Element fix henüz web'e deploy edilmedi (sadece kodda)

### 7. Demo Hesap (Apple Reviewer + Screenshot için)
- **Email:** `demo@cember.org`
- **Şifre:** `Cember2026!`
- **UID:** `Q3wjkyKzvuXcfpZ2MM0bERmmdDs2`
- Firebase Auth REST API ile oluşturuldu
- 3 sınıf (7-A Yıldızlar, 8-B Şahinler, 6-C Pırıltılar), her birinde 15 öğrenci
- Tüm öğrencilere rastgele element (🔥💧🌱💨) atandı

### 8. App Store Metinleri
- Tek dosya: `store/app_store_metni.md`
- App Name, Subtitle, Description (~2800 char), Keywords, Privacy URL, Demo hesap notları, App Privacy nutrition label tablosu, submission checklist

### 9. iPhone 6.9" Screenshot'lar
- Klasör: `store/screenshots/iphone-6.9/`
- **5 adet, 1320×2868 (App Store uyumlu):**
  - `01-login.png` — Apple + Google + email girişleri
  - `02-classes-and-versus.png` — Sınıflar + Sınıflar Arası Maç modal
  - `03-ai-team-builder.png` — AI Takım Dağılımı, 8 vs 8 dengeli
  - `04-score-board.png` — Skor, timer, ceza sistemi
  - `05-profile-with-account-deletion.png` — Profil + Tehlikeli Bölge

---

## ⏳ Bekleyenler

### Apple Developer Hesabı
- Ödendi: ~₺650 (24 Mayıs ~03:15)
- Aktivasyon durumu kontrol edilmeli: https://developer.apple.com/account
- Aktif olunca → sonraki adımlar mümkün

---

## 📋 Yarın yapılacaklar (Apple hesabı aktif olunca)

### A. Apple Developer Portal
1. **App ID kaydet:** Identifiers → `org.cember.cember`
2. **Capabilities:** Sign in with Apple ✓ (entitlement uyumu için ŞART)
3. (İsteğe bağlı) Service ID — Apple Sign-In web kullanırsak

### B. App Store Connect
1. **My Apps → "+"** ile uygulama oluştur
   - Platform: iOS
   - Name: "Çember — Sınıf Yöneticisi"
   - Primary Language: Turkish
   - Bundle ID: org.cember.cember
   - SKU: cember-app
2. **App Information** — kategori (Education), age rating (4+)
3. **Pricing** — Free
4. **App Privacy** — nutrition label (store/app_store_metni.md'deki tablodan)
5. **App Store sayfası** — store/app_store_metni.md'den copy-paste:
   - Name, Subtitle, Promo Text, Description, Keywords
   - Privacy Policy URL: https://cemberapp-2a101.web.app/privacy.html
   - Support URL: https://cemberapp-2a101.web.app
6. **Screenshots** — store/screenshots/iphone-6.9/ klasöründen 5 PNG'yi sürükle
7. **App Review Information** — demo hesap bilgileri (store/app_store_metni.md bölüm 9)

### C. Xcode → Build → Upload
1. Xcode aç → Runner.xcworkspace
2. Signing & Capabilities → Team seç (yeni Apple Dev hesabın)
3. Build → Destination: "Any iOS Device (arm64)"
4. Product → Archive
5. Organizer → Distribute App → App Store Connect → Upload
6. (10-30 dk processing) → App Store Connect'te build görünür
7. App Store sayfasında "+" → bu build'i seç → Submit for Review

### D. Eğer reddedilirse
- Common reasons: Apple Sign-In configuration, privacy details mismatch, demo account access
- Düzeltip "Submit for Review" tekrar

---

## 🐛 Bilinen / unutmamamız gereken konular

1. **Element fix henüz iOS build'inde test edilmedi** — Simülatörde rebuild + test yapılmadı. Submission öncesi en az bir kez test et.
2. **Web'de element fix yok** — istersen `flutter build web && firebase deploy --only hosting --project cemberapp-2a101` ile güncelle.
3. **Android tarafında ikon hâlâ default** — `flutter_launcher_icons` konfigünde `android: false`. Google Play yüklerken düzelt.
4. **`flutter analyze` info-level warnings** — kritik değil ama bir gün temizlenebilir.
5. **iPad screenshot'ları yok** — iPad de destekleniyorsa Apple ister. İhtiyaç olursa 13" iPad simülatörü kurup screenshot al.

---

## 🔑 Önemli kayıtlar

| Şey | Değer |
|---|---|
| Demo Email | `demo@cember.org` |
| Demo Şifre | `Cember2026!` |
| Demo UID | `Q3wjkyKzvuXcfpZ2MM0bERmmdDs2` |
| Bundle ID | `org.cember.cember` |
| Firebase Project | `cemberapp-2a101` |
| Privacy URL | https://cemberapp-2a101.web.app/privacy.html |
| Support URL | https://cemberapp-2a101.web.app |
| İletişim e-postası | `cember@amoro.org` |
| App Store Name | Çember — Sınıf Yöneticisi |
| Apple Developer ödemesi | ~₺650, 24 May ~03:15 |
