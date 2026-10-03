# KalemSimgeleri

Öğrenci kartındaki kontrol kalemlerinin Çember'e özel simgeleri: Kıyafet, Ayakkabı, Sarı Kart, Sağlık, Mola.

- 24×24 ızgara, 2px güvenli kenar, dolu biçim, yumuşak köşeler: Material Icons Round'un yanında aynı ailedenmiş gibi durur. Material'da bu kalemleri doğru anlatan simge olmadığı için çizildi (eskiden `checkroom`, `directions_run`, `style`, `medical_services`, `front_hand`).
- Ayakkabı ve Sağlık'taki delikler (bağcık, artı) `fill-rule="evenodd"` ile oyuk: zemin rengi içinden görünür, ayrı renk verme.
- Boyutlar: 16 (hap içi, satır içi), 18 (sayaç rozeti), 24 (liste), 40 (karo). 16'nın altına indirme.
- Renk: kodda satır içi SVG olarak `fill="currentColor"`; varsayılan `ana`. Sayaç rozetinde kalemin kendi tonu ve %16 zemini (Sarı Kart `#ffa000`, Kıyafet `#009688`, diğerleri `ana`).
- Simge tek başına anlam taşımaz: hapta adıyla, sayaçta `title` / erişilebilir etiketle birlikte.

Dosyalar: `assets/Simgeler/` (mürekkep `ana` #37474f). Flutter için SVG'ler `flutter_svg` ile ya da bir ikon yazı tipine dönüştürülerek kullanılabilir. Kullanan sağlar: kalem adı, boyut, renk.
