import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../login.dart';

class SellerMainNav extends StatelessWidget {
  const SellerMainNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        title: const Text('MERCHANT SUITE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.ashGrey),
            tooltip: 'Keluar',
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
              Icons.storefront_outlined,
              size: 56,
              color: AppColors.champagneGold,
            ),
            const SizedBox(height: 16),
            const Text(
              'Dashboard Penjual',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ruang kendali mitra pengrajin & penjual',
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
