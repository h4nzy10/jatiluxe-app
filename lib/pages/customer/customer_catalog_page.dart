import 'package:flutter/material.dart';

import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../service/auto_refresh.dart';
import '../../service/l10n.dart';
import '../../utils/formatters.dart';

/// Customer storefront: an editorial, image-led catalog with instant search
/// and restrained category tabs.
class CustomerCatalogPage extends StatefulWidget {
  /// Called when a product card is tapped so the parent can open its detail.
  final void Function(Map<String, dynamic> product) onProductSelected;

  /// Optional logout action rendered in the catalog AppBar.
  final Future<void> Function()? onLogout;

  /// False while this tab is not visible, so it does not poll in the background.
  final bool isActive;

  const CustomerCatalogPage({
    super.key,
    required this.onProductSelected,
    this.onLogout,
    this.isActive = true,
  });

  @override
  State<CustomerCatalogPage> createState() => _CustomerCatalogPageState();
}

class _CustomerCatalogPageState extends State<CustomerCatalogPage>
    with AutoRefresh<CustomerCatalogPage> {
  @override
  bool get autoRefreshEnabled => widget.isActive;

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  List<String> _categoryFilters = ['Semua'];
  String _selectedCategoryFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchCatalog();
    startAutoRefresh(() => _fetchCatalog(silent: true));
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCatalog({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/products'),
        ApiService.get('/api/v1/categories').catchError((_) => null),
      ]);

      if (!mounted) return;

      final catRes = results[1];
      if (catRes != null && catRes['categories'] != null) {
        _categories = List<Map<String, dynamic>>.from(catRes['categories']);
        final names = _categories
            .map((c) => (c['category'] ?? '').toString())
            .where((name) => name.isNotEmpty)
            .toList();
        _categoryFilters = ['Semua', ...names];
      } else {
        _categoryFilters = ['Semua'];
      }

      final prodRes = results[0];
      _products = prodRes is Map && prodRes['products'] is List
          ? List<dynamic>.from(prodRes['products'] as List)
          : <dynamic>[];

      _applyFilter();
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted || silent) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      final isEmptyCatalog =
          message.toLowerCase().contains('empty') || message.contains('404');
      setState(() {
        if (isEmptyCatalog) {
          _products = [];
          _filteredProducts = [];
        } else {
          _errorMessage = message;
        }
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _products.where((item) {
        final product = _asMap(item);
        final name = (product['product_name'] ?? '').toString().toLowerCase();
        final wood = (product['wood_type'] ?? '').toString().toLowerCase();
        final category = (product['category'] ?? '').toString().toLowerCase();
        final seller = (product['seller'] ?? '').toString().toLowerCase();

        final matchesQuery =
            query.isEmpty ||
            name.contains(query) ||
            wood.contains(query) ||
            category.contains(query) ||
            seller.contains(query);

        final matchesCategory =
            _selectedCategoryFilter == 'Semua' ||
            category == _selectedCategoryFilter.trim().toLowerCase();

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  Map<String, dynamic>? get _featuredProduct =>
      _filteredProducts.isEmpty ? null : _asMap(_filteredProducts.first);

  List<Map<String, dynamic>> get _gridProducts {
    final products = _filteredProducts.map(_asMap).toList();
    return products.length > 1 ? products.sublist(1) : <Map<String, dynamic>>[];
  }

  String? _cleanImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    return clean.startsWith('http://')
        ? 'https://${clean.substring(7)}'
        : clean;
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 22,
        title: const TText(
          'JatiLuxe',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.4,
          ),
        ),
        actions: [
          const LanguageSwitcher(),
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Keluar'.tr(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.ashGrey),
              onPressed: () => widget.onLogout!(),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.surfaceBorder),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.champagneGold,
          backgroundColor: AppColors.charcoalVelvet,
          onRefresh: _fetchCatalog,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: _buildSlivers(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(BuildContext context) {
    final featured = _featuredProduct;
    final gridProducts = _gridProducts;

    return [
      SliverToBoxAdapter(child: _buildIntro()),
      SliverToBoxAdapter(child: _buildSearchField(context)),
      SliverToBoxAdapter(child: _buildCategoryTabs()),
      if (_isLoading)
        _buildStateSliver(_buildLoading())
      else if (_errorMessage != null)
        _buildStateSliver(_buildErrorView())
      else if (_filteredProducts.isEmpty)
        _buildStateSliver(_buildEmptyView())
      else ...[
        if (featured != null)
          SliverToBoxAdapter(child: _buildFeatured(context, featured)),
        if (gridProducts.isNotEmpty) ...[
          SliverToBoxAdapter(child: _buildSectionHeader()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 26,
                childAspectRatio: 0.58,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildProductTile(context, gridProducts[index]),
                childCount: gridProducts.length,
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 34)),
      ],
    ];
  }

  Widget _buildStateSliver(Widget child) {
    return SliverFillRemaining(hasScrollBody: false, child: child);
  }

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 26, height: 1, color: AppColors.champagneGold),
              const SizedBox(width: 10),
              const TText(
                'KOLEKSI JATILUXE',
                style: TextStyle(
                  color: AppColors.champagneGold,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const TText(
            'Koleksi Kayu',
            style: TextStyle(
              color: AppColors.ivorySilk,
              fontSize: 36,
              fontWeight: FontWeight.w300,
              height: 1.0,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 310),
            child: const TText(
              'Temukan karya kayu pilihan untuk rumah Anda',
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              TText(
                '${_filteredProducts.length} Desain',
                style: const TextStyle(
                  color: AppColors.champagneGoldLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Divider(color: AppColors.surfaceBorder, height: 1),
              ),
              const SizedBox(width: 12),
              const TText(
                'JATILUXE — 2026',
                style: TextStyle(
                  color: AppColors.ashGreySubtle,
                  fontSize: 8,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
        cursorColor: AppColors.champagneGold,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Cari furnitur, jenis kayu, atau kategori...'.tr(context),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.ashGreySubtle,
            size: 18,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.ashGreySubtle,
                  ),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.surfaceBorder, width: 0.8),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.surfaceBorder, width: 0.8),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.champagneGold, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        scrollDirection: Axis.horizontal,
        itemCount: _categoryFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          final category = _categoryFilters[index];
          final isSelected = _selectedCategoryFilter == category;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _selectedCategoryFilter = category);
              _applyFilter();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TText(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.ivorySilk
                        : AppColors.ashGreySubtle,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 7),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 16 : 0,
                  height: 1,
                  color: AppColors.champagneGold,
                ),
                const SizedBox(height: 4),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatured(BuildContext context, Map<String, dynamic> product) {
    final picture = _cleanImageUrl(product['picture']?.toString());
    final category = (product['category'] ?? '').toString();
    final wood = (product['wood_type'] ?? '').toString();
    final name = (product['product_name'] ?? '').toString();
    final price = product['price'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openProduct(context, product),
        child: AspectRatio(
          aspectRatio: 1.08,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag:
                      'customer-product-${(product['id_product'] ?? '').toString()}',
                  child: _buildNetworkImage(picture, iconSize: 32),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.obsidianBlack.withValues(alpha: 0.55),
                        AppColors.obsidianBlack,
                      ],
                      stops: const [0.35, 0.72, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 1,
                            color: AppColors.champagneGold,
                          ),
                          const SizedBox(width: 8),
                          const TText(
                            'KARYA PILIHAN',
                            style: TextStyle(
                              color: AppColors.champagneGold,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TText(
                              category.toUpperCase(),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ashGrey,
                                fontSize: 8,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TText(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ivorySilk,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            CurrencyFormat.toRupiah(price),
                            style: const TextStyle(
                              color: AppColors.champagneGoldLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TText(
                              wood,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ashGreySubtle,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.champagneGold.withValues(
                                  alpha: 0.7,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 15,
                              color: AppColors.champagneGold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 14),
      child: Row(
        children: [
          const TText(
            'Katalog JatiLuxe',
            style: TextStyle(
              color: AppColors.ivorySilk,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Divider(color: AppColors.surfaceBorder, height: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(BuildContext context, Map<String, dynamic> product) {
    final picture = _cleanImageUrl(product['picture']?.toString());
    final category = (product['category'] ?? '').toString();
    final wood = (product['wood_type'] ?? '').toString();
    final name = (product['product_name'] ?? '').toString();
    final price = product['price'];
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openProduct(context, product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Hero(
              tag:
                  'customer-product-${(product['id_product'] ?? '').toString()}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox.expand(
                  child: _buildNetworkImage(picture, iconSize: 24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TText(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ashGreySubtle,
              fontSize: 8.5,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          TText(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ivorySilk,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormat.toRupiah(price),
              style: const TextStyle(
                color: AppColors.champagneGoldLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (stock <= 0)
            const TText(
              'Stok Habis',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (wood.isNotEmpty)
            TText(
              wood,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ashGreySubtle,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage(String? picture, {double iconSize = 26}) {
    if (picture == null) {
      return Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.ashGreySubtle,
          size: iconSize,
        ),
      );
    }

    return Image.network(
      picture,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.champagneGold,
              ),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.ashGreySubtle,
          size: iconSize,
        ),
      ),
    );
  }

  void _openProduct(BuildContext context, Map<String, dynamic> product) {
    widget.onProductSelected(product);
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.champagneGold),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.ashGreySubtle,
              size: 44,
            ),
            const SizedBox(height: 14),
            const TText(
              'Belum ada furnitur di katalog',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const TText(
              'Coba kata kunci atau kategori lain',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ashGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 14),
            TText(
              _errorMessage ?? 'Gagal memuat katalog',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _fetchCatalog,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const TText('Coba Lagi'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.champagneGold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
