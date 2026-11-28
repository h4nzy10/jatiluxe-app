import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';

import '../../constants/theme.dart';
import '../../service/api.dart';
import '../login.dart';
import 'customer_catalog_page.dart';
import 'customer_checkout_page.dart';
import 'customer_cart_page.dart';
import 'customer_orders_page.dart';
import 'customer_product_detail_page.dart';
import 'customer_profile_page.dart';

class CustomerMainNav extends StatefulWidget {
  const CustomerMainNav({super.key});

  @override
  State<CustomerMainNav> createState() => _CustomerMainNavState();
}

class _CustomerMainNavState extends State<CustomerMainNav> {
  int _selectedIndex = 0;
  int _cartCount = 0;
  final GlobalKey<CustomerOrdersPageState> _ordersKey =
      GlobalKey<CustomerOrdersPageState>();

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
    if (index == 2) {
      _ordersKey.currentState?.refresh();
    }
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
            onProductSelected: (product) =>
                _openProductDetail(context, product),
            onLogout: () => _logout(context),
          ),
          CustomerCartPage(
            onProductSelected: (product) =>
                _openProductDetail(context, product),
            onBrowseCatalog: () => _onTabTapped(0),
            onCartChanged: () => _refreshCartCount(),
            onCheckout: (selectedCartIds, total, items) =>
                _openCheckoutFromCart(context, selectedCartIds, items),
          ),
          CustomerOrdersPage(
            key: _ordersKey,
            onBrowseCatalog: () => _onTabTapped(0),
          ),
          const CustomerProfilePage(),
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
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long_rounded),
            label: 'Pesanan'.tr(context),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'Profil'.tr(context),
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
          onBuyNow: (product, quantity) => _openCheckout(
            context,
            [
              <String, dynamic>{...product, 'quantity': quantity},
            ],
            quantity: quantity,
          ),
        ),
      ),
    );
    if (!mounted) return;
    await _refreshCartCount();
  }

  Future<void> _openCheckout(
    BuildContext context,
    List<Map<String, dynamic>> items, {
    int quantity = 1,
    String? initialAddress,
    String sourceLabel = 'Produk',
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          items: items,
          initialAddress: initialAddress,
          sourceLabel: sourceLabel,
          onOrderCreated: () => _refreshCartCount(),
        ),
      ),
    );
    if (!mounted) return;
    await _refreshCartCount();
  }

  Future<void> _openCheckoutFromCart(
    BuildContext context,
    List<int> selectedCartIds,
    List<Map<String, dynamic>> items,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          items: items,
          selectedCartIds: selectedCartIds,
          sourceLabel: 'Keranjang',
          onOrderCreated: () => _refreshCartCount(),
        ),
      ),
    );
    if (!mounted) return;
    await _refreshCartCount();
  }
}
