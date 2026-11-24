import 'package:flutter/material.dart';
import 'constants/theme.dart';
import 'service/api.dart';
import 'pages/splash.dart';
import 'pages/login.dart';
import 'pages/customer/customer_main_nav.dart';
import 'pages/seller/seller_main_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JatiLuxe());
}

class JatiLuxe extends StatelessWidget {
  const JatiLuxe({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JatiLuxe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

/// AuthGate checks the stored JWT token and routes the user
/// to the appropriate dashboard or splash/login flow.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<Widget> _authCheckFuture;

  @override
  void initState() {
    super.initState();
    _authCheckFuture = _checkJwtToken();
  }

  Future<Widget> _checkJwtToken() async {
    try {
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        return const SplashPage();
      }

      final profileRes = await ApiService.get('/api/v1/profile');

      if (profileRes != null && profileRes['user'] != null) {
        final user = profileRes['user'];
        final role = user['role']?.toString().toLowerCase();

        // Route based on role
        if (role == 'seller' || role == '2') {
          return const SellerMainNav();
        } else {
          return const CustomerMainNav();
        }
      }

      await ApiService.logout();
      return const LoginPage();
    } catch (_) {
      return const SplashPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _authCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return snapshot.data!;
        }

        // Luxury obsidian loading canvas (prevents white screen flash)
        return const Scaffold(
          backgroundColor: AppColors.obsidianBlack,
          body: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.champagneGold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
