# Iskelet

Liste verisi gelirken gerçek kartın yerini tutan gri iskelet; içerik geldiğinde aynı yerleşim yerine oturur, sayfa zıplamaz.

- `cm-isk` blokları `ana-50` zeminli, soldan sağa yavaş ışıltı (1,4 sn). Köşeler gerçek bileşeninkiyle aynı: sınıf kartı `radius-xl`, ikon karosu `radius-lg`, sayaç `radius-sm`.
- Satır genişlikleri farklı (%25–60): hepsi aynı uzunlukta olursa liste gibi değil desen gibi görünür.
- Bir ekranda en fazla bir ekran boyu (3 sınıf kartı, 4–6 öğrenci satırı) iskelet çiz.
- Kapsayıcıya `aria-busy="true"`. `prefers-reduced-motion`: ışıltı kapalı.

Kullanan sağlar: kaç satır. Yeni tasarım; `SinifKarti` ve `OgrenciSatiri` ölçülerini izler.
