import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

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
      _showErrorSnackBar(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.error.withOpacity(0.6), width: 0.8),
        ),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
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
                  // Subtle top brand mark
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 44,
                      height: 44,
                      errorBuilder: (_, __, ___) => CustomPaint(
                        size: const Size(38, 38),
                        painter: _ArtisanMiniMark(color: AppColors.champagneGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'J A T I L U X E',
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
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Log in to explore the best teak furniture works',
                    style: TextStyle(
                      color: AppColors.ashGrey,
                      fontSize: 13,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email Field
                  const Text(
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
                  const Text(
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
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.champagneGold,
                        foregroundColor: AppColors.obsidianBlack,
                        disabledBackgroundColor: AppColors.champagneGold.withOpacity(0.4),
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
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
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
                        child: const Text(
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
