import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../login.dart';
import 'seller_dashboard_page.dart';
import 'seller_inventory_page.dart';

class SellerMainNav extends StatefulWidget {
  const SellerMainNav({super.key});

  @override
  State<SellerMainNav> createState() => _SellerMainNavState();
}

class _SellerMainNavState extends State<SellerMainNav> {
  int _currentIndex = 0;

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
        title: const Text(
          'Keluar dari Toko',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin mengakhiri sesi merchant ini?',
          style: TextStyle(
            color: AppColors.ashGrey,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
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
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      SellerDashboardPage(
        onNavigateToInventory: () => _onTabTapped(1),
        onNavigateToDelivery: () => _onTabTapped(2),
      ),
      const SellerInventoryPage(),
      _buildDeliveryPlaceholder(),
      _buildProfilePlaceholder(),
    ];

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_currentIndex),
          style: const TextStyle(
            letterSpacing: 2.0,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.ashGrey, size: 20),
            tooltip: 'Keluar',
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Ringkasan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Inventaris',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping_rounded),
              label: 'Logistik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront_rounded),
              label: 'Profil Toko',
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

  Widget _buildDeliveryPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.local_shipping_outlined,
              size: 52,
              color: AppColors.champagneGold,
            ),
            SizedBox(height: 16),
            Text(
              'Otorisasi & Logistik Pengiriman',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pembaruan status armada dan verifikasi bukti terima dari pembeli',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.storefront_outlined,
              size: 52,
              color: AppColors.champagneGold,
            ),
            SizedBox(height: 16),
            Text(
              'Profil Workshop & Galeri',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Identitas pengrajin, lokasi galeri, dan foto profil workshop',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
