import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../login.dart';
import 'seller_dashboard_page.dart';
import 'seller_delivery_page.dart';
import 'seller_inventory_page.dart';
import 'seller_onboarding_page.dart';
import 'seller_profile_page.dart';

class SellerMainNav extends StatefulWidget {
  const SellerMainNav({super.key});

  @override
  State<SellerMainNav> createState() => _SellerMainNavState();
}

class _SellerMainNavState extends State<SellerMainNav> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showOnboardingIfNeeded(),
    );
  }

  Future<void> _showOnboardingIfNeeded() async {
    final completed = await SellerOnboarding.isCompleted();
    if (!mounted || completed) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SellerOnboardingPage()),
    );
  }

  void _openOnboarding() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellerOnboardingPage()),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        title: const TText(
          'Keluar dari Toko',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const TText(
          'Apakah Anda yakin ingin mengakhiri sesi merchant ini?',
          style: TextStyle(
            color: AppColors.ashGrey,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TText(
              'Batal',
              style: TextStyle(color: AppColors.ashGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.ivorySilk,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const TText('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildShell(context));
  }

  Widget _buildShell(BuildContext context) {
    final List<Widget> pages = [
      SellerDashboardPage(
        onNavigateToInventory: () => _onTabTapped(1),
        onNavigateToDelivery: () => _onTabTapped(2),
      ),
      const SellerInventoryPage(),
      const SellerDeliveryPage(),
      SellerProfilePage(
        onNavigateToInventory: () => _onTabTapped(1),
        onOpenOnboarding: _openOnboarding,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        title: TText(
          _getAppBarTitle(_currentIndex),
          style: const TextStyle(
            letterSpacing: 2.0,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          const LanguageSwitcher(),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded,
                color: AppColors.ashGrey, size: 20),
            tooltip: 'Panduan Toko'.tr(context),
            onPressed: _openOnboarding,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.ashGrey, size: 20),
            tooltip: 'Keluar'.tr(context),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.charcoalVelvet,
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: AppColors.charcoalVelvet,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedItemColor: AppColors.champagneGold,
          unselectedItemColor: AppColors.ashGreySubtle,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard_rounded),
              label: 'Ringkasan'.tr(context),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined),
              activeIcon: const Icon(Icons.inventory_2_rounded),
              label: 'Inventaris'.tr(context),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.local_shipping_outlined),
              activeIcon: const Icon(Icons.local_shipping_rounded),
              label: 'Logistik'.tr(context),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.storefront_outlined),
              activeIcon: const Icon(Icons.storefront_rounded),
              label: 'Profil Toko'.tr(context),
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'MERCHANT SUITE';
      case 1:
        return 'INVENTARIS KATALOG';
      case 2:
        return 'LOGISTIK & PENGIRIMAN';
      case 3:
        return 'PROFIL TOKO';
      default:
        return 'JATILUXE';
    }
  }

}
