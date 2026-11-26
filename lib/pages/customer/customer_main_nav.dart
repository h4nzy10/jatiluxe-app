import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../login.dart';

class CustomerMainNav extends StatelessWidget {
  const CustomerMainNav({super.key});

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        title: const TText('J A T I L U X E'),
        actions: [
          const LanguageSwitcher(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.ashGrey),
            tooltip: 'Keluar'.tr(context),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.weekend_outlined,
              size: 56,
              color: AppColors.champagneGold,
            ),
            const SizedBox(height: 16),
            const TText(
              'Katalog JatiLuxe',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            const TText(
              'Storefront Pelanggan siap dibangun',
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
