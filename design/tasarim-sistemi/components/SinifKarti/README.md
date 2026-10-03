# SinifKarti

Sınıflarım listesindeki tek sınıf. Solda yoklama halkası: sınıfın kısaltması ("7A") ve etrafında son yoklamada gelenlerin oranı; ad 18/700, altında son yoklamanın özeti `metin-ikincil`.

- **Yoklama halkası** (`cm-sinif__halka`): 52px, 5px kalınlık. İz `ana-50`, dolu yay `vurgu`, saat 12'den saat yönünde, yuvarlak uçlu. Ortada kısaltma 15/800 `ana-koyu`: sınıf adından ayırıcılar (-, /, boşluk) atılır, en çok 3 karakter ("7-A" → "7A", "Hazırlık B" → "HB").
- Yayın oranı = son yoklamada gelen / sınıf mevcudu. Alt satır sayıyla ve ne zaman olduğuyla söyler: "20 / 24 geldi · bugün", "· dün", ondan eskiyse tarih ("· 28 Eylül"). Oran yalnız renkle verilmez; sayı her zaman yazılı.
- Hiç yoklama alınmamış sınıf: yalnız iz, alt satır "24 öğrenci · yoklama alınmadı".
- Öğrencisiz sınıf (`cm-sinif__halka--bos`): kesik çizgili `cizgi` halka, kısaltma `metin-ucuncul`, alt satır `uyari` renkli "Öğrenci ekle" daveti.
- Seçili (yarışma için sınıf seçerken): kart `vurgu-zemin` + 2px `vurgu`, halkanın izi `zemin`.
- Halka bir ilerleme göstergesidir, bu yüzden turkuazdır (README'deki "turkuaz yalnız eylem, seçim, ilerleme" kuralı). Sınıfları renkle ayırma; eski 12 gradyanlı `groups` karosu kaldırıldı.
- Erişilebilirlik: halkaya `aria-label` ("7-A, bugün 20 / 24 geldi").
- Kart `radius-xl` (16px), `zemin` üzerinde, sayfa `sayfa-zemin`.

Kullanan sağlar: sınıf adı, öğrenci sayısı, son yoklamada gelen sayısı ve tarihi. Yeni tasarım; Flutter'da kartın son yoklama verisini göstermesi gerekir (`siniflar_ekrani.dart`).
