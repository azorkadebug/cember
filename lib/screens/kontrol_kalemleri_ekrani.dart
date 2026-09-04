import 'package:flutter/material.dart';
import '../widgets/girdi.dart';
import '../tema.dart';
import '../models/kontrol_kalemi.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

/// Sınıfın kontrol/yoklama kalemlerini düzenleme ekranı.
/// Öğretmen kalem ekler/siler/adlandırır, türünü (günlük/sayaç) ve ikonunu seçer.
class KontrolKalemleriEkrani extends StatefulWidget {
  final String sinifId;
  final List<KontrolKalemi> kalemler;
  const KontrolKalemleriEkrani({super.key, required this.sinifId, required this.kalemler});

  @override
  State<KontrolKalemleriEkrani> createState() => _KontrolKalemleriEkraniState();
}

class _KontrolKalemleriEkraniState extends State<KontrolKalemleriEkrani> {
  late final FirestoreService _db;
  late List<KontrolKalemi> _kalemler;
  bool _kaydediyor = false;
  /// Ekleme/silme/düzenleme/sıralama sonrası true. Geri tuşunda kaydedilmemiş
  /// değişiklik uyarısı vermek için — eskiden geri ok her şeyi sessizce atıyordu.
  bool _kirli = false;

  static const _ikonSecenekleri = [
    'check', 'shirt', 'shoe', 'card', 'brush', 'palette',
    'book', 'notebook', 'music', 'homework', 'pencil', 'ruler',
  ];

  @override
  void initState() {
    super.initState();
    _db = FirestoreService(uid: AuthService().uid);
    _kalemler = widget.kalemler.map((k) => k.copyWith()).toList();
  }

  Future<void> _kaydet() async {
    setState(() => _kaydediyor = true);
    // sira'yı mevcut listeye göre yeniden numarala
    final sirali = <KontrolKalemi>[
      for (var i = 0; i < _kalemler.length; i++) _kalemler[i].copyWith(sira: i),
    ];
    try {
      await _db.kontrolKalemleriGuncelle(widget.sinifId, sirali);
      if (mounted) Navigator.pop(context, sirali);
    } catch (e) {
      if (mounted) {
        setState(() => _kaydediyor = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Kaydedilemedi, tekrar deneyin.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _kalemDuzenle({KontrolKalemi? mevcut, int? index}) {
    final adCtrl = TextEditingController(text: mevcut?.ad ?? '');
    KalemTipi tip = mevcut?.tip ?? KalemTipi.gunluk;
    String ikon = mevcut?.ikon ?? 'check';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(mevcut == null ? 'Kalem Ekle' : 'Kalemi Düzenle',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(
                controller: adCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                maxLength: GirdiSiniri.kalemAdi,
                buildCounter: gizliSayac,
                decoration: InputDecoration(
                  hintText: 'Örn: Kitap, Boya, Sarı Kart...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Tür', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                _tipChip('Günlük ✓/✗', tip == KalemTipi.gunluk, () => setLocal(() => tip = KalemTipi.gunluk)),
                const SizedBox(width: 8),
                _tipChip('Sayaç', tip == KalemTipi.sayac, () => setLocal(() => tip = KalemTipi.sayac)),
              ]),
              const SizedBox(height: 6),
              Text(
                tip == KalemTipi.gunluk
                    ? 'Her ders "getirdi mi?" olarak işaretlenir (kitap, boya...).'
                    : 'Sezon boyu birikir (sarı kart, olumsuz davranış...).',
                style: const TextStyle(color: AppTema.metinIkincil, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text('İkon', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _ikonSecenekleri.map((anahtar) {
                  final secili = anahtar == ikon;
                  return GestureDetector(
                    onTap: () => setLocal(() => ikon = anahtar),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: secili ? AppTema.ana : AppTema.ana50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: secili ? AppTema.ana : Colors.transparent, width: 2),
                      ),
                      child: Icon(kalemIkonu(anahtar), color: secili ? Colors.white : AppTema.ana, size: 22),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTema.ana, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final ad = adCtrl.text.trim();
                if (ad.isEmpty) return;
                setState(() {
                  _kirli = true;
                  if (mevcut == null) {
                    _kalemler.add(KontrolKalemi(
                      id: 'k_${DateTime.now().microsecondsSinceEpoch}',
                      ad: ad, ikon: ikon, tip: tip, sira: _kalemler.length,
                    ));
                  } else {
                    _kalemler[index!] = mevcut.copyWith(ad: ad, ikon: ikon, tip: tip);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ).then((_) => adCtrl.dispose());
  }

  Widget _tipChip(String label, bool secili, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: secili ? AppTema.ana : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label, style: TextStyle(
          color: secili ? Colors.white : Colors.grey.shade700,
          fontWeight: FontWeight.w600, fontSize: 13,
        )),
      ),
    );
  }

  /// Geri çıkmadan önce kaydedilmemiş değişiklik varsa sorar.
  Future<bool> _cikisOnayi() async {
    final cikilsin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kaydedilmemiş değişiklikler'),
        content: const Text('Kalemlerde yaptığın değişiklikler kaydedilmedi. Çıkarsan kaybolacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydetmeden çık', style: TextStyle(color: AppTema.tehlike, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return cikilsin ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_kirli,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _cikisOnayi() && mounted) {
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: _govde(),
    );
  }

  Widget _govde() {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        title: const Text('Kontrol Kalemleri'),
        actions: [
          TextButton(
            onPressed: _kaydediyor ? null : _kaydet,
            child: _kaydediyor
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _kalemler.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.checklist_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Henüz kalem yok', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTema.metinIkincil)),
                  const SizedBox(height: 6),
                  const Text('Aşağıdaki "Kalem Ekle" ile branşına uygun kalemler ekle\n(kitap, boya, forma, sarı kart...).',
                      textAlign: TextAlign.center, style: TextStyle(color: AppTema.metinUcuncul)),
                ]),
              ),
            )
          // 1440 px'te kartlar tam genişlikti; sil/tutamak isimden 1250 px
          // uzaktaydı (denetim O5).
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTema.icerikMaxGenislik),
              child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _kalemler.length,
              // Flutter masaüstü/web'de kendi sürükleme tutamağını satırın
              // sağına otomatik bindiriyordu; aşağıdaki elle eklenen ikonla
              // üst üste iki tutamak görünüyor, üstelik elle eklenen olan
              // hiçbir listener'a sarılı olmadığı için çalışmıyordu.
              buildDefaultDragHandles: false,
              onReorder: (eski, yeni) => setState(() {
                _kirli = true;
                if (yeni > eski) yeni--;
                final k = _kalemler.removeAt(eski);
                _kalemler.insert(yeni, k);
              }),
              itemBuilder: (context, i) {
                final k = _kalemler[i];
                return Card(
                  key: ValueKey(k.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    onTap: () => _kalemDuzenle(mevcut: k, index: i),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppTema.ana50, borderRadius: BorderRadius.circular(10)),
                      child: Icon(kalemIkonu(k.ikon), color: AppTema.ana, size: 22),
                    ),
                    title: Text(k.ad, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(k.tip == KalemTipi.sayac ? 'Sayaç' : 'Günlük ✓/✗',
                        style: const TextStyle(color: AppTema.metinIkincil, fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                        tooltip: 'Kalemi sil',
                        onPressed: () => setState(() {
                          _kirli = true;
                          _kalemler.removeAt(i);
                        }),
                      ),
                      // Tek ve gerçekten sürükleyen tutamak.
                      Semantics(
                        label: '${k.ad} sırasını değiştirmek için basılı tutup sürükle',
                        excludeSemantics: true,
                        child: ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            child: Icon(Icons.drag_handle_rounded, color: AppTema.metinIkincil),
                          ),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTema.ana,
        foregroundColor: Colors.white,
        onPressed: () => _kalemDuzenle(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kalem Ekle'),
      ),
    );
  }
}
