import 'package:flutter/material.dart';
import '../tema.dart';

/// Her ekranın app bar'ına eklenebilen yardım dialogu.
///
/// Kullanım:
/// ```dart
/// AppBar(
///   actions: [
///     IconButton(
///       icon: const Icon(Icons.help_outline_rounded),
///       onPressed: () => YardimDiyalogu.goster(
///         context,
///         baslik: 'Sınıflarım',
///         bolumler: [
///           YardimBolumu(
///             ikon: Icons.add_circle_outline,
///             baslik: 'Yeni sınıf oluştur',
///             aciklama: '...',
///           ),
///         ],
///       ),
///     ),
///   ],
/// )
/// ```
class YardimDiyalogu extends StatelessWidget {
  final String baslik;
  final List<YardimBolumu> bolumler;

  const YardimDiyalogu({
    super.key,
    required this.baslik,
    required this.bolumler,
  });

  static Future<void> goster(
    BuildContext context, {
    required String baslik,
    required List<YardimBolumu> bolumler,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => YardimDiyalogu(baslik: baslik, bolumler: bolumler),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Sürükleme tutamacı
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Başlık
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: AppTema.ana, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      baslik,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Kapat',
                    color: AppTema.metinIkincil,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade200),
            // İçerik
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: bolumler.length,
                separatorBuilder: (_, _) => const SizedBox(height: 18),
                itemBuilder: (_, i) => _BolumKart(bolum: bolumler[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class YardimBolumu {
  final IconData ikon;
  final String baslik;
  final String aciklama;
  final Color? renk;

  const YardimBolumu({
    required this.ikon,
    required this.baslik,
    required this.aciklama,
    this.renk,
  });
}

class _BolumKart extends StatelessWidget {
  final YardimBolumu bolum;
  const _BolumKart({required this.bolum});

  @override
  Widget build(BuildContext context) {
    final renk = bolum.renk ?? AppTema.ana;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: renk.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(bolum.ikon, color: renk, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bolum.baslik,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bolum.aciklama,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
