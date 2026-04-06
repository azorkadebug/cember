import '../tema.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEkrani extends StatefulWidget {
  const AdminEkrani({super.key});

  @override
  State<AdminEkrani> createState() => _AdminEkraniState();
}

class _AdminEkraniState extends State<AdminEkrani> {
  List<Map<String, dynamic>> _kullanicilar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  String? _hata;

  Future<void> _yukle() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      _kullanicilar = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      _hata = null;
    } catch (e) {
      _hata = e.toString();
    }
    if (mounted) setState(() => _yukleniyor = false);
  }

  Map<String, int> _grupla(String alan) {
    final sayac = <String, int>{};
    for (var k in _kullanicilar) {
      final deger = (k[alan] ?? '').toString().trim();
      if (deger.isEmpty) continue;
      sayac[deger] = (sayac[deger] ?? 0) + 1;
    }
    // Çoktan aza sırala
    final sirali = sayac.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sirali);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: AppTema.ana))
          : _hata != null
          ? Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text("Hata: $_hata", style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
            ))
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _yukleniyor = true);
                await _yukle();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Özet kartı
                  _ozetKarti(),
                  const SizedBox(height: 16),
                  // Okul dağılımı
                  _dagilimKarti('Okullar', 'okul', Icons.school_rounded),
                  const SizedBox(height: 12),
                  // Şehir dağılımı
                  _dagilimKarti('Şehirler', 'sehir', Icons.location_city_rounded),
                  const SizedBox(height: 12),
                  // Branş dağılımı
                  _dagilimKarti('Branşlar', 'brans', Icons.category_rounded),
                  const SizedBox(height: 12),
                  // Kullanıcı listesi
                  _kullaniciListesi(),
                ],
              ),
            ),
    );
  }

  Widget _ozetKarti() {
    final okulSayisi = _grupla('okul').length;
    final sehirSayisi = _grupla('sehir').length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Genel Bakış', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _ozetItem(Icons.people_rounded, '${_kullanicilar.length}', 'Öğretmen'),
              _ozetItem(Icons.school_rounded, '$okulSayisi', 'Okul'),
              _ozetItem(Icons.location_city_rounded, '$sehirSayisi', 'Şehir'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ozetItem(IconData icon, String deger, String etiket) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white60, size: 24),
          const SizedBox(height: 6),
          Text(deger, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          Text(etiket, style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _dagilimKarti(String baslik, String alan, IconData icon) {
    final gruplar = _grupla(alan);
    if (gruplar.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTema.ana, size: 20),
              const SizedBox(width: 8),
              Text(baslik, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('${gruplar.length} farklı', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...gruplar.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTema.ana.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${e.value}', style: TextStyle(color: AppTema.ana, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _kullaniciListesi() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_rounded, color: AppTema.ana, size: 20),
              const SizedBox(width: 8),
              const Text('Tüm Öğretmenler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          ..._kullanicilar.map((k) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTema.ana.withAlpha(30),
                  radius: 18,
                  child: Text(
                    (k['ad'] ?? '?').toString().substring(0, 1).toUpperCase(),
                    style: TextStyle(color: AppTema.ana, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k['ad'] ?? 'İsimsiz', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        [k['okul'], k['sehir']].where((e) => e != null && e.toString().isNotEmpty).join(' • '),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(k['brans'] ?? '', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
