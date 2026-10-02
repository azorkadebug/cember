# Dugme

Çember'in düğmeleri: tek ana eylem turkuaz, gerisi geri çekilir.

- **Birincil** (`cm-btn--birincil`): `vurgu` dolgu, beyaz yazı, 14/700. Ekranda bir tane: "Kaydet", "Takım Kur". Alt çubukta `cm-btn--bar` (16/700, köşe `radius-lg`, 14px dikey dolgu).
- **Koyu** (`cm-btn--koyu`, `cm-btn--oyun`): `panel-koyu-1`. Oyun/yarışma başlatma eylemleri; skor dünyasına geçişi haber verir. "Oyunu Başlat" 54px yüksek, 18/800.
- **Silme**: dolgulu `sil` ("Evet, Sil", "Evet, Bitir") yalnız onay diyaloğunda; ekranda `cm-btn--tehlike-metin` ya da çerçeveli `cm-btn--cerceve-sil`.
- **Metin**: "İptal" `metin-ikincil`; uyarı tonlu toplu eylem "Hepsini Geldi Yap" `uyari`.
- Her düğme en az `dokunma-min` (44px) yüksek. Yazılar Başlık Düzeninde ve fiil ile: "Sınıf Ekle", "Takım Kur"; skor ekranında BÜYÜK HARF ("BAŞLAT").

Kullanan sağlar: etiket, isteğe bağlı Material Icons Round ikon adı. Elle aktarıldı: `lib/main.dart`, `lib/screens/*`.
