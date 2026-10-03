# OgrenciSatiri

Sınıf listesindeki öğrenci. Avatar yok: sol kenardaki 3,5×44px şerit cinsiyeti verir (#42a5f5 erkek, #ec407a kız).

- Ad 14/700; gelmeyende üstü çizili gri + "Yok" hapı.
- Alt satır 12/500: not (`uyari` ikon) ya da "Not ekle", eşliyse "Eşli".
- Sağda kontrol kalemi sayaçları: 32px karo, kalem renginin %16'sı, içinde 18px kalem simgesi (`KalemSimgeleri`), sayı rozeti yeşil (eksi değer kırmızı). Hiç eksiği yoksa yeşil check_circle.
- Sağa kaydırınca yoklama: "Geldi" / "Yok yaz".

Kullanan sağlar: ad, cinsiyet, rozetler, not var mı, kalem sayaçları. Elle aktarıldı: `ogrenci_listesi_ekrani.dart:633`.
