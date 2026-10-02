# TakimSkoru

Skor ekranında bir takımın paneli: takım rengi gradyanı (%78 → tam), skor 38/900, iki yanda 44px −/+ düğmesi, altta "2 dk Mola" (15px Mola simgesi, `KalemSimgeleri`).

- Metin rengini her zaman `ustMetin` seçer: sarı ve beyaz formalarda `panel-koyu-1`, gerisinde beyaz. Düğme dolgusu `ustDolgu` (beyaz %16 ya da siyah %11).
- Moladaki oyuncu varsa hap `mola` olur: "Mola (1)".
- 3+ takımda dolgu 8px, skor 30px'e iner.
- Sunum modunda panel düz renk, skor 260px'e kadar büyür.

Kullanan sağlar: takım adı, forma rengi adı, skor, moladaki sayısı. Zemin her zaman `panel-koyu-1`. Takım adları ortaokul mizahı: "Lag Kralları", "Tost Mafyası", "Ctrl+Z Spor".
