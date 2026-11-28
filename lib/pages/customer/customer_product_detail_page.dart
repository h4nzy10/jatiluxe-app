import 'package:flutter/material.dart';

import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../service/l10n.dart';
import '../../utils/formatters.dart';

/// Customer product detail page.
///
/// Layout follows a familiar marketplace product page (large gallery, bold
/// price block, separated information cards, sticky cart/buy actions) while
/// keeping the JatiLuxe Obsidian & Champagne Gold identity.
class CustomerProductDetailPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic>? initialProduct;
  final void Function(Map<String, dynamic> product, int quantity) onBuyNow;

  const CustomerProductDetailPage({
    super.key,
    required this.productId,
    this.initialProduct,
    required this.onBuyNow,
  });

  @override
  State<CustomerProductDetailPage> createState() =>
      _CustomerProductDetailPageState();
}

class _CustomerProductDetailPageState extends State<CustomerProductDetailPage> {
  Map<String, dynamic>? _product;
  List<dynamic> _recommendations = [];
  bool _isLoading = true;
  bool _isAddingToCart = false;
  String? _errorMessage;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/product/${widget.productId}'),
        ApiService.get('/api/v1/products').catchError((_) => null),
      ]);
      if (!mounted) return;
      final raw = results[0] is Map ? results[0]['product'] : null;
      if (raw == null) {
        throw Exception('Produk tidak ditemukan');
      }
      final product = Map<String, dynamic>.from(raw as Map);
      final allProducts = results[1] is Map && results[1]['products'] is List
          ? List<dynamic>.from(results[1]['products'] as List)
          : <dynamic>[];

      setState(() {
        _product = product;
        _recommendations = _pickRecommendations(allProducts, product);
        _quantity = 1;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> get _currentProduct => _product ?? <String, dynamic>{};

  int get _stock =>
      int.tryParse(_currentProduct['stock']?.toString() ?? '0') ?? 0;

  String? _cleanImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    return clean.startsWith('http://')
        ? 'https://${clean.substring(7)}'
        : clean;
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  /// Same-category and same-wood pieces first, then anything else in the
  /// catalog, excluding the product currently being viewed.
  List<dynamic> _pickRecommendations(
    List<dynamic> products,
    Map<String, dynamic> current,
  ) {
    final currentId = (current['id_product'] ?? '').toString();
    final category = (current['category'] ?? '').toString().toLowerCase();
    final wood = (current['wood_type'] ?? '').toString().toLowerCase();

    final candidates = products
        .map(_asMap)
        .where(
          (product) => (product['id_product'] ?? '').toString() != currentId,
        )
        .toList();

    int relevance(Map<String, dynamic> product) {
      final sameCategory =
          (product['category'] ?? '').toString().toLowerCase() == category;
      final sameWood =
          (product['wood_type'] ?? '').toString().toLowerCase() == wood;
      return (sameCategory ? 2 : 0) + (sameWood ? 1 : 0);
    }

    candidates.sort((a, b) => relevance(b).compareTo(relevance(a)));
    return candidates.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        title: const TText(
          'Detail Produk',
          style: TextStyle(fontSize: 14, letterSpacing: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [LanguageSwitcher()],
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.champagneGold,
                  ),
                ),
              ),
            )
          : _errorMessage != null
          ? _buildErrorView(context)
          : _buildContent(context),
      bottomNavigationBar: (_isLoading || _errorMessage != null)
          ? null
          : _buildActionBar(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final product = _currentProduct;
    final picture = _cleanImageUrl(product['picture']?.toString());
    final category = (product['category'] ?? '').toString();
    final wood = (product['wood_type'] ?? '').toString();
    final name = (product['product_name'] ?? '').toString();
    final seller = (product['seller'] ?? product['nama'] ?? '').toString();
    final description = (product['description'] ?? '').toString();
    final stock = _stock;

    return RefreshIndicator(
      color: AppColors.champagneGold,
      backgroundColor: AppColors.charcoalVelvet,
      onRefresh: _fetchProduct,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildGallery(picture),
            const SizedBox(height: 8),
            _buildPriceAndTitleCard(name, category, wood, stock),
            _buildSectionCard(
              title: 'SPESIFIKASI KARYA',
              children: [
                _buildSpecRow('Kategori', category),
                _buildSpecRow('Jenis Kayu', wood),
                _buildSpecRow('Stok Unit', stock.toString()),
                _buildSpecRow('Pengrajin', seller),
              ],
            ),
            _buildSectionCard(
              title: 'DESKRIPSI & DIMENSI',
              children: [
                TText(
                  description.isEmpty ? '-' : description,
                  style: const TextStyle(
                    color: AppColors.ashGrey,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
            _buildRecommendations(context),
            _buildSectionCard(
              title: '',
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TText(
                      'Jumlah',
                      style: TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TText(
                      stock > 0 ? 'Stok: $stock Unit' : 'Stok Habis',
                      style: TextStyle(
                        color: stock > 0 ? AppColors.success : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuantitySelector(),
              ],
            ),
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(String? picture) {
    return Hero(
      tag: 'customer-product-${widget.productId}',
      child: Container(
        height: 300,
        color: AppColors.charcoalVelvet,
        child: Stack(
          fit: StackFit.expand,
          children: [
            picture != null
                ? Image.network(
                    picture,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.champagneGold,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.ashGreySubtle,
                        size: 44,
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: AppColors.ashGreySubtle,
                      size: 44,
                    ),
                  ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.obsidianBlack.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const TText(
                  '1 / 1',
                  style: TextStyle(
                    color: AppColors.ivorySilk,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Center(
                child: SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAndTitleCard(
    String name,
    String category,
    String wood,
    int stock,
  ) {
    return _buildSectionCard(
      title: 'JATILUXE',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                CurrencyFormat.toRupiah(_currentProduct['price']),
                style: const TextStyle(
                  color: AppColors.champagneGoldLight,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warmBronze.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.warmBronze, width: 0.8),
              ),
              child: const TText(
                'JATILUXE',
                style: TextStyle(
                  color: AppColors.champagneGold,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TText(
          name,
          style: const TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(
              label: category.toUpperCase(),
              foreground: AppColors.champagneGold,
              background: AppColors.warmBronze.withValues(alpha: 0.16),
            ),
            _buildInfoChip(
              label: wood,
              foreground: AppColors.ashGrey,
              background: AppColors.surfaceElevated,
            ),
            _buildInfoChip(
              label: stock > 0 ? 'Stok: $stock Unit' : 'Stok Habis',
              foreground: stock > 0 ? AppColors.success : AppColors.error,
              background: (stock > 0 ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required String label,
    required Color foreground,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TText(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TText(
            title,
            style: const TextStyle(
              color: AppColors.champagneGold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    if (_recommendations.isEmpty) return const SizedBox.shrink();

    return _buildSectionCard(
      title: 'ANDA MUNGKIN SUKA',
      children: [
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _buildRecommendationCard(
              context,
              _asMap(_recommendations[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
    final id = (product['id_product'] ?? '').toString();
    final picture = _cleanImageUrl(product['picture']?.toString());
    final name = (product['product_name'] ?? '').toString();
    final category = (product['category'] ?? '').toString();

    return SizedBox(
      width: 116,
      height: 168,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerProductDetailPage(
              productId: id,
              initialProduct: product,
              onBuyNow: widget.onBuyNow,
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 88,
                width: double.infinity,
                child: Hero(
                  tag: 'customer-product-$id',
                  child: picture != null
                      ? Image.network(
                          picture,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.ashGreySubtle,
                              size: 22,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.ashGreySubtle,
                            size: 22,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TText(
                        category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.champagneGold,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Flexible(
                        child: TText(
                          name,
                          style: const TextStyle(
                            color: AppColors.ivorySilk,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormat.toRupiah(product['price']),
                          style: const TextStyle(
                            color: AppColors.champagneGoldLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: TText(
              label,
              style: const TextStyle(
                color: AppColors.ashGreySubtle,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: TText(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    final max = _stock > 0 ? _stock : 1;
    return Container(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _quantity > 1 && !_isAddingToCart
                  ? () => setState(() => _quantity--)
                  : null,
              icon: const Icon(Icons.remove_rounded, size: 18),
              color: AppColors.champagneGold,
              disabledColor: AppColors.ashGreySubtle,
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$_quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ivorySilk,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: _quantity < max && !_isAddingToCart
                  ? () => setState(() => _quantity++)
                  : null,
              icon: const Icon(Icons.add_rounded, size: 18),
              color: AppColors.champagneGold,
              disabledColor: AppColors.ashGreySubtle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final disabled = _stock <= 0 || _isAddingToCart;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.charcoalVelvet,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildActionButton(
              label: 'Tambah ke Keranjang',
              icon: Icons.add_shopping_cart_outlined,
              primary: false,
              enabled: !disabled,
              onPressed: _addToCart,
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              label: 'Beli Langsung',
              icon: Icons.flash_on_rounded,
              primary: true,
              enabled: !disabled,
              onPressed: _buyNow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required bool primary,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final foreground = !enabled
        ? AppColors.ashGreySubtle
        : primary
        ? AppColors.obsidianBlack
        : AppColors.champagneGold;
    final background = primary
        ? (enabled ? AppColors.champagneGold : AppColors.surfaceElevated)
        : Colors.transparent;

    return Expanded(
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: primary
              ? BorderSide.none
              : BorderSide(
                  color: enabled
                      ? AppColors.warmBronze
                      : AppColors.surfaceBorder,
                  width: 1,
                ),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 5),
                Flexible(
                  child: TText(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_stock <= 0) return;
    setState(() => _isAddingToCart = true);
    try {
      await ApiService.post('/api/v1/cart', {
        'product_id': int.tryParse(widget.productId) ?? 0,
        'quantity': _quantity,
      });
      if (!mounted) return;
      _showSnack(context, 'Produk ditambahkan ke keranjang', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        context,
        'Gagal menambahkan ke keranjang: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  void _buyNow() {
    widget.onBuyNow(_currentProduct, _quantity);
  }

  void _showSnack(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isError ? AppColors.error : AppColors.champagneGold,
            width: 0.8,
          ),
        ),
        content: TText(
          message,
          style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.error,
              size: 44,
            ),
            const SizedBox(height: 14),
            TText(
              _errorMessage ?? 'Gagal memuat detail produk',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _fetchProduct,
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 40)),
              child: const TText('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
