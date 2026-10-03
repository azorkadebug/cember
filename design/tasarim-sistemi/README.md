Çember, beden eğitimi (ve artık her branştan) öğretmenin ders sırasında elinde tuttuğu sınıf yardımcısıdır: yoklama, kontrol kalemleri (forma, ayakkabı, sarı kart), takım kurma ve skor tablosu. Tasarımın işi, sahada tek elle, güneş altında, 30 öğrencinin gürültüsünde hızlı okunmak. Sakin bir charcoal gövde, tek bir turkuaz eylem rengi, ve ders oyuna dönünce koyu bir skor dünyası.

## İçerik ilkeleri

- **Dil Türkçe, hitap "sen".** Öğretmene arkadaşça ve kısa konuş: "Sınıfını ekle", "Öğrencileri ekle", "Yoklamanı al". "Siz", resmi kalıp, "lütfen" yok.
- **Düğmeler fiil ile, Başlık Düzeninde:** "Sınıf Ekle", "Takım Kur", "Kaydet", "Oyunu Başlat". Skor ekranında büyük harf: "BAŞLAT", "DURDUR", "SÜRE BİTTİ".
- **Bölüm etiketleri büyük harf**, 12/700, harf aralığı 1.1px, `metin-ucuncul`: "KONTROL KALEMLERİ", "ROZETLER", "BİLGİLER".
- **Onay diyaloğu sonucu söyler:** "Etkinliği tamamen bitirmek istediğine emin misin? Skorlar sıfırlanacak." Onay düğmesi "Evet, Bitir" / "Evet, Sil".
- **Hatalar ne olduğunu ve ne yapılacağını söyler:** "Kaydedilemedi, tekrar dene." · "Bağlantı yok. Yoklama kaydedildi, internet gelince gönderilecek."
- **Sayılar özet olarak:** "18 / 22 geldi", "24 öğrenci", "2 eksik", "Kırmızı • 7 kişi • (84 puan)". Tarihler yazıyla: "2 Ekim 2026", ISO değil.
- **Mizah takım adlarında yaşar**, ortaokul diliyle: "Lag Kralları", "Tost Mafyası", "Ayran United", "Simit Karteli", "Ctrl+Z Spor". Arayüz metninin geri kalanı düz ve işlevsel.
- **Branştan bağımsız yaz:** "Maç" değil "Etkinlik/Yarışma". Beden eğitimine özgü kalemler (Forma, Ayakkabı, Sarı Kart) yalnız o branşın şablonunda.
- **Emoji:** arayüz simgesi olarak KULLANMA; cihaza göre farklı çiziliyor ya da hiç çizilmiyor. Element ve cinsiyet her yerde ikon. Emoji yalnız iki yerde kalır: karşılama ("Hoş geldin! 👋") ve öğrenci rozetleri ("🏅 Fair Play").
- **Öğrenci verisi mahremdir.** Ekran görüntüsü, tanıtım ve tasarım örneklerinde gerçek öğrenci adı kullanma; Demo modu ya da uydurma adlar (Ayşe Yılmaz, Emre Kaya).

## Renk

- **Gövde charcoal:** AppBar ve başlık bantları `ana` (beyaz yazı), koyu gradyan `ana` → `ana-koyu` (öğrenci listesi) ya da `ana` → `ana-acik` (sınıflar başlığı). Beyaz zemindeki ana metin `ana-koyu`.
- **Turkuaz yalnız ana eylem için:** `vurgu` birincil düğme, geniş FAB, odak çerçevesi, seçili durum ve ilerleme göstergesidir. Ekranda turkuaz bir şey varsa basılacak olan odur. AppBar'ı, başlıkları, ikonları turkuaza boyama. Turkuaz metin gerekirse `vurgu-koyu`; seçili zemin `vurgu-zemin`.
- **Sayfa ve kart:** liste ekranları `sayfa-zemin` üzerinde, kartlar `zemin` üzerinde `radius-md`–`radius-xl` köşe ve hafif gölgeyle.
- **İkincil metin:** `metin-ikincil` (açıklama, 13px), `metin-ucuncul` (küçük etiket, 11–12px). İkisi de `zemin` üzerinde AA geçer. Flutter'ın grey400/500'ünü metinde kullanma, geçmiyor.
- **Durum renkleri** yeşil/sarı/kırmızıya ayrılmıştır, vurgu değildir: `basari`, `uyari`, `tehlike` metin içindir, `-zemin` eşleriyle bant ve hap olur. Yoklamada "Geldi" `geldi-zemin`/`geldi-cizgi`/`basari`, "Yok" `yok-zemin`/`yok-cizgi`/`yok-metin`. Durum asla yalnız renkle verilmez; ikon ve sözcük her zaman yanında ("Geldi" ✓, "Yok" ✕).
- **Koyu skor dünyası:** skor ekranı, yarışma FAB'ı, "etkinlik sürüyor" bandı ve oyun başlatma düğmesi `panel-koyu-1`/`panel-koyu-2`. Bu renkler oyunu haber verir; normal yönetim ekranlarına taşıma.
- **Forma renkleri** (`forma-*`) yalnız takımı boyar: skor paneli, takım kartı, oyuncu noktası. Üzerindeki yazının rengini seçerken kontrastı hesapla (`ustMetin`): sarı ve beyaz formada `panel-koyu-1`, diğerlerinde beyaz. Forma rengini arayüz rengi olarak kullanma.
- **Element ve cinsiyet:** `element-ates/su/toprak/hava` ve `cinsiyet-erkek`/`cinsiyet-kiz` yalnız kendi ikonlarında, ikonun rengi + %14 zemin olarak.
- Uygulama bilinçli olarak tek (açık) temadır; skor ekranı kendi koyu paletini kurar. Koyu tema henüz karar aşamasında, bu sistemde tanımlı değil.

## Tipografi

- Yazı tipi **Manrope** (Google Fonts, 400–800; Türkçe karakterlerin hepsi var). Geometrik ama sıcak, rakamları net; sahada uzaktan okunur. Kalınlık hiyerarşiyi taşır: başlıklar 800, ad ve satır başlığı 700, gövde 400. Manrope'ta 900 yok; en kalın 800'dür, daha kalınını isteme (tarayıcı sahte kalın çizer).
- Ölçek tektir, satır içi boyut uydurma: `displaySmall` 30/800 · `headlineMedium` 26/800 · `headlineSmall` 22/800 · `titleLarge` 20/800 (AppBar, diyalog başlığı) · `titleMedium` 16/700 · `titleSmall` 14/600 · `bodyLarge` 16 · `bodyMedium` 14 · `bodySmall` 13 `metin-ikincil` · `labelLarge` 14/600 (düğme) · `labelMedium` 12/600 · `labelSmall` 11/500 `metin-ucuncul`. Diyalog gövdesi `dialogBody` 15, satır 1.45.
- Sayaç ve skor sayıları eş aralıklı (`mono`) ve 900: `sayacSkor` 48px, `sayacSunum` 72px, harf aralığı 4px. Skor sayısı panelde 38/800 Manrope (tabular), sunum modunda 260'a kadar büyür. Hizalanan sayılarda tabular rakam kullan.
- iOS "Daha Büyük Metin" 1,5 katla sınırlı; sabit yükseklikli kartlar buna göre ölçülür.

## Boşluk, köşe, yerleşim

- Sayfa kenarı ve kart dolgusu `space-4` (16). Liste satırları arası 6–8px, kart arası `space-3` (12). Diyalog ve büyük kart `space-5`, boş durum ekranı `space-8`.
- Köşeler: kart `radius-md` (12, Material kart teması), sınıf kartı ve alt sayfa `radius-xl` (16), skor paneli ve diyalog 20, alt sayfa üst köşeleri 20–28, hap çipler `radius-pill`. Keskin köşe yok.
- Her dokunulabilir öğe en az `dokunma-min` (44px). Skor ekranındaki −/+ 44×44, sunum modunda 52×52.
- Geniş ekranda (iPad, masaüstü web) içerik `icerik-max` (720) genişlikte ve üstte ortalanır. iPad'de iki sütun kullanılır.
- Ana ekleme eylemi sağ altta geniş FAB; ekran eylemi alta yapışık beyaz çubukta (solda özet, sağda tek birincil düğme).

## Gölge ve yüzey

- Kartlar `kart` gölgesiyle ya da daha hafif (siyah %6–8, bulanıklık 6–10). Alt çubuğun gölgesi yukarı doğru (y −2).
- Alt sayfalarda üstte 40×4 `cizgi` sürükleme tutamağı.
- Snackbar yüzer, köşe `radius-snack`; hata `tehlike`, bağlantı uyarısı `uyari`, bilgi koyu yüzey.

## İkonlar

- Material Icons **Rounded** (dolu), Flutter'ın `Icons.*_rounded` seti; web'de "Material Icons Round" yazı tipi. Başka ikon seti karıştırma, emoji ikon yerine geçmez.
- Tek istisna: kontrol kalemleri (Kıyafet, Ayakkabı, Sarı Kart, Sağlık, Mola) Çember'e özel çizilmiş simgeleri kullanır (`assets/Simgeler/`, `KalemSimgeleri`). Aynı ızgara ve dolu, yuvarlak dille çizildiler; Material karşılıklarını bu kalemler için kullanma.
- Sık kullanılanlar: person_add_alt (öğrenci ekle), fact_check (yoklama), auto_awesome (Takım Kur), emoji_events (yarışma), sports (Oyunu Başlat), check_circle / cancel (geldi/yok), star (kaptan), link (eşli), shield (takım), local_fire_department / water_drop / eco / air (ateş/su/toprak/hava), male / female (cinsiyet).
- İkon boyutları: satır içi 14–16, liste 18–22, karo içi 26–28.
- İkon karosu: ikonun renginin %10–16'sı dolgu, köşe `radius-sm` ya da `radius-lg`, ikon tam renk.

## Logo

- Küre logo (`assets/Logos/logo.png`, `logo_256.png`): iç içe geçmiş gökkuşağı halkalar. Beyaz ya da açık zemine koy; yeniden çizme, renklendirme veya tek renge çevirme. Logonun renkleri arayüz paletine girmez; arayüzün markası turkuaz + charcoal'dır.

## Bileşenler

Bileşenler Flutter ekranlarından elle aktarılmış statik HTML karşılıklarıdır (`components/bundle.css`, `cm-` önekli sınıflar). Tasarım ve prototip içindir; uygulamanın gerçek kodu `lib/` altındaki Flutter widget'larıdır.

**Bekleme** grubu (`AcilisEkrani`, `Iskelet`, `Yukleyici`) Flutter'dan aktarılmadı, yeni tasarımdır: uygulama açılışı ve yarışma ekranına geçiş için tam ekran bekleme, liste ilk açılırken iskelet, kısa işler için turkuaz çember yükleyici. Kural: 300 ms altı hiçbir şey, ilk liste yüklemesi iskelet, kısa iş çember, açılış ekranı yalnız soğuk açılışta.

## Aktarılmayanlar

- Bileşenler derlenmedi (Flutter, React değil): hepsi `lib/screens/*` ve `lib/main.dart`'tan elle aktarılmış statik önizlemeler.
- Manrope dosya olarak eklenmedi; Google Fonts'tan yükleniyor. Flutter uygulaması hâlâ Roboto kullanıyor: uygulamaya geçmesi için `google_fonts` paketi ya da `assets/fonts/` + `pubspec.yaml` ile Manrope eklenmeli, `tema.dart`'ta `fontFamily` ve 900 kalınlıklar 800'e çekilmeli.
- Flutter'ın Material gri/yeşil/kırmızı tonlarının bir kısmı token değil, bileşen notlarında listeli.
- Sınıf kartının yoklama halkası yeni tasarım; Flutter'daki sınıf kartı hâlâ gradyanlı `groups` karosunu gösteriyor.
- Koyu tema, illüstrasyon dili: henüz yok.
