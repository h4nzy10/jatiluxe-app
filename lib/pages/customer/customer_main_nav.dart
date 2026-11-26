import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../login.dart';
import 'customer_catalog_page.dart';
import 'customer_cart_page.dart';
import 'customer_product_detail_page.dart';

/// Customer shell with a persistent bottom navigation bar. Both tabs keep
/// their own AppBar; the shell owns tab switching and the cart badge count.
class CustomerMainNav extends StatefulWidget {
  const CustomerMainNav({super.key});

  @override
  State<CustomerMainNav> createState() => _CustomerMainNavState();
}

class _CustomerMainNavState extends State<CustomerMainNav> {
  int _selectedIndex = 0;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshCartCount();
  }

  Future<void> _refreshCartCount() async {
    try {
      final response = await ApiService.get('/api/v1/cart-list');
      if (!mounted) return;
      setState(() {
        _cartCount = response is Map && response['cart'] is List
            ? (response['cart'] as List).length
            : 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cartCount = 0);
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
    _refreshCartCount();
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CustomerCatalogPage(
            onProductSelected: (product) => _openProductDetail(context, product),
            onLogout: () => _logout(context),
          ),
          CustomerCartPage(
            onProductSelected: (product) => _openProductDetail(context, product),
            onBrowseCatalog: () => _onTabTapped(0),
            onCartChanged: () => _refreshCartCount(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        backgroundColor: AppColors.charcoalVelvet,
        selectedItemColor: AppColors.champagneGold,
        unselectedItemColor: AppColors.ashGreySubtle,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_outlined),
            label: 'Katalog'.tr(context),
          ),
          BottomNavigationBarItem(
            icon: Badge.count(
              count: _cartCount,
              isLabelVisible: _cartCount > 0,
              backgroundColor: AppColors.champagneGold,
              textStyle: const TextStyle(
                color: AppColors.obsidianBlack,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: 'Keranjang'.tr(context),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openProductDetail(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerProductDetailPage(
          productId: (product['id_product'] ?? '').toString(),
          initialProduct: product,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshCartCount();
  }
}
