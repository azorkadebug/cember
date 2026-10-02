# Tasarım dosyaları

Claude Design'da (claude.ai) tutulan Çember tasarımlarının depodaki kopyası. Asıl kaynak claude.ai'deki artifact'lerdir; burası sürüm geçmişi ve yedek içindir. claude.ai'de yapılan değişiklikler buraya kendiliğinden gelmez, önemli bir değişiklikten sonra yeniden kopyalanmalı.

| Klasör | Ne | Kaynak |
| --- | --- | --- |
| `tasarim-sistemi/` | Renk/yazı tokenları (`tokens.json`), marka kitabı (`README.md`), 16 bileşenin statik HTML önizlemesi (`components/`), kontrol kalemi simgeleri (`assets/Simgeler/`) | https://claude.ai/artifact/FMQyEhVvy7bburdjWceaH8 |
| `koyu-tema-tuvali/` | Sınıflar ve Yoklama ekranları: açık, Koyu A (lacivert), Koyu B (charcoal) | https://claude.ai/artifact/DsmwrZK5JQ1AD2i76dMaAG |

Notlar:

- Önizlemeler claude.ai içinde çalışacak şekilde yazıldı: renkleri tasarım sisteminin ürettiği `tokens.css`'ten, logoyu `/_blob/…` adresinden alırlar. Bu yüzden dosyayı tarayıcıda doğrudan açınca renksiz görünür; bakmak için claude.ai'deki sayfayı kullan.
- Logolar burada tekrarlanmadı; asılları `assets/images/logo.png` ve `logo_256.png`.
- Tasarım ile uygulama farklıysa geçerli olan uygulamadır (`lib/`). Tasarım sisteminin README'sinin "Aktarılmayanlar" bölümü henüz koda geçmemiş tasarım kararlarını listeler (Manrope yazı tipi, kalem simgeleri, yoklama halkası, bekleme ekranları).
