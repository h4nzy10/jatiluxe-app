import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/theme.dart';

/// Persists the seller onboarding status locally.
class SellerOnboarding {
  static const String _completedKey = 'seller_onboarding_completed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}

class SellerOnboardingPage extends StatefulWidget {
  const SellerOnboardingPage({super.key});

  @override
  State<SellerOnboardingPage> createState() => _SellerOnboardingPageState();
}

class _SellerOnboardingPageState extends State<SellerOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingStep> _steps = [
    _OnboardingStep(
      icon: Icons.dashboard_rounded,
      eyebrow: 'LANGKAH 1 DARI 4',
      title: 'Kenali Ruang Kendali Toko',
      description:
          'Ringkasan menampilkan pendapatan, jumlah pesanan, dan kondisi etalase Anda dalam satu tampilan.',
      hints: [
        'Pantau total pendapatan terverifikasi',
        'Cek koleksi aktif dan total stok kayu',
        'Gunakan ringkasan untuk melihat pesanan terbaru',
      ],
    ),
    _OnboardingStep(
      icon: Icons.inventory_2_rounded,
      eyebrow: 'LANGKAH 2 DARI 4',
      title: 'Bangun Etalase Berkualitas',
      description:
          'Tambah karya jati maupun kayu pilihan lain lengkap dengan foto, kategori, spesifikasi, harga, dan stok.',
      hints: [
        'Gunakan foto dengan pencahayaan alami',
        'Isi dimensi dan teknik finishing di deskripsi',
        'Perbarui harga dan stok secara berkala',
      ],
    ),
    _OnboardingStep(
      icon: Icons.local_shipping_rounded,
      eyebrow: 'LANGKAH 3 DARI 4',
      title: 'Kelola Pengiriman sampai Selesai',
      description:
          'Temukan pesanan pada tab Logistik, lalu awalui status pengiriman dan verifikasi bukti penerimaan pelanggan.',
      hints: [
        'Tandai pesanan menjadi "Dikirim" saat barang keluar',
        'Lihat foto bukti yang diunggah pelanggan',
        'Selesaikan transaksi setelah bukti terverifikasi',
      ],
    ),
    _OnboardingStep(
      icon: Icons.storefront_rounded,
      eyebrow: 'LANGKAH 4 DARI 4',
      title: 'Rapikan Identitas Workshop',
      description:
          'Lengkapi profil dan foto workshop agar pembeli mengenal pengrajin di balik setiap karya.',
      hints: [
        'Isi nama, email, telepon, dan alamat galeri',
        'Ganti kata sandi hanya dengan kata sandi saat ini',
        'Buka panduan ini kapan saja dari ikon bantuan',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _finish();
  }

  Future<void> _finish() async {
    await SellerOnboarding.markCompleted();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _steps.length - 1;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const TText(
                      'LEWATI',
                      style: TextStyle(
                        color: AppColors.ashGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TText(
                    '${_currentPage + 1}/${_steps.length}',
                    style: const TextStyle(
                      color: AppColors.ashGreySubtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: List.generate(_steps.length, (i) {
                  final active = i <= _currentPage;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: i == _steps.length - 1 ? 0 : 6,
                      ),
                      height: 3,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.champagneGold
                            : AppColors.surfaceBorder,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) =>
                    _buildStepContent(_steps[index], index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
                      child: const TText(
                        'Sebelumnya',
                        style: TextStyle(
                          color: AppColors.ashGrey,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.champagneGold,
                        foregroundColor: AppColors.obsidianBlack,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _nextPage,
                      child: TText(
                        isLast ? 'Mulai Berjualan' : 'Lanjut',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(_OnboardingStep step, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SizedBox(
              width: 260,
              height: 174,
              child: CustomPaint(
                painter: _OnboardingArtPainter(step: index),
                child: Center(
                  child: Icon(
                    step.icon,
                    size: 22,
                    color: AppColors.champagneGold.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          TText(
            step.eyebrow,
            style: const TextStyle(
              color: AppColors.warmBronze,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          TText(
            step.title,
            style: const TextStyle(
              color: AppColors.ivorySilk,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          TText(
            step.description,
            style: const TextStyle(
              color: AppColors.ashGrey,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          ...step.hints.map(
            (hint) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TText(
                      hint,
                      style: const TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> hints;

  const _OnboardingStep({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.hints,
  });
}

/// Lightweight vector-style scene drawn with Flutter primitives so the
/// tutorial stays sharp on every screen and needs no external assets.
class _OnboardingArtPainter extends CustomPainter {
  final int step;

  const _OnboardingArtPainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.charcoalVelvet, AppColors.surfaceElevated],
        ).createShader(rect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      _stroke(AppColors.surfaceBorder, 0.8),
    );

    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.18),
      52,
      _fill(AppColors.champagneGold.withValues(alpha: 0.06)),
    );
    _drawWoodGrain(canvas, size);

    switch (step) {
      case 0:
        _drawDashboard(canvas, size);
        break;
      case 1:
        _drawInventory(canvas, size);
        break;
      case 2:
        _drawLogistics(canvas, size);
        break;
      default:
        _drawProfile(canvas, size);
    }
  }

  Paint _fill(Color color) => Paint()..color = color;

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _drawWoodGrain(Canvas canvas, Size size) {
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.12 + i * 0.15);
      final path = Path()
        ..moveTo(-10, y)
        ..cubicTo(
          size.width * 0.3,
          y - 12,
          size.width * 0.6,
          y + 14,
          size.width + 10,
          y - 4,
        );
      canvas.drawPath(
        path,
        _stroke(AppColors.warmBronze.withValues(alpha: 0.12), 1),
      );
    }
  }

  void _card(Canvas canvas, Rect rect) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(9));
    canvas.drawRRect(rrect, _fill(AppColors.obsidianBlack.withValues(alpha: 0.55)));
    canvas.drawRRect(rrect, _stroke(AppColors.surfaceBorder, 0.8));
  }

  void _drawDashboard(Canvas canvas, Size size) {
    _card(canvas, const Rect.fromLTWH(16, 30, 92, 96));
    final bars = [30.0, 48.0, 36.0, 58.0];
    for (var i = 0; i < bars.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(30 + i * 18, 116 - bars[i], 10, bars[i]),
          const Radius.circular(3),
        ),
        _fill(
          i == bars.length - 1
              ? AppColors.champagneGold
              : AppColors.warmBronze.withValues(alpha: 0.75),
        ),
      );
    }

    _card(canvas, const Rect.fromLTWH(122, 40, 120, 66));
    final line = Path()
      ..moveTo(134, 90)
      ..lineTo(154, 76)
      ..lineTo(174, 84)
      ..lineTo(196, 58)
      ..lineTo(230, 66);
    canvas.drawPath(line, _stroke(AppColors.champagneGold, 2));
    for (final p in [
      const Offset(134, 90),
      const Offset(154, 76),
      const Offset(174, 84),
      const Offset(196, 58),
      const Offset(230, 66),
    ]) {
      canvas.drawCircle(p, 3, _fill(AppColors.champagneGoldLight));
    }

    _card(canvas, const Rect.fromLTWH(140, 118, 102, 30));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(150, 127, 44, 12),
        const Radius.circular(6),
      ),
      _fill(AppColors.champagneGold.withValues(alpha: 0.45)),
    );
  }

  void _drawInventory(Canvas canvas, Size size) {
    _card(canvas, const Rect.fromLTWH(20, 30, 58, 62));
    canvas.drawCircle(
      const Offset(63, 47),
      6,
      _fill(AppColors.champagneGold.withValues(alpha: 0.7)),
    );
    final mountain = Path()
      ..moveTo(26, 82)
      ..lineTo(44, 60)
      ..lineTo(56, 74)
      ..lineTo(66, 64)
      ..lineTo(72, 82)
      ..close();
    canvas.drawPath(mountain, _stroke(AppColors.warmBronze, 1.5));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 136, 184, 12),
        const Radius.circular(4),
      ),
      _fill(AppColors.surfaceElevated),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(96, 86, 64, 11),
        const Radius.circular(3),
      ),
      _fill(AppColors.champagneGold.withValues(alpha: 0.85)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(100, 44, 56, 40),
        const Radius.circular(4),
      ),
      _fill(AppColors.warmBronze.withValues(alpha: 0.5)),
    );
    canvas.drawLine(
      const Offset(102, 97),
      const Offset(96, 136),
      _stroke(AppColors.champagneGold, 3),
    );
    canvas.drawLine(
      const Offset(154, 97),
      const Offset(160, 136),
      _stroke(AppColors.champagneGold, 3),
    );

    _card(canvas, const Rect.fromLTWH(188, 96, 52, 28));
    canvas.drawCircle(
      const Offset(200, 110),
      4,
      _fill(AppColors.champagneGold),
    );
    canvas.drawLine(
      const Offset(210, 110),
      const Offset(232, 110),
      _stroke(AppColors.warmBronze, 2),
    );
  }

  void _drawLogistics(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(24, 138)
      ..lineTo(96, 118)
      ..lineTo(168, 82)
      ..lineTo(232, 54);
    canvas.drawPath(route, _stroke(AppColors.warmBronze.withValues(alpha: 0.6), 2));
    for (final p in [
      const Offset(24, 138),
      const Offset(96, 118),
      const Offset(168, 82),
      const Offset(232, 54),
    ]) {
      canvas.drawCircle(p, 5, _fill(AppColors.champagneGold));
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 72, 104, 50),
        const Radius.circular(6),
      ),
      _fill(AppColors.surfaceElevated),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(44, 72, 104, 50),
        const Radius.circular(6),
      ),
      _stroke(AppColors.surfaceBorder, 0.8),
    );
    final cabin = Path()
      ..moveTo(148, 88)
      ..lineTo(188, 88)
      ..lineTo(204, 110)
      ..lineTo(148, 110)
      ..close();
    canvas.drawPath(cabin, _fill(AppColors.warmBronze.withValues(alpha: 0.6)));
    for (final x in [70.0, 182.0]) {
      canvas.drawCircle(Offset(x, 124), 10, _fill(AppColors.obsidianBlack));
      canvas.drawCircle(
        Offset(x, 124),
        10,
        _stroke(AppColors.champagneGold, 1.5),
      );
    }

    _card(canvas, const Rect.fromLTWH(172, 16, 68, 46));
    final check = Path()
      ..moveTo(186, 40)
      ..lineTo(196, 50)
      ..lineTo(216, 30);
    canvas.drawPath(check, _stroke(AppColors.success, 2.5));
  }

  void _drawProfile(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(46, 56, 168, 94),
        const Radius.circular(8),
      ),
      _fill(AppColors.surfaceElevated),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(46, 56, 168, 94),
        const Radius.circular(8),
      ),
      _stroke(AppColors.surfaceBorder, 0.8),
    );

    for (var i = 0; i < 6; i++) {
      canvas.drawRect(
        Rect.fromLTWH(46 + i * 28, 38, 28, 20),
        _fill(
          i.isEven
              ? AppColors.champagneGold.withValues(alpha: 0.55)
              : AppColors.warmBronze.withValues(alpha: 0.55),
        ),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(112, 96, 36, 54),
        const Radius.circular(3),
      ),
      _fill(AppColors.obsidianBlack.withValues(alpha: 0.6)),
    );
    canvas.drawCircle(
      const Offset(130, 76),
      15,
      _fill(AppColors.champagneGold.withValues(alpha: 0.25)),
    );
    canvas.drawCircle(
      const Offset(130, 72),
      5,
      _fill(AppColors.champagneGoldLight),
    );
    canvas.drawLine(
      const Offset(120, 88),
      const Offset(140, 88),
      _stroke(AppColors.champagneGoldLight, 2),
    );

    _card(canvas, const Rect.fromLTWH(190, 112, 44, 34));
    final shackle = Path()
      ..moveTo(201, 118)
      ..quadraticBezierTo(201, 107, 212, 107)
      ..quadraticBezierTo(223, 107, 223, 118);
    canvas.drawPath(shackle, _stroke(AppColors.champagneGold, 2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(199, 118, 26, 18),
        const Radius.circular(4),
      ),
      _fill(AppColors.champagneGold.withValues(alpha: 0.35)),
    );
  }

  @override
  bool shouldRepaint(covariant _OnboardingArtPainter oldDelegate) =>
      oldDelegate.step != step;
}
