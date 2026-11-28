import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import '../constants/theme.dart';
import '../service/api.dart';
import 'customer/customer_main_nav.dart';
import 'seller/seller_main_nav.dart';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  static const int _maxAttempts = 5;
  static const Duration _lockDuration = Duration(seconds: 30);

  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isLocked =>
      _lockedUntil != null && DateTime.now().isBefore(_lockedUntil!);

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLocked) {
      _showErrorSnackBar(
        'Login ditunda karena terlalu banyak percobaan gagal. Coba lagi dalam $_remainingSeconds detik.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/api/v1/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });

      if (!mounted) return;

      final token = response['token'];
      if (token == null || token.toString().isEmpty) {
        throw Exception('Token not found from server.');
      }

      await ApiService.saveToken(token);

      // Fetch user profile to determine role
      final profileResponse = await ApiService.get('/api/v1/profile');

      if (!mounted) return;

      _failedAttempts = 0;
      _lockedUntil = null;

      final user = profileResponse['user'];
      final role = user?['role']?.toString().toLowerCase();

      if (role == 'seller' || role == '2') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SellerMainNav()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerMainNav()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      _handleFailedLogin(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleFailedLogin(String message) {
    final isRateLimited = message.contains('Terlalu banyak percobaan') ||
        message.contains('429');

    if (isRateLimited) {
      final parsedSeconds = int.tryParse(
            RegExp(r'(\d+) detik').firstMatch(message)?.group(1) ?? '',
          ) ??
          _lockDuration.inSeconds;
      _startLock(seconds: parsedSeconds);
      _showErrorSnackBar(message);
      return;
    }

    final isCredentialError = message.contains('Login failed') ||
        message.contains('kata sandi') ||
        message.contains('salah');

    if (!isCredentialError) {
      _showErrorSnackBar(message);
      return;
    }

    _failedAttempts += 1;

    if (_failedAttempts >= _maxAttempts) {
      _startLock();
      _showErrorSnackBar(
        'Terlalu banyak kata sandi salah. Login ditunda selama ${_lockDuration.inSeconds} detik.',
      );
      return;
    }

    _showErrorSnackBar(
      'Email atau kata sandi salah. ${_maxAttempts - _failedAttempts} percobaan tersisa.',
    );
  }

  void _startLock({int? seconds}) {
    if (!mounted) return;
    final lockSeconds = seconds ?? _lockDuration.inSeconds;
    _lockedUntil = DateTime.now().add(Duration(seconds: lockSeconds));
    _remainingSeconds = lockSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final left = _lockedUntil!.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        timer.cancel();
        _countdownTimer = null;
        setState(() {
          _lockedUntil = null;
          _remainingSeconds = 0;
          _failedAttempts = 0;
        });
        return;
      }

      setState(() => _remainingSeconds = left);
    });
    setState(() {});
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TText(
                message,
                style: const TextStyle(
                  color: AppColors.ivorySilk,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Align(
                    alignment: Alignment.topRight,
                    child: LanguageSwitcher(),
                  ),
                  const SizedBox(height: 8),
                  // Subtle top brand mark
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 44,
                      height: 44,
                      errorBuilder: (_, _, _) => CustomPaint(
                        size: const Size(38, 38),
                        painter: _ArtisanMiniMark(color: AppColors.champagneGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: TText(
                      'JatiLuxe',
                      style: TextStyle(
                        color: AppColors.champagneGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 5.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Heading
                  const TText(
                    'Welcome Back',
                    style: TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const TText(
                    'Log in to explore the finest wood furniture',
                    style: TextStyle(
                      color: AppColors.ashGrey,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email Field
                  const TText(
                    'Email',
                    style: TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                    cursorColor: AppColors.champagneGold,
                    decoration: const InputDecoration(
                      hintText: 'example@email.com',
                      prefixIcon: Icon(
                        Icons.alternate_email_rounded,
                        color: AppColors.ashGreySubtle,
                        size: 18,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Email is invalid';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password Field
                  const TText(
                    'Password',
                    style: TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                    cursorColor: AppColors.champagneGold,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.ashGreySubtle,
                        size: 18,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.ashGreySubtle,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isLocked ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.champagneGold,
                        foregroundColor: AppColors.obsidianBlack,
                        disabledBackgroundColor:
                            AppColors.champagneGold.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.obsidianBlack,
                                ),
                              ),
                            )
                          : TText(
                              _isLocked ? 'Tunggu $_remainingSeconds detik' : 'Login',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),

                  if (_isLocked)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TText(
                        'Terlalu banyak percobaan gagal. Login kembali dalam $_remainingSeconds detik.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else if (_failedAttempts > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TText(
                        'Percobaan gagal: $_failedAttempts/$_maxAttempts',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _failedAttempts >= _maxAttempts - 1
                              ? AppColors.warning
                              : AppColors.ashGrey,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TText(
                        'Don\'t have account? ',
                        style: TextStyle(
                          color: AppColors.ashGrey,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const TText(
                          'Register Now',
                          style: TextStyle(
                            color: AppColors.champagneGoldLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArtisanMiniMark extends CustomPainter {
  final Color color;

  _ArtisanMiniMark({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.5)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.5)
      ..close();
    canvas.drawPath(path, paint);

    canvas.drawLine(
      Offset(w * 0.35, h * 0.5),
      Offset(w * 0.65, h * 0.5),
      paint..strokeWidth = 1.0,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.35),
      Offset(w * 0.5, h * 0.65),
      paint..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant _ArtisanMiniMark oldDelegate) =>
      oldDelegate.color != color;
}
