import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import '../constants/theme.dart';
import '../service/api.dart';
import 'login.dart';
import 'customer/customer_main_nav.dart';
import 'seller/seller_main_nav.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _lineAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _checkSession();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _lineAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.forward();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    try {
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        _navigateToLogin();
        return;
      }

      final response = await ApiService.get('/api/v1/profile');

      if (!mounted) return;

      if (response != null && response['user'] != null) {
        final user = response['user'];
        final role = user['role']?.toString().toLowerCase();

        if (role == 'seller' || role == '2') {
          _navigateToSellerHome();
        } else {
          _navigateToCustomerHome();
        }
      } else {
        await ApiService.logout();
        _navigateToLogin();
      }
    } catch (_) {
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const LoginPage(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToCustomerHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const CustomerMainNav(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToSellerHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const SellerMainNav(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: Stack(
          children: [
            // Centerpiece: Understated luxury typographic branding
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo (loads assets/images/logo.png if provided, otherwise falls back to artisan mark)
                    Image.asset(
                      'assets/images/logo.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return CustomPaint(
                          size: const Size(44, 44),
                          painter: _ArtisanMarkPainter(
                            color: AppColors.champagneGold,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Main Brand Wordmark
                    const TText(
                      'JatiLuxe',
                      style: TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 9.0,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Natural, quiet tagline
                    const TText(
                      'Wooden Furniture',
                      style: TextStyle(
                        color: AppColors.ashGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.5,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Minimalist hairline loading indicator
                    SizedBox(
                      width: 50,
                      height: 1.5,
                      child: AnimatedBuilder(
                        animation: _lineAnimation,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 50 * _lineAnimation.value,
                              height: 1.5,
                              color: AppColors.warmBronze,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Subtle, authentic origin mark at the bottom
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Center(
                  child: TText(
                    'JatiLuxe',
                    style: TextStyle(
                      color: AppColors.ashGreySubtle,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 3.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A clean, geometric wood joinery mark inspired by traditional teak mortise & tenon woodwork
class _ArtisanMarkPainter extends CustomPainter {
  final Color color;

  _ArtisanMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;

    // Outer subtle diamond / architectural frame
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.5)
      ..close();
    canvas.drawPath(path, paint);

    // Inner minimalist wood grain / joinery lines
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(w * 0.35, h * 0.5),
      Offset(w * 0.65, h * 0.5),
      innerPaint,
    );

    canvas.drawLine(
      Offset(w * 0.5, h * 0.35),
      Offset(w * 0.5, h * 0.65),
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArtisanMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
