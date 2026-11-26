import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../utils/formatters.dart';

class SellerInventoryPage extends StatefulWidget {
  const SellerInventoryPage({super.key});

  @override
  State<SellerInventoryPage> createState() => _SellerInventoryPageState();
}

class _SellerInventoryPageState extends State<SellerInventoryPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategoryFilter = 'Semua';
  List<Map<String, dynamic>> _categories = [];
  List<String> _categoryFilters = ['Semua'];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/seller-products').catchError((_) => null),
        ApiService.get('/api/v1/categories').catchError((_) => null),
      ]);

      if (!mounted) return;

      // 1. Process Categories from Database
      final catRes = results[1];
      if (catRes != null && catRes['categories'] != null) {
        _categories = List<Map<String, dynamic>>.from(catRes['categories']);
        final names = _categories
            .map((c) => (c['category'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
        _categoryFilters = ['Semua', ...names];
      } else {
        _categories = [
          {'id_category': 1, 'category': 'Seatings'},
          {'id_category': 2, 'category': 'Tables'},
          {'id_category': 3, 'category': 'Storage'},
          {'id_category': 4, 'category': 'Sleeping'},
          {'id_category': 5, 'category': 'Outdoor'},
          {'id_category': 6, 'category': 'Decoration'},
        ];
        _categoryFilters = ['Semua', ..._categories.map((c) => c['category'] as String)];
      }

      // 2. Process Products
      final prodRes = results[0];
      if (prodRes != null && prodRes['products'] != null) {
        _products = List<dynamic>.from(prodRes['products']);
      } else {
        _products = [];
      }

      _applyFilter();
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().toLowerCase();
      if (err.contains('empty') || err.contains('404')) {
        setState(() {
          _products = [];
          _filteredProducts = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredProducts = _products.where((item) {
        final name = (item['product_name'] ?? '').toString().toLowerCase();
        final wood = (item['wood_type'] ?? '').toString().toLowerCase();
        final category = (item['category'] ?? '').toString();

        final matchesQuery = query.isEmpty ||
            name.contains(query) ||
            wood.contains(query) ||
            category.toLowerCase().contains(query);

        final matchesCategory = _selectedCategoryFilter == 'Semua' ||
            category.trim().toLowerCase() == _selectedCategoryFilter.trim().toLowerCase();

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  String? _cleanImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    var clean = url.trim();
    if (clean.startsWith('http://')) {
      clean = 'https://${clean.substring(7)}';
    }
    return clean;
  }

  void _openProductForm({Map<String, dynamic>? existingProduct}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ProductFormSheet(
        existingProduct: existingProduct,
        categories: _categories,
        onSuccess: () {
          Navigator.pop(ctx);
          _fetchProducts();
        },
      ),
    );
  }

  Future<void> _deleteProduct(dynamic idProduct, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        title: const Text(
          'Delete Karya Jati',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "$productName" dari katalog inventaris toko?',
          style: const TextStyle(
            color: AppColors.ashGrey,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.ashGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.ivorySilk,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.delete('/api/v1/product/$idProduct');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.charcoalVelvet,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Produk berhasil dihapus dari etalase',
              style: TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            ),
          ),
        );
      }
      _fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.charcoalVelvet,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Gagal menghapus: ${e.toString().replaceFirst('Exception: ', '')}',
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.champagneGold,
          backgroundColor: AppColors.charcoalVelvet,
          onRefresh: _fetchProducts,
          child: Column(
            children: [
              _buildTopBar(),
              _buildSearchAndFilters(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
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
                        : _filteredProducts.isEmpty
                            ? _buildEmptyView()
                            : _buildProductList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'KATALOG & INVENTARIS',
                style: TextStyle(
                  color: AppColors.ashGreySubtle,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_products.length} Desain Terdaftar',
                style: const TextStyle(
                  color: AppColors.ivorySilk,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _openProductForm(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tambah Karya'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
              foregroundColor: AppColors.obsidianBlack,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Input
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          child: TextFormField(
            controller: _searchController,
            style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            cursorColor: AppColors.champagneGold,
            decoration: InputDecoration(
              hintText: 'Cari nama mebel, ukiran, atau kategori...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.ashGreySubtle,
                size: 18,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16, color: AppColors.ashGreySubtle),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),

        // Category Horizontal Filters from Database
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: _categoryFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categoryFilters[index];
              final isSelected = _selectedCategoryFilter == category;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategoryFilter = category;
                    _applyFilter();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.champagneGold : AppColors.charcoalVelvet,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.champagneGold : AppColors.surfaceBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? AppColors.obsidianBlack : AppColors.ashGrey,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildProductList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      itemCount: _filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = _filteredProducts[index];
        final idProduct = p['id_product'];
        final name = p['product_name'] ?? 'Mebel Jati';
        final woodType = p['wood_type'] ?? 'Kayu Jati';
        final category = p['category'] ?? 'Furnitur';
        final price = p['price'] ?? 0;
        final stock = int.tryParse(p['stock']?.toString() ?? '0') ?? 0;
        final rawPic = p['picture'];
        final cleanPic = _cleanImageUrl(rawPic);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.charcoalVelvet,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Preview
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder, width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: cleanPic != null
                      ? Image.network(
                          cleanPic,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.champagneGold,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, color: AppColors.ashGreySubtle, size: 24),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_outlined, color: AppColors.ashGreySubtle, size: 24),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Product Info & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Wood badge
                    Row(
                      children: [
                        Text(
                          category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.champagneGold,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '•  $woodType',
                          style: const TextStyle(
                            color: AppColors.ashGrey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Product Name
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      CurrencyFormat.toRupiah(price),
                      style: const TextStyle(
                        color: AppColors.champagneGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Stock Tag & Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: stock > 0
                                ? AppColors.surfaceElevated
                                : AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stock > 0 ? 'Stok: $stock Unit' : 'Stok Habis',
                            style: TextStyle(
                              color: stock > 0 ? AppColors.ashGrey : AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _openProductForm(existingProduct: p),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.ashGrey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => _deleteProduct(idProduct, name),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 46,
              color: AppColors.ashGreySubtle,
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum Ada Koleksi Jati',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Mulai daftarkan karya furnitur kayu jati Anda ke etalase untuk dilihat para kolektor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openProductForm(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Karya Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.champagneGold,
                foregroundColor: AppColors.obsidianBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Gagal Memuat Inventaris',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Periksa koneksi server Anda',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ashGrey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.champagneGold),
              label: const Text('Muat Ulang', style: TextStyle(color: AppColors.champagneGold)),
            ),
          ],
        ),
      ),
    );
  }
}

/// BottomSheet Form to Add or Edit Teak Furniture Product
class _ProductFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existingProduct;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onSuccess;

  const _ProductFormSheet({
    this.existingProduct,
    required this.categories,
    required this.onSuccess,
  });

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descController;

  int _selectedCategoryId = 1;
  String _selectedWoodType = 'Jati TPK Perhutani';
  String? _existingPictureUrl;
  File? _pickedImage;

  bool _isSaving = false;

  late final List<Map<String, dynamic>> _categories;

  final List<String> _woodTypes = [
    'Jati TPK Perhutani',
    'Jati Emas',
    'Jati Belanda',
    'Jati Jawa Kuno',
  ];

  @override
  void initState() {
    super.initState();
    _categories = widget.categories.isNotEmpty
        ? widget.categories
        : [
            {'id_category': 1, 'category': 'Kursi & Sofa'},
            {'id_category': 2, 'category': 'Meja'},
            {'id_category': 3, 'category': 'Lemari & Rak'},
            {'id_category': 4, 'category': 'Tempat Tidur'},
            {'id_category': 5, 'category': 'Dekorasi & Ukir'},
          ];

    final p = widget.existingProduct;
    _nameController = TextEditingController(text: p?['product_name'] ?? '');
    _priceController = TextEditingController(text: p?['price']?.toString() ?? '');
    _stockController = TextEditingController(text: p?['stock']?.toString() ?? '1');
    _descController = TextEditingController(text: p?['description'] ?? '');
    _existingPictureUrl = p?['picture'];

    if (p != null) {
      final catId = int.tryParse(p['id_category']?.toString() ?? '1') ?? 1;
      final exists = _categories.any((c) {
        final cid = int.tryParse(c['id_category']?.toString() ?? c['id']?.toString() ?? '0');
        return cid == catId;
      });
      _selectedCategoryId = exists ? catId : (int.tryParse(_categories.first['id_category']?.toString() ?? '1') ?? 1);
      _selectedWoodType = p['wood_type'] ?? _woodTypes.first;
    } else {
      _selectedCategoryId = int.tryParse(_categories.first['id_category']?.toString() ?? '1') ?? 1;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.champagneGold),
                title: const Text('Ambil Foto Kamera', style: TextStyle(color: AppColors.ivorySilk)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.champagneGold),
                title: const Text('Pilih dari Galeri', style: TextStyle(color: AppColors.ivorySilk)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final isEdit = widget.existingProduct != null;

    if (!isEdit && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.charcoalVelvet,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Foto karya mebel jati wajib diunggah',
            style: TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final fields = {
      'id_category': _selectedCategoryId.toString(),
      'product_name': _nameController.text.trim(),
      'wood_type': _selectedWoodType,
      'price': _priceController.text.trim(),
      'stock': _stockController.text.trim(),
      'description': _descController.text.trim(),
      if (isEdit && _pickedImage == null && _existingPictureUrl != null)
        'picture': _existingPictureUrl!,
    };

    try {
      if (isEdit) {
        final idProduct = widget.existingProduct!['id_product'];
        if (_pickedImage != null) {
          await ApiService.putMultipart(
            '/api/v1/product/$idProduct',
            fields: fields,
            fileField: 'picture',
            filePath: _pickedImage!.path,
          );
        } else {
          await ApiService.put('/api/v1/product/$idProduct', fields);
        }
      } else {
        await ApiService.postMultipart(
          '/api/v1/product',
          fields: fields,
          fileField: 'picture',
          filePath: _pickedImage!.path,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.charcoalVelvet,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.champagneGold, width: 0.8),
            ),
            content: Text(
              isEdit
                  ? 'Karya jati berhasil diperbarui'
                  : 'Karya mebel jati berhasil didaftarkan ke etalase',
              style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            ),
          ),
        );
      }
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.charcoalVelvet,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.error, width: 0.8),
            ),
            content: Text(
              'Gagal menyimpan: ${e.toString().replaceFirst('Exception: ', '')}',
              style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingProduct != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 22,
        right: 22,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Perbarui Karya Jati' : 'Tambah Karya Jati Baru',
                    style: const TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.ashGrey, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.surfaceBorder),
              const SizedBox(height: 12),

              // Image Selector Preview
              GestureDetector(
                onTap: _showImagePickerModal,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.charcoalVelvet,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_pickedImage!, fit: BoxFit.cover),
                              Container(
                                color: Colors.black38,
                                child: const Center(
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 26),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _existingPictureUrl != null && _existingPictureUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(_existingPictureUrl!, fit: BoxFit.cover),
                                  Container(
                                    color: Colors.black38,
                                    child: const Center(
                                      child: Icon(Icons.camera_alt, color: Colors.white, size: 26),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_photo_alternate_outlined, color: AppColors.champagneGold, size: 36),
                                SizedBox(height: 8),
                                Text(
                                  'Unggah Foto Mebel Jati',
                                  style: TextStyle(color: AppColors.ivorySilk, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Foto pencahayaan alami beresolusi tinggi',
                                  style: TextStyle(color: AppColors.ashGreySubtle, fontSize: 11),
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 18),

              // Product Name
              _buildFieldLabel('Nama Karya Mebel'),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
                cursorColor: AppColors.champagneGold,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Meja Makan Jati Solid Trembesi',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),

              const SizedBox(height: 14),

              // Category & Wood Type Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Kategori'),
                        DropdownButtonFormField<int>(
                          value: _selectedCategoryId,
                          dropdownColor: AppColors.surfaceElevated,
                          style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _categories.map((c) {
                            final id = int.tryParse(c['id_category']?.toString() ?? c['id']?.toString() ?? '1') ?? 1;
                            final name = (c['category'] ?? c['name'] ?? 'Kategori').toString();
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategoryId = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Jenis Kayu Jati'),
                        DropdownButtonFormField<String>(
                          value: _selectedWoodType,
                          dropdownColor: AppColors.surfaceElevated,
                          style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: _woodTypes.map((w) {
                            return DropdownMenuItem<String>(
                              value: w,
                              child: Text(w, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedWoodType = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Price & Stock Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Harga (Rupiah)'),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
                          cursorColor: AppColors.champagneGold,
                          decoration: const InputDecoration(hintText: '12500000'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Harga wajib diisi';
                            final numVal = num.tryParse(val.trim());
                            if (numVal == null || numVal <= 0) return 'Harga tidak valid';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Stok Unit'),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
                          cursorColor: AppColors.champagneGold,
                          decoration: const InputDecoration(hintText: '1'),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Stok wajib';
                            final intVal = int.tryParse(val.trim());
                            if (intVal == null || intVal < 0) return 'Stok >= 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Description
              _buildFieldLabel('Deskripsi Spesifikasi & Dimensi'),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
                cursorColor: AppColors.champagneGold,
                decoration: const InputDecoration(
                  hintText: 'Sebutkan dimensi (P x L x T), teknik finishing kayu (natural oil, walnut), dan keunggulan serat.',
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.champagneGold,
                    foregroundColor: AppColors.obsidianBlack,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.obsidianBlack),
                          ),
                        )
                      : Text(
                          isEdit ? 'Perbarui Karya Jati' : 'Daftarkan Karya ke Etalase',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.ivorySilk, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
