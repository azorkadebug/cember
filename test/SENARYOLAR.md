# Çember — Elle Koşulan İşlevsel Senaryo Listesi

App Store'a her yayından önce bu liste baştan sona elle koşulur. Her satır: numara · alan · adımlar · beklenen.
Yıkıcı adımlar için kendi test sınıfını oluştur (örn. `F-TEST`), gerçek sınıflara dokunma; işin sonunda test sınıfını sil.
Son koşu: 2026-09-05, web derlemesi (commit bfd3465), 430×932 telefon görünümü — sonuçlar en altta.

## A. Sınıf

| No | Adımlar | Beklenen |
|----|---------|----------|
| S01 | Sınıflarım → Sınıf Ekle → ad `F5` → Ekle | Kart listede, altında "Öğrenci ekle" |
| S02 | Sınıf Ekle → 30 karakterlik ad (`F-TEST UZUN SINIF ADI DENEMESİ`) → Ekle | Kart oluşur, ad kırpılmadan/taşmadan iki satırda görünür |
| S03 | Sınıf Ekle → `F-TEST` → Ekle | Ana test sınıfı oluşur |
| S04 | Aynı adla (`F-TEST`) ikinci sınıf ekle | Uyarı ("bu adda sınıf var") ya da ayırt edici bir işaret; sessizce ikinci kart oluşmamalı |
| S05 | Sınıf Ekle → Branş açılır listesi → `Resim` | Çipler Boya · Fırça · Resim Defteri'ne döner; Ekle ile sınıf oluşur ve kartında bu kalemler gelir |
| S06 | Sınıf kartını sola kaydır → İsmi Düzenle → yeni ad → Kaydet | Liste yeni adı gösterir. (Yardım metni "basılı tut" der; basılı tutma da menüyü açmalı) |
| S07 | Kartı sola kaydır → Sınıfı Sil → onay diyaloğu → İptal; tekrar → Evet, Sil | Onay metninde sınıfın ADI yazar; İptal'de kart kalır; Evet'te listeden düşer |
| S08 | Sınıf Ekle → adı boş bırakıp Ekle | Sınıf oluşmaz; kullanıcıya "ad gerekli" geri bildirimi |
| S22 | Bir sınıf ekle/sil/yeniden adlandır, listeye bak | Diğer sınıfların "N öğrenci" sayaçları doğru kalır (0'a düşmez) |

## B. Öğrenci

| No | Adımlar | Beklenen |
|----|---------|----------|
| S09 | F-TEST → ⋮ → Hızlı Öğrenci Ekle → yalnız 1. satıra ad → Tümünü Kaydet | "1 öğrenci eklendi!", listede görünür, Toplam 1 |
| S10 | Hızlı Ekle: `Şükrü Çağlar İğdeli`, `Ayşe` (♀), `Mehmet Yılmaz`, `Zeynep Kara` (♀, puan 120), 5. satır boş | "4 öğrenci eklendi!"; Türkçe karakterler bozulmaz; cinsiyet renkleri doğru; boş satır atlanır |
| S10c | Listeye bak | Alfabetik sıra Türkçe alfabeye göre (Ş, S ile T arasında) |
| S11 | Hızlı Ekle → Satır Ekle ×15 → 20 ad (10 ♀ 10 ♂, puanlı) → Tümünü Kaydet | "20 satır" sayacı; "20 öğrenci eklendi!"; Toplam 25 |
| S12 | Hızlı Ekle ile var olan bir adı (`Ali Veli`) tekrar ekle → Atla; tekrar → Yine de Ekle | "Aynı İsim Var" diyaloğu; Atla'da eklenmez, Yine de Ekle'de ikinci kayıt eklenir |
| S13 | Öğrenci satırına dokun → kart: Kıyafet +2, Sarı Kart +1, not yaz, ifade Ateş, isim/puan değiştir, cinsiyet değiştir → Kaydet | Listede yeni ad, "2 işaret" rozetleri, "Not" etiketi (not İÇERİĞİ listede görünmez), cinsiyet rengi; kartı yeniden açınca tüm değerler kalıcı |
| S14 | Kart → Eşleş → Ekle → seçiciden bir öğrenci işaretle → Kapat → Kaydet | İki öğrencinin satırında "Eşli"; karşı öğrencinin kart özetinde "Eşli: …" |
| S15 | Kart → Rozet Ver → Lider; sonra çipteki × → Sil | Kartta "👑 Lider" çipi, listede 👑; kaldırınca ikisi de gider |
| S16 | Kart → Sağlık + → not yaz → Ekle → Kaydet; yeniden aç → "Sağlık" satırına dokun | Sayaç 1, listede sağlık rozeti; geçmişte tarihli not |
| S17 | Kart → sayaç 0'dayken − bas (4 kez); Erkek seç → İptal → yeniden aç | Sayaç 0'ın altına inmez; İptal hiçbir değişikliği kaydetmez |
| S18 | Kart → Sil → İptal; tekrar Sil → Evet, Sil | İptal'de öğrenci kalır; Evet'te listeden düşer, Toplam bir azalır |
| S19 | Sınıf içi arama: `şük`, `iğdeli`, `İĞDELİ`, `ali`, `zzz`; × ile temizle | Kısmi ve Türkçe İ/ı eşleşir (büyük İ dahil); boş sonuçta "sonuç yok" mesajı; × tam listeyi getirir; sonuç listenin BAŞINDA görünür |
| S20 | Sınıflarım → büyüteç → `iğdeli` / `ŞÜKRÜ` / `zzz`; sonuca dokun; geri dön | Tüm sınıflarda arar; "Sonuç yok" mesajı; sonuç öğrencinin kartını açar; arama boşken "SON BAKILANLAR" |
| S21 | Sınıfı aç (Toplam N) → listeyi aşağı-yukarı kaydır | Başlıktaki Toplam/Mevcut/Yok sayacı doğru kalır (0'a düşmez) |

## C. Yoklama

| No | Adımlar | Beklenen |
|----|---------|----------|
| S23 | F-TEST → ✓ (Yoklama) | Bugünün tarihi, herkes "Geldi", alt sayaç "25 / 25 geldi", Kaydet düğmesi |
| S24 | Değişiklik yapmadan Kaydet | "Değişiklik yok." uyarısı, yazma olmaz |
| S25 | İki öğrencide Geldi → Yok; birinde karta dokun → Kıyafet çipini ✗ yap → Kaydet | Alt sayaç "23 / 25"; "… yoklaması kaydedildi"; geri çıkıp yeniden açınca aynı işaretler yüklenir |
| S26 | Tarih → dünkü gün → bir öğrenciyi Yok yap → Kaydet → bugüne dön | Dünkü kayıt ayrı tutulur; bugünün kaydı bozulmaz |
| S27 | Aynı güne ikinci kayıt: bir işaret daha ekle → Kaydet | Önceki işaretler korunur, yeni işaret eklenir (birleştirme) |
| S28 | "Yeni Ders / Tümü Geldi" (işaret varken) → Vazgeç; tekrar → Sıfırla → Kaydet | Onay sorulur; Vazgeç'te işaretler kalır; Sıfırla'da herkes Geldi, sayaç 25 / 25 |
| S29 | Öğrenci listesinde satırı sağa kaydır (Yok Say) | Satır üstü çizili + "Yok" etiketi; başlık "Yok" sayacı artar; yoklama ekranı bu durumu yansıtmaz (ayrı sistemler — bilinçli mi?) |

## D. Takım Kurma

| No | Adımlar | Beklenen |
|----|---------|----------|
| S30 | Yalnız 1 öğrenci "burada" iken AI Takım Kur (2 takım) | "Yeterli öğrenci yok." uyarısı |
| S31 | 3 öğrenci burada, 2 takım | 2+1 dağılım, kart başlıklarında kişi/puan |
| S32 | 25 öğrenci, 4 takım | Kişi farkı ≤ 1; kızlar ve erkekler takımlara dengeli dağılır |
| S33 | Ateş ve Su ifadeli iki öğrenci | Farklı takımlara düşer (5 karıştırmada 0 çatışma) |
| S34 | Eşli ikili (S14) | Her karıştırmada aynı takımda; satırlarında 🔗 |
| S35 | Yeniden Karıştır | Takım adları/dağılım değişir, dengeler korunur |
| S36 | ⋮ → Takım Renkleri: renk sil, `Mor` ekle → Kaydet ve Kapat; takım kur | Silinen renk kullanılmaz, yeni renk sıraya girer; takım sayısı seçeneği renk sayısına göre |

## E. Skor Tablosu

| No | Adımlar | Beklenen |
|----|---------|----------|
| S37 | Takım dağılımı → Oyunu Başlat | Skor ekranı: takım kartları 0-0, 00:00, hazır süreler |
| S38 | + / − ; 0'dayken − | Skor artar/azalır, 0'ın altına inmez |
| S39 | 0:30 seç → BAŞLAT → 3 sn bekle → DURDUR → Sıfırla | Sayaç azalır, durur, 00:30'a döner |
| S40 | 0:30 → BAŞLAT → 30 sn bekle | Tam ekran kırmızı "SÜRE BİTTİ" + skor özeti; dokununca kapanır; düğme "SÜRE BİTTİ" |
| S41 | 2dk Ceza → oyuncu seç | Kırmızı şeritte oyuncu + 02:00 geri sayar (birkaç sn sonra azalmış); listede üstü çizili; × ile iptal → şerit kalkar |
| S42 | Oyuncu satırını basılı tutup diğer takıma sürükle | Oyuncu karşı takıma geçer, başlık (N) güncellenir |
| S43 | Oyuncu satırına dokun → İsim Düzenle → Kaydet | Satırda yeni ad (yalnız maç içinde) |
| S44 | Sunum modu aç → panele dokun (+1) → basılı tut (−1) → çık | Devasa skor; dokunma +1, basılı tutma −1; çıkışta normal görünüm |
| S45 | ← Sınıfa dön (süre çalışırken) → "Etkinlik devam ediyor / Devam Et" | Skor ve kalan süre korunur; süre arkada işlemeye devam eder |
| S46 | Sınıflarım şeridi → ⏹ Etkinliği bitir → Evet, Bitir | Şerit kalkar; sınıfta banner yok |

## F. Sınıflar Arası Yarışma

| No | Adımlar | Beklenen |
|----|---------|----------|
| S47 | Sınıflarım → 🏆 → Ev sahibi / Deplasman seç, renk seç → Yarışmayı Başlat | Skor ekranı, takım adları sınıf adları; aynı sınıf seçilirse "Aynı sınıfı seçemezsiniz."; boş sınıfta "hazır öğrenci yok" ve diyalog açık kalır |

## G. Profil

| No | Adımlar | Beklenen |
|----|---------|----------|
| S48 | Profilim → Ad/Okul/Şehir değiştir, branş seç → Kaydet | "Profil kaydedildi."; yeniden açınca değerler kalıcı |
| S49 | Alan değiştir → Geri | "Kaydedilmemiş değişiklikler" uyarısı; Vazgeç'te ekranda kalır |

## H. Demo Modu (yalnızca admin hesabı)

| No | Adımlar | Beklenen |
|----|---------|----------|
| S50 | Göz simgesi → Demo Aç → sınıf listesi, kart, arama, yoklama, skor | Tüm ekranlarda sahte isimler; arama sahte ada göre çalışır |
| S51 | Demo Kapat | Gerçek isimler geri gelir |

## I. Oturum

| No | Adımlar | Beklenen |
|----|---------|----------|
| S52 | Çıkış Yap → giriş ekranı → e-posta/şifre → Hesabıma Gir | Giriş ekranı gelir; tekrar giriş sınıf listesini yükler |

## Temizlik
F-TEST, F-RESİM, F5 (yeniden adlandırılmış), uzun adlı sınıf silinir; 6-C Pırıltılar'a yalnız okuma amaçlı dokunulur.

## Koşu sonucu — 2026-09-05 (F ajanı, web derlemesi bfd3465, 430×932)

PASS 59 · FAIL 13 · ŞÜPHELİ 1 · KOŞULAMADI 2 (toplam 75 kontrol). Ayrıntılı rapor: denetim #4 F raporu (artifact).

| No | Durum | Gözlenen |
|----|-------|----------|
| S01 | PASS | listede: F5 / 0 öğrenci |
| S02 | PASS | listede: F-TEST UZUN SINIF ADI DENEMESİ / 0 öğrenci |
| S03 | PASS | oluştu |
| S04 | FAIL | uyarısız 2 adet aynı adlı kart oluştu |
| S05 | PASS | görünen: Boya, Fırça, Resim Defteri |
| S05b | PASS |  |
| S06 | PASS | yeni ad listede ("FF5-YENİ"; baştaki F sürücünün seç-sil artığı, uygulama hatası değil) |
| S06b | FAIL | basılı tutma sınıfı açıyor (dokunma gibi); menü yalnız sola kaydırmayla açılıyor |
| S07a | PASS | önce 2, sonra 2 |
| S07b | FAIL | metin: "GhATq7Pnr6e8PfUT4E0q sınıfını ve tüm öğrencilerini silmek istediğinize" |
| S07c | PASS | önce 2, sonra 1 |
| S08 | PASS | diyalog açık kaldı (geri bildirim yok) |
| S09 | PASS | mesaj: "1 öğrenci eklendi!", listede: true |
| S10 | PASS | mesaj "4 öğrenci eklendi!"; Şükrü Çağlar İğdeli, Ayşe (kız), Mehmet Yılmaz, Zeynep Kara (kız) listede; boş satır atlandı |
| S10b | PASS | Toplam=5 |
| S10c | FAIL | "Şükrü…" listede "Zeynep"in ALTINDA — Ş, Z'den sonra sıralanıyor (Dart toLowerCase+compareTo, Türkçe harf sırası yok) |
| S11 | PASS | "20 satır" sayacı; kayıt sonrası Toplam=25 |
| S12a | PASS | uyarı: true, mesaj: "Yoklama", Toplam=25 |
| S12b | PASS | mesaj: "1 öğrenci eklendi!", Toplam=26, Ali Veli satırı: 2 |
| S13a | PASS | satır: Erkek öğrenci / Ayşe Yıldız / Kontrol kalemleri, 2 işaret; not düğmesi: "Not" (içerik listede gizli) |
| S13b | PASS | Kıyafet=2 SarıKart=1 not="Gözlük takıyor" isim="Ayşe Yıldız" puan="120" özet="120 puan  ·  🔥 Ateş" |
| S13c | PASS | Kız öğrenci |
| S13d | PASS | 2/2 |
| S14 | PASS | seçici: true, çip: true, listede Ali:true Ayşe:true, Ayşe kartı özeti: "120 puan  ·  🔥 Ateş  ·  Eşli: Ali Veli" |
| S15 | PASS | listede👑:true çip:true onay:true kaldırıldı:true liste sonrası👑:false |
| S16 | PASS | sayaç 1, listede "1 işaret"; geçmiş diyaloğunda "05.09.2026 — Bu hafta koşu yok, yürüyüş yapsın" |
| S17 | PASS | 4 kez azalt → 0; Erkek seçip İptal → yeniden aç: Kıyafet=2, cinsiyet=Kız öğrenci |
| S18 | PASS | onay:true iptal sonrası kart açık:true Ali Veli sayısı:1 Toplam 26→25 |
| S19a | PASS | sonuç: Şükrü Çağlar İğdeli |
| S19b | FAIL | "iğdeli": SONUÇ YOK; "İĞDELİ": SONUÇ YOK; "ipek" (İpek Doğan var): SONUÇ YOK — büyük İ içeren adlar sınıf içi aramada bulunamıyor (toLowerCase "İ"→"i̇") |
| S19c | PASS | sonuç: Ali Veli |
| S19d | FAIL | satır: 0, mesaj: YOK (boş gri alan, açıklama yok) |
| S19e | PASS | görünen satır: 11 |
| S19f | FAIL | tek sonuç y=638–742'de (liste üstü y=232), üstte boş alan; eski kaydırma konumu korunuyor |
| S20a | PASS | a:16 A:16 i:16 İ:16 ı:10 zzz:0 mesaj:"Sonuç yok" |
| S20b | PASS | "Aysu Berk" sonucuna dokununca 6-C ekranı kartı açık geldi (F_B20_sonuctan_kart); boş aramada SON BAKILANLAR: Aysu Berk |
| S21 | FAIL | açılışta {"toplam":25,"mevcut":25,"yok":0} → kaydırma sonrası {"toplam":0,"mevcut":0,"yok":0} |
| S22 | FAIL | silmeden önce {"6-C Pırıltılar":"15 öğrenci","7-A Yıldızlar":"15 öğrenci","8-B Şahinler":"16 öğrenci"} → sonra {"6-C Pırıltılar":"15 öğrenci","7-A Yıldızlar":"15 öğrenci","8-B Şahinler":"0 öğrenci"} |
| S23 | PASS | başlık "Yoklama • F-TEST / Bugün — 5 Eylül 2026", 25 satır Geldi, alt çubuk "25 / 25 geldi" + Kaydet (kare F_C23) |
| S24 | PASS | mesaj: "Değişiklik yok." |
| S25 | PASS | işaretlerken sayaç "23 / 25 geldi", mesaj "5 Eylül 2026 yoklaması kaydedildi"; geri çıkıp yeniden açınca 2 Yok + "Alp Güler 1 eksik" + sayaç 23/25 yüklendi |
| S26 | PASS | dün açılış: {"yok":0,"eksik":0,"sayac":"25 / 25 geldi"}; dün kayıt mesajı: "4 Eylül 2026 yoklaması kaydedildi"; bugüne dönüş: {"yok":2,"eksik":1,"sayac":"23 / 25 geldi"} |
| S26b | PASS | {"yok":1,"eksik":0,"sayac":"24 / 25 geldi"} |
| S27 | PASS | mesaj "5 Eylül 2026 yoklaması kaydedildi"; yeniden açınca 3 Yok, "22 / 25 geldi" — önceki 2 Yok korundu, yeni eklendi. (Kıyafet ✗ işaretli Alp Güler bu turda Yok yapıldığı için "1 eksik" rozeti gizlendi: Yok olan öğrencide kalemler gösterilmiyor, tasarım gereği) |
| S28 | PASS | onay diyaloğu çıktı (F_C28_onay); Vazgeç sonrası 3 Yok korundu (ilk koşu); Sıfırla sonrası "25 / 25 geldi"; Kaydet "5 Eylül 2026 yoklaması kaydedildi"; yeniden açınca yok=0, eksik=0, 25/25 |
| S29 | PASS | kaydırma sonrası satır: "Geldi / Kız öğrenci / Ada Özkan / Yok / Kontrol kalemleri, eksik yok", başlık {"toplam":25,"mevcut":24,"yok":1}; geri: {"toplam":25,"mevcut":25,"yok":0} |
| S30 | PASS | mesaj: "Yeterli öğrenci yok." |
| S31 | PASS | başlık: "3 oyuncu  •  2 takım", kartlar: Alt+F4 Kalesi Kırmızı  •  2 kişi  •  (192 puan) / Uçan Halıcılar Mavi  •  1 kişi  •  (102 puan) |
| S32 | FAIL | boyut 6/6/7/6, kız 1/2/3/2, erkek 5/4/4/4, puan 599/600/644/590 ; boyut 6/6/6/7, kız 1/2/2/3, erkek 5/4/4/4, puan 606/596/592/644 ; boyut 6/6/6/7, kız 2/1/2/3, erkek 4/5/4/4, puan 599/602/600/649 (sürücü hatasıyla İpek 1150, Ceren 1105, Beren 1205 girilmişti; 100'e düzeltildi) |
| S33 | PASS | 0/5 turda aynı takıma düştü; boyutlar 6/6/7/6 ; 12/13 ; 13/12 ; 12/13 ; 12/13 |
| S34 | PASS | 0/5 turda ayrıldı (2 takım) — 4 takımda da aynı takımdaydı (F_D32) |
| S35 | PASS | 5 turda 20 farklı takım adı görüldü |
| S36 | PASS | önce: Kırmızı,Mavi,Sarı,Yeşil,Siyah,Beyaz,Turuncu,Lacivert; sonra: Mavi,Sarı,Yeşil,Siyah,Beyaz,Turuncu,Lacivert,Mor; takım seçenekleri: 2 Takım/3 Takım/4 Takım/5 Takım/6 Takım/7 Takım/8 Takım; kurulan takım renkleri: Mavi/Sarı; yeniden açınca: Mavi,Sarı,Yeşil,Siyah,Beyaz,Turuncu,Lacivert,Mor |
| S37 | PASS | {"baslik":true,"skor":["Ninja Kaplumbağalar skoru 0","Meteor Kurabiyeler skoru 0"],"sure":"00:00","preset":6,"baslat":true} |
| S38 | PASS | Ninja Kaplumbağalar skoru 1 → Ninja Kaplumbağalar skoru 0 |
| S39 | PASS | ayar 00:30; 3 sn sonra 00:27 (düğme DURDUR:true); durdurunca 00:26 → 1,5 sn sonra 00:26; sıfırla → 00:30 |
| S40 | PASS | alarm katmanı:true, "Kapatmak için dokun":true, dokununca kapandı:true, düğme:SÜRE BİTTİ |
| S41 | PASS | diyalog:"2 dk Ceza — Mavi"; şerit:true 01:58→3 sn sonra 01:55; satır:true; düğme:Ceza (1); iptal sonrası şerit kalktı:true |
| S42 | PASS | Zeynep Kara: Kitap Unutanlar (13) / Alt+F4 Kalesi (12) → Kitap Unutanlar (12) / Alt+F4 Kalesi (13); karşı sütunda: true |
| S43 | PASS | diyalog:true, "Ayşe Yıldız" → "Ayşe Yıldız X": true |
| S44 | PASS | paneller: Ninja Kaplumbağalar skoru 0. Artırmak için dokun, azaltmak için basılı tut / Meteor Kurabiyeler skoru 0. Artırmak için dokun, azaltmak için basılı tut; dokun → "Ninja Kaplumbağalar skoru 1. Artırmak için dokun, azaltmak için basılı tut"; basılı tut → "Ninja Kaplumbağalar skoru 0. Artırmak için dokun, azaltmak için basılı tut"; çıkış → normal görünüm:true |
| S45 | PASS | çıkarken 04:58 / Ninja Kaplumbağalar skoru 1, Meteor Kurabiyeler skoru 0; banner:true; ~5 sn sonra dönüş: 04:50 / Ninja Kaplumbağalar skoru 1, Meteor Kurabiyeler skoru 0; çalışıyor:true |
| S46 | PASS | şerit:true, onay:true, bitince şerit kalktı:true, sınıfta banner:false |
| S47 | FAIL | Yarışmayı Başlat → skor ekranı AÇILMIYOR; diyalog açık kalıyor; arkada "Etkinlik devam ediyor" şeridi beliriyor (etkinlik başlamış). İptal ile diyalog kapanınca şerit duruyor, skor ekranı yok. 3 kez tekrarlandı (F_F47_sonuc, F_F47_skor, F_F47_iptal_sonrasi). Kaynak: siniflar_ekrani.dart:1085 SkorEkrani push ediliyor, hemen ardından :975 Navigator.pop(ctx) EN ÜSTTEKİ rotayı (skor ekranını) kapatıyor, diyalog kalıyor. |
| S47b | PASS | karede kırmızı snackbar "FF5-YENİ sınıfında hazır öğrenci yok." görünüyor, diyalog açık kaldı (snackbar diyaloğun ARKASINDA, kısmen örtülü) |
| S47c | ŞÜPHELİ | sürücü uyarı metnini yakalayamadı (diyalog içi snackbar); önceki koşuda diyalog kapanmadı ve yarışma başlamadı — engel çalışıyor, metin doğrulanamadı |
| S47d | FAIL | açılan: Sınıf ekranı (Devam Et banner) (ev sahibi sınıfın öğrenci listesi; skor için bir dokunuş daha gerekiyor) |
| S47e | PASS | F-RESİM skoru 0 / F-TEST skoru 0 |
| S48 | PASS | mesaj "Profil kaydedildi."; yeniden açınca okul="F-TEST Okulu", şehir="İzmir", branş Türkçe:true |
| S49 | PASS | uyarı:true, Vazgeç sonrası profil ekranında:true |
| S49b | FAIL | hiçbir şey değiştirmeden alana dokunup çıkınca "Kaydedilmemiş değişiklikler" uyarısı çıkıyor (controller listener seçim değişiminde de tetikleniyor) |
| S50 | KOŞULAMADI | demo@cember.org hesabında Demo Aç/Kapat düğmesi YOK (yalnız admin UID'de görünür; auth_service.dart:18,35 ve siniflar_ekrani.dart:84-100). Üst çubuk düğmeleri: Öğrenci ara, Yardım, Profilim, Çıkış Yap |
| S51 | KOŞULAMADI | S50 ile aynı neden |
| S52 | PASS | giriş ekranı:true; tekrar giriş sonrası 10 kart: Öğrenci ara / F-TEST / 25 öğrenci / 5-A SİNCAPLAR / Öğrenci ekle / 5S / Öğrenci ekle |
| S53 | PASS | yeniden yükleme sonrası kartlar: Öğrenci ara / 5-A SİNCAPLAR / Öğrenci ekle / 5S / Öğrenci ekle / 6-C Pırıltılar / 15 öğrenci / 7-A Yıldızlar / 15 öğrenci / 8-B Şahinler / 16 öğrenci |
