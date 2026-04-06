import '../tema.dart';
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfilEkrani extends StatefulWidget {
  /// true ise ilk kayıt akışı (geri tuşu yok, zorunlu doldurma)
  final bool ilkKayit;
  const ProfilEkrani({super.key, this.ilkKayit = false});

  @override
  State<ProfilEkrani> createState() => _ProfilEkraniState();
}

class _ProfilEkraniState extends State<ProfilEkrani> {
  final _db = FirestoreService(uid: AuthService().uid);
  final _adCtrl = TextEditingController();
  final _okulCtrl = TextEditingController();
  final _sehirCtrl = TextEditingController();
  String _brans = 'Beden Eğitimi';
  bool _yukleniyor = true;
  bool _kaydediliyor = false;

  static const _branslar = [
    'Beden Eğitimi',
    'Matematik',
    'Fen Bilimleri',
    'Türkçe',
    'Sosyal Bilgiler',
    'İngilizce',
    'Müzik',
    'Görsel Sanatlar',
    'Teknoloji ve Tasarım',
    'Din Kültürü',
    'Rehberlik',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _profilYukle();
  }

  Future<void> _profilYukle() async {
    final data = await _db.profilGetir();
    if (data != null && mounted) {
      _adCtrl.text = data['ad'] ?? '';
      _okulCtrl.text = data['okul'] ?? '';
      _sehirCtrl.text = data['sehir'] ?? '';
      _brans = data['brans'] ?? 'Beden Eğitimi';
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _kaydet() async {
    if (_adCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Lütfen adınızı girin."),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _kaydediliyor = true);
    await _db.profilKaydet({
      'ad': _adCtrl.text.trim(),
      'okul': _okulCtrl.text.trim(),
      'sehir': _sehirCtrl.text.trim(),
      'brans': _brans,
      'email': AuthService().currentUser?.email ?? '',
    });

    if (widget.ilkKayit) {
      AnalyticsService.profilTamamlandi(sehir: _sehirCtrl.text.trim(), brans: _brans);
    }

    if (mounted) {
      setState(() => _kaydediliyor = false);
      if (widget.ilkKayit) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Profil kaydedildi."),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _okulCtrl.dispose();
    _sehirCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.ilkKayit,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: AppTema.ana,
          foregroundColor: Colors.white,
          title: Text(widget.ilkKayit ? "Profilini Tamamla" : "Profilim",
              style: const TextStyle(fontWeight: FontWeight.w800)),
          centerTitle: true,
          automaticallyImplyLeading: !widget.ilkKayit,
        ),
        body: _yukleniyor
            ? const Center(child: CircularProgressIndicator(color: AppTema.ana))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.ilkKayit) ...[
                      const Text("Hosgeldin!",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text("Seni daha iyi tanıyalım.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      const SizedBox(height: 28),
                    ],
                    _buildField("Ad Soyad *", _adCtrl, Icons.person_rounded),
                    const SizedBox(height: 16),
                    _buildField("Okul", _okulCtrl, Icons.school_rounded),
                    const SizedBox(height: 16),
                    _buildField("Sehir", _sehirCtrl, Icons.location_city_rounded),
                    const SizedBox(height: 16),
                    Text("Brans", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButton<String>(
                        value: _brans,
                        isExpanded: true,
                        underline: const SizedBox(),
                        borderRadius: BorderRadius.circular(14),
                        items: _branslar.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (val) => setState(() => _brans = val!),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTema.ana,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: _kaydediliyor ? null : _kaydet,
                        child: _kaydediliyor
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text("Kaydet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    if (!widget.ilkKayit) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              AuthService().currentUser?.email ?? '',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              'UID: ${AuthService().uid}',
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTema.anaAcik, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTema.ana, width: 2)),
          ),
        ),
      ],
    );
  }
}
