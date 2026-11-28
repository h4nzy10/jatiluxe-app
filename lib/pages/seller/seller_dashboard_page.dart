import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../service/auto_refresh.dart';
import '../../utils/formatters.dart';

class SellerDashboardPage extends StatefulWidget {
  final VoidCallback? onNavigateToInventory;
  final VoidCallback? onNavigateToDelivery;

  /// False while this tab is not visible, so it does not poll in the background.
  final bool isActive;

  const SellerDashboardPage({
    super.key,
    this.onNavigateToInventory,
    this.onNavigateToDelivery,
    this.isActive = true,
  });

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage>
    with AutoRefresh<SellerDashboardPage> {
  @override
  bool get autoRefreshEnabled => widget.isActive;

  bool _isLoading = true;
  String? _errorMessage;

  String _sellerName = 'Workshop Jepara';
  String _sellerAddress = 'Jepara, Jawa Tengah';
  String? _sellerAvatar;
  bool _isUploadingAvatar = false;

  num _totalSales = 0;
  List<dynamic> _salesList = [];
  int _productCount = 0;
  int _totalStockUnits = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    startAutoRefresh(() => _fetchDashboardData(silent: true));
  }

  Future<void> _fetchDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/profile').catchError((_) => null),
        ApiService.get('/api/v1/sales').catchError((_) => null),
        ApiService.get('/api/v1/seller-products').catchError((_) => null),
      ]);

      if (!mounted) return;

      // 1. Profile Data
      final profileRes = results[0];
      if (profileRes != null && profileRes['user'] != null) {
        final u = profileRes['user'];
        _sellerName = u['nama'] ?? _sellerName;
        _sellerAddress = (u['alamat'] != null && u['alamat'].toString().isNotEmpty)
            ? u['alamat']
            : 'Jepara, Jawa Tengah';
        _sellerAvatar = u['profile'];
      }

      // 2. Sales Analytics
      final salesRes = results[1];
      if (salesRes != null && salesRes['success'] == true) {
        _totalSales = salesRes['total_sales'] ?? 0;
        _salesList = salesRes['sales'] ?? [];
      } else {
        _totalSales = 0;
        _salesList = [];
      }

      // 3. Products & Stock Counts
      final productsRes = results[2];
      if (productsRes != null && productsRes['products'] != null) {
        final List list = productsRes['products'];
        _productCount = list.length;
        _totalStockUnits = list.fold<int>(
          0,
          (sum, item) => sum + (int.tryParse(item['stock']?.toString() ?? '0') ?? 0),
        );
      } else {
        _productCount = 0;
        _totalStockUnits = 0;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.champagneGold,
          backgroundColor: AppColors.charcoalVelvet,
          onRefresh: _fetchDashboardData,
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
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWorkshopHeader(context),
                          const SizedBox(height: 28),
                          _buildRevenueLedger(),
                          const SizedBox(height: 28),
                          _buildInventoryOverview(),
                          const SizedBox(height: 28),
                          _buildOperationalRibbons(),
                          const SizedBox(height: 28),
                          _buildCuratorialNote(),
                          const SizedBox(height: 32),
                          _buildSalesLedger(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  String? _getCleanImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    var clean = url.trim();
    if (clean.startsWith('http://')) {
      clean = 'https://${clean.substring(7)}';
    }
    return clean;
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TText(
                'Foto Profil Workshop / Galeri',
                style: TextStyle(
                  color: AppColors.ivorySilk,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.champagneGold),
                title: const TText('Ambil dari Kamera', style: TextStyle(color: AppColors.ivorySilk)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.champagneGold),
                title: const TText('Pilih dari Galeri', style: TextStyle(color: AppColors.ivorySilk)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final bytes = await pickedFile.readAsBytes();
      final response = await ApiService.postMultipart(
        '/api/v1/profile-picture',
        fileField: 'profile',
        filePath: pickedFile.path,
        fileBytes: bytes,
        filename: pickedFile.name,
      );

      if (!mounted) return;

      if (response != null && response['profile_picture'] != null) {
        setState(() {
          _sellerAvatar = response['profile_picture'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.champagneGold, width: 0.8),
            ),
            content: const TText(
              'Profile picture successfully updated',
              style: TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.error, width: 0.8),
          ),
          content: TText(
            'Gagal mengunggah foto: ${e.toString().replaceFirst('Exception: ', '')}',
            style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  /// Atelier / Workshop Header with quiet luxury elegance
  Widget _buildWorkshopHeader(BuildContext context) {
    final cleanUrl = _getCleanImageUrl(_sellerAvatar);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Interactive square portrait frame with Cloudinary photo & camera badge
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.charcoalVelvet,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.surfaceBorder,
                    width: 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _isUploadingAvatar
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.champagneGold,
                              ),
                            ),
                          ),
                        )
                      : cleanUrl != null
                          ? Image.network(
                              cleanUrl,
                              fit: BoxFit.cover,
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
                              errorBuilder: (_, _, _) => _buildMonogram(),
                            )
                          : _buildMonogram(),
                ),
              ),

              // Small gold camera edit badge
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.champagneGold, width: 0.8),
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 10,
                    color: AppColors.champagneGold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Workshop Name & Location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sellerName,
                style: const TextStyle(
                  color: AppColors.ivorySilk,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.champagneGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _sellerAddress,
                      style: const TextStyle(
                        color: AppColors.ashGrey,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Subtle Sync Action
        IconButton(
          onPressed: _fetchDashboardData,
          icon: const Icon(
            Icons.sync_rounded,
            color: AppColors.ashGrey,
            size: 20,
          ),
          tooltip: 'Sinkronisasi Data'.tr(context),
        ),
      ],
    );
  }

  Widget _buildMonogram() {
    final initial = _sellerName.isNotEmpty ? _sellerName[0].toUpperCase() : 'J';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.champagneGold,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Pure typographic revenue presentation (no tacky glowing gradients)
  Widget _buildRevenueLedger() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TText(
            'TOTAL PENDAPATAN TERVERIFIKASI',
            style: TextStyle(
              color: AppColors.ashGreySubtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            CurrencyFormat.toRupiah(_totalSales),
            style: const TextStyle(
              color: AppColors.champagneGold,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TText(
            '${_salesList.length} pesanan telah selesai dan diterima kolektor',
            style: const TextStyle(
              color: AppColors.ashGrey,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Balanced operational metrics split with clean vertical hairline
  Widget _buildInventoryOverview() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Total Catalog Items
          Expanded(
            child: InkWell(
              onTap: widget.onNavigateToInventory,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TText(
                      'KOLEKSI AKTIF',
                      style: TextStyle(
                        color: AppColors.ashGreySubtle,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TText(
                      '$_productCount Desain',
                      style: const TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const TText(
                      'Terdaftar di etalase',
                      style: TextStyle(
                        color: AppColors.ashGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Hairline Divider
          Container(
            width: 0.8,
            height: 48,
            color: AppColors.surfaceBorder,
          ),

          // Total Stock In Units
          Expanded(
            child: InkWell(
              onTap: widget.onNavigateToInventory,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TText(
                      'TOTAL STOK KAYU',
                      style: TextStyle(
                        color: AppColors.ashGreySubtle,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TText(
                      '$_totalStockUnits Unit',
                      style: const TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const TText(
                      'Siap diproses & dikirim',
                      style: TextStyle(
                        color: AppColors.ashGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Operational Navigation Ribbons
  Widget _buildOperationalRibbons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TText(
          'MANAJEMEN ETALASE & OPERASIONAL',
          style: TextStyle(
            color: AppColors.ashGreySubtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),

        _buildRibbonItem(
          title: 'Katalog & Inventaris Furnitur',
          subtitle: 'Perbarui harga, stok kayu, dan foto spesifikasi',
          onTap: widget.onNavigateToInventory,
        ),
        const SizedBox(height: 10),
        _buildRibbonItem(
          title: 'Otorisasi Logistik & Pengiriman',
          subtitle: 'Perbarui keberangkatan armada & verifikasi foto bukti terima',
          onTap: widget.onNavigateToDelivery,
        ),
      ],
    );
  }

  Widget _buildRibbonItem({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.charcoalVelvet,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.surfaceBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TText(
                    title,
                    style: const TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  TText(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.ashGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.champagneGold,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  /// Quiet, artisanal curatorial guidelines
  Widget _buildCuratorialNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warmBronze.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          TText(
            '✦',
            style: TextStyle(
              color: AppColors.champagneGold,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: TText(
              'Standar JatiLuxe: Setiap produk kayu jati yang didaftarkan wajib mencantumkan jenis jati (TPK Perhutani / Jati Emas) serta difoto dengan pencahayaan alami tanpa manipulasi warna serat.',
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 11,
                height: 1.45,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Clean sales ledger rows (no plastic badge icons)
  Widget _buildSalesLedger() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const TText(
              'BUKU TRANSAKSI PENJUALAN',
              style: TextStyle(
                color: AppColors.ashGreySubtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.0,
              ),
            ),
            TText(
              '${_salesList.length} Transaksi',
              style: const TextStyle(
                color: AppColors.ashGrey,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_salesList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: AppColors.charcoalVelvet,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.surfaceBorder,
                width: 0.8,
              ),
            ),
            child: const Center(
              child: TText(
                'Belum ada riwayat transaksi penjualan terbayar',
                style: TextStyle(
                  color: AppColors.ashGrey,
                  fontSize: 12,
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.charcoalVelvet,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.surfaceBorder,
                width: 0.8,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _salesList.length,
              separatorBuilder: (_, _) => const Divider(
                color: AppColors.surfaceBorder,
                height: 1,
                thickness: 0.8,
              ),
              itemBuilder: (context, index) {
                final sale = _salesList[index];
                final orderId = sale['id_order'];
                final total = sale['total_price'];
                final method = sale['payment_method'] ?? 'Transfer';
                final date = sale['pay_date'] ?? sale['order_date'];
                final orderStatus = sale['order_status'] ?? 'Selesai';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Order & Date Info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              TText(
                                'Pesanan #$orderId',
                                style: const TextStyle(
                                  color: AppColors.ivorySilk,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TText(
                                '•  $orderStatus',
                                style: const TextStyle(
                                  color: AppColors.champagneGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          TText(
                            '${DateFormatHelper.toReadable(date)} • $method',
                            style: const TextStyle(
                              color: AppColors.ashGrey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),

                      // Price Statement
                      Text(
                        CurrencyFormat.toRupiah(total),
                        style: const TextStyle(
                          color: AppColors.ivorySilk,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TText(
              'Gagal Memuat Data',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TText(
              _errorMessage ?? 'Periksa koneksi server Anda',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ashGrey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: _fetchDashboardData,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.champagneGold),
              label: const TText(
                'Muat Ulang',
                style: TextStyle(color: AppColors.champagneGold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
