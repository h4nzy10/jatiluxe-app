import 'package:flutter/material.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../service/l10n.dart';
import '../../utils/formatters.dart';

/// Customer shopping cart with dynamic quantity, removal, selective checkout,
/// and localized empty/error states.
///
/// The cart API returns names and prices but not product IDs/images, so the
/// public catalog is fetched alongside it to enrich cards with pictures and to
/// allow opening the matching product detail page.
class CustomerCartPage extends StatefulWidget {
  /// Receives checked cart detail IDs and the computed total. Page 4 will use
  /// this to start checkout without reading the cart again.
  final void Function(List<int> selectedCartIds, num total)? onCheckout;

  /// Called when a cart item's product card is tapped.
  final void Function(Map<String, dynamic> product)? onProductSelected;

  /// Optional override for the empty-state "Explore Catalog" action.
  final VoidCallback? onBrowseCatalog;

  /// Notifies the shell after cart mutations so its badge stays in sync.
  final VoidCallback? onCartChanged;

  const CustomerCartPage({
    super.key,
    this.onCheckout,
    this.onProductSelected,
    this.onBrowseCatalog,
    this.onCartChanged,
  });

  @override
  State<CustomerCartPage> createState() => _CustomerCartPageState();
}

class _CustomerCartPageState extends State<CustomerCartPage> {
  List<dynamic> _items = [];
  List<dynamic> _products = [];
  final Set<int> _selectedIds = <int>{};
  final Set<int> _updatingIds = <int>{};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  Future<void> _fetchCart() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/cart-list'),
        ApiService.get('/api/v1/products').catchError((_) => null),
      ]);
      if (!mounted) return;

      final raw = results[0] is Map ? results[0]['cart'] : null;
      if (raw is! List) {
        throw Exception('Gagal memuat keranjang');
      }

      final catalog = results[1] is Map && results[1]['products'] is List
          ? List<dynamic>.from(results[1]['products'] as List)
          : <dynamic>[];
      final items = List<dynamic>.from(raw);
      final ids = items
          .map(_asMap)
          .map((item) => int.tryParse(item['cart_detail_id']?.toString() ?? ''))
          .whereType<int>()
          .toSet();

      setState(() {
        _items = items;
        _products = catalog;
        _selectedIds
          ..clear()
          ..addAll(ids);
        _isLoading = false;
      });
      widget.onCartChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  int _itemId(Map<String, dynamic> item) =>
      int.tryParse(item['cart_detail_id']?.toString() ?? '') ?? 0;

  int _quantityOf(Map<String, dynamic> item) =>
      int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;

  num _priceOf(Map<String, dynamic> item) =>
      num.tryParse(item['price']?.toString() ?? '0') ?? 0;

  num _subtotalOf(Map<String, dynamic> item) =>
      _priceOf(item) * _quantityOf(item);

  num get _selectedTotal => _items
      .map(_asMap)
      .where((item) => _selectedIds.contains(_itemId(item)))
      .fold<num>(0, (sum, item) => sum + _subtotalOf(item));

  bool get _allSelected =>
      _items.isNotEmpty &&
      _selectedIds.length == _items.map(_asMap).map(_itemId).where((id) => id > 0).length;

  String? _cleanImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    return clean.startsWith('http://')
        ? 'https://${clean.substring(7)}'
        : clean;
  }

  /// Cart rows do not carry product IDs, so match the catalog by name.
  Map<String, dynamic>? _matchedProduct(Map<String, dynamic> item) {
    final name = (item['product_name'] ?? '').toString().trim().toLowerCase();
    if (name.isEmpty) return null;
    for (final raw in _products) {
      final product = _asMap(raw);
      if ((product['product_name'] ?? '').toString().trim().toLowerCase() ==
          name) {
        return product;
      }
    }
    return null;
  }

  int _maxQuantity(Map<String, dynamic>? product) {
    final stock = int.tryParse(product?['stock']?.toString() ?? '0') ?? 0;
    return stock > 0 ? stock : 999;
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
        title: const TText(
          'Keranjang',
          style: TextStyle(fontSize: 14, letterSpacing: 1.0),
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
              ? _buildErrorView()
              : _items.isEmpty
                  ? _buildEmptyView(context)
                  : Column(
                      children: [
                        _buildSelectAllRow(),
                        Expanded(child: _buildItemList(context)),
                      ],
                    ),
      bottomNavigationBar:
          (_isLoading || _errorMessage != null || _items.isEmpty)
              ? null
              : _buildBottomBar(context),
    );
  }

  Widget _buildSelectAllRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _allSelected,
            onChanged: _toggleSelectAll,
            activeColor: AppColors.champagneGold,
            checkColor: AppColors.obsidianBlack,
            side: const BorderSide(color: AppColors.ashGreySubtle, width: 1),
          ),
          const TText(
            'Pilih Semua',
            style: TextStyle(
              color: AppColors.ivorySilk,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: TText(
              _selectedIds.length == 1
                  ? '1 item dipilih'
                  : '${_selectedIds.length} item dipilih',
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.ashGrey, fontSize: 11),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.champagneGold,
      backgroundColor: AppColors.charcoalVelvet,
      onRefresh: _fetchCart,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildItemCard(context, _asMap(_items[index])),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    final id = _itemId(item);
    final product = _matchedProduct(item);
    final picture = _cleanImageUrl(product?['picture']?.toString());
    final category = (product?['category'] ?? '').toString();
    final name = (item['product_name'] ?? '').toString();
    final stock = int.tryParse(product?['stock']?.toString() ?? '0') ?? 0;
    final isUpdating = _updatingIds.contains(id);

    return Opacity(
      opacity: isUpdating ? 0.7 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 10, 10, 10),
        decoration: BoxDecoration(
          color: AppColors.charcoalVelvet,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _selectedIds.contains(id),
              onChanged: isUpdating
                  ? null
                  : (value) => setState(() {
                      if (value == true) {
                        _selectedIds.add(id);
                      } else {
                        _selectedIds.remove(id);
                      }
                    }),
              activeColor: AppColors.champagneGold,
              checkColor: AppColors.obsidianBlack,
              side: const BorderSide(color: AppColors.ashGreySubtle, width: 1),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemImage(context, picture, product, name),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category.isNotEmpty)
                          TText(
                            category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.champagneGold,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 2),
                        TText(
                          name,
                          style: const TextStyle(
                            color: AppColors.ivorySilk,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormat.toRupiah(_priceOf(item)),
                            style: const TextStyle(
                              color: AppColors.champagneGoldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: TText(
                            'Subtotal: ${CurrencyFormat.toRupiah(_subtotalOf(item))}',
                            style: const TextStyle(
                              color: AppColors.ashGrey,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        if (stock > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: TText(
                              'Stok: $stock Unit',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildQuantityStepper(
                              item: item,
                              product: product,
                              id: id,
                              isUpdating: isUpdating,
                            ),
                            IconButton(
                              onPressed: isUpdating
                                  ? null
                                  : () => _confirmDelete(context, item),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                              ),
                              color: AppColors.error,
                              disabledColor: AppColors.ashGreySubtle,
                              tooltip: 'Hapus'.tr(context),
                              constraints: const BoxConstraints.tightFor(
                                width: 30,
                                height: 30,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage(
    BuildContext context,
    String? picture,
    Map<String, dynamic>? product,
    String name,
  ) {
    Widget image = SizedBox(
      width: 62,
      height: 76,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: picture != null
            ? Image.network(
                picture,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.ashGreySubtle,
                    size: 20,
                  ),
                ),
              )
            : const Center(
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.ashGreySubtle,
                  size: 20,
                ),
              ),
      ),
    );

    if (product == null || widget.onProductSelected == null) return image;

    return Semantics(
      button: true,
      label: name,
      child: InkWell(
        onTap: () => widget.onProductSelected!(product),
        borderRadius: BorderRadius.circular(8),
        child: image,
      ),
    );
  }

  Widget _buildQuantityStepper({
    required Map<String, dynamic> item,
    required Map<String, dynamic>? product,
    required int id,
    required bool isUpdating,
  }) {
    final quantity = _quantityOf(item);
    final max = _maxQuantity(product);
    final canDecrease = quantity > 1 && !isUpdating;
    final canIncrease = quantity < max && !isUpdating;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: canDecrease
                ? () => _updateQuantity(item, quantity - 1)
                : null,
            icon: const Icon(Icons.remove_rounded, size: 14),
            color: AppColors.champagneGold,
            disabledColor: AppColors.ashGreySubtle,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
          ),
          SizedBox(
            width: 28,
            child: isUpdating
                ? const Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.champagneGold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          IconButton(
            onPressed: canIncrease
                ? () => _updateQuantity(item, quantity + 1)
                : null,
            icon: const Icon(Icons.add_rounded, size: 14),
            color: AppColors.champagneGold,
            disabledColor: AppColors.ashGreySubtle,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll(bool? value) {
    final ids = _items
        .map(_asMap)
        .map(_itemId)
        .where((id) => id > 0)
        .toSet();
    setState(() {
      if (value == true) {
        _selectedIds
          ..clear()
          ..addAll(ids);
      } else {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _updateQuantity(Map<String, dynamic> item, int quantity) async {
    final id = _itemId(item);
    if (id <= 0 || quantity < 1) return;
    setState(() => _updatingIds.add(id));

    try {
      await ApiService.put('/api/v1/cart/$id', {'quantity': quantity});
      if (!mounted) return;
      setState(() {
        final index = _items.indexWhere(
          (raw) => _itemId(_asMap(raw)) == id,
        );
        if (index >= 0) {
          final updated = _asMap(_items[index]);
          updated['quantity'] = quantity;
          updated['subtotal'] = _priceOf(updated) * quantity;
          _items[index] = updated;
        }
      });
      widget.onCartChanged?.call();
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Gagal memperbarui keranjang: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
      await _fetchCart();
    } finally {
      if (mounted) setState(() => _updatingIds.remove(id));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.charcoalVelvet,
        title: const TText(
          'Hapus item ini dari keranjang?',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const TText('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const TText(
              'Ya, Hapus',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _deleteItem(item);
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final id = _itemId(item);
    if (id <= 0) return;
    setState(() => _updatingIds.add(id));

    try {
      await ApiService.delete('/api/v1/cart/$id');
      if (!mounted) return;
      setState(() {
        _items.removeWhere((raw) => _itemId(_asMap(raw)) == id);
        _selectedIds.remove(id);
      });
      widget.onCartChanged?.call();
      _showSnack('Item dihapus dari keranjang', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Gagal menghapus item: '
        '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _updatingIds.remove(id));
    }
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.charcoalVelvet,
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TText(
                    'Total',
                    style: TextStyle(color: AppColors.ashGrey, fontSize: 10),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormat.toRupiah(_selectedTotal),
                      style: const TextStyle(
                        color: AppColors.champagneGoldLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Material(
                color: AppColors.champagneGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: InkWell(
                  onTap: _checkout,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          size: 16,
                          color: AppColors.obsidianBlack,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: const TText(
                            'Lanjut ke Checkout',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.obsidianBlack,
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
            ),
          ],
        ),
      ),
    );
  }

  void _checkout() {
    if (_selectedIds.isEmpty) {
      _showSnack('Pilih minimal satu item', isError: true);
      return;
    }

    final ids = _selectedIds.toList()..sort();
    final callback = widget.onCheckout;
    if (callback != null) {
      callback(ids, _selectedTotal);
      return;
    }
    // Checkout page will replace this once it is wired in.
    _showSnack('Checkout segera tersedia', isError: false);
  }

  void _showSnack(String message, {required bool isError}) {
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
          style: const TextStyle(color: AppColors.ivorySilk, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.ashGreySubtle,
              size: 52,
            ),
            const SizedBox(height: 14),
            const TText(
              'Keranjang masih kosong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const TText(
              'Temukan karya kayu favorit Anda di katalog',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ashGrey, fontSize: 12),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                final callback = widget.onBrowseCatalog;
                if (callback != null) {
                  callback();
                } else {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(170, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const TText('Jelajahi Katalog'),
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
              size: 44,
            ),
            const SizedBox(height: 14),
            TText(
              _errorMessage ?? 'Gagal memuat keranjang',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _fetchCart,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 40),
              ),
              child: const TText('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
