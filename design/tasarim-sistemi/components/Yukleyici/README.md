# Yukleyici

Çember yükleyici: markanın halka motifinden dönen tek turkuaz yay; kısa beklemeler için.

- Boyutlar: 16 (düğme içi, satır içi), 24 (bant, liste sonu), 40 (varsayılan), 56 (boş sayfa ortası). Halka `vurgu-zemin`, yay `vurgu`; koyu panelde iz beyaz %12, yay `geldi-serit`; turkuaz düğme içinde beyaz.
- **Düğme bekliyor**: `aria-busy="true"`, zemin `vurgu-koyu`, 16px beyaz çember ve fiilin süren hâli: "Kaydediliyor…", "Takımlar kuruluyor…". Düğme genişliği değişmesin.
- **Liste sonu** (`cm-yukleniyor`): 13/600 `metin-ikincil`, ne yüklendiğini söyler.
- Liste ilk kez açılıyorsa yükleyici değil `Iskelet` kullan. 300 ms'den kısa işlerde hiçbir şey gösterme.

Kullanan sağlar: boyut, metin.
