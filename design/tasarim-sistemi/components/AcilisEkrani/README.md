# AcilisEkrani

Uygulama açılırken ve yarışma (skor) ekranına geçerken gösterilen tam ekran bekleme.

- **Açık** (`cm-acilis`): `zemin` üzerinde ortada küre logo (96px, `logo_256.png`) ve altında "Çember" 26/800 `ana-koyu`. Altta 120px turkuaz çizgi yükleyici (`cm-cizgi-yukle`) ve durum metni 13px `metin-ikincil`: "Sınıfların hazırlanıyor…".
- **Koyu** (`cm-acilis--koyu`): `panel-koyu-1` → `panel-koyu-2` gradyanı, ortada `emoji_events` (`forma-sari`), "Yarışma" beyaz, koyu çember yükleyici. Yalnız skor dünyasına girerken; yönetim ekranlarında kullanma.
- Metin "sen" diliyle ve ne beklendiğini söyler; "Yükleniyor…" tek başına kullanılmaz. 1 saniyeden kısa sürecekse açılış ekranı gösterme, doğrudan iskelete geç.
- Sağ üst köşede kapaktaki çember motifinden iki taşan halka (6px, `vurgu-zemin`; koyuda beyaz %5): süs, hareketsiz.
- Logo dönmez, yanıp sönmez, renklendirilmez; hareket yalnız yükleyicide.
- `prefers-reduced-motion`: çizgi sabit, metin nabzı kapalı.

Kullanan sağlar: durum metni. Flutter'da karşılığı yok (yeni tasarım).
