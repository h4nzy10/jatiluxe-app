import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../service/l10n.dart';
import '../../utils/formatters.dart';

/// Customer orders & real-time delivery tracking.
///
/// Follows JatiLuxe's quiet editorial aesthetic: matte walnut cards,
/// 0.8px hairline dividers, restrained champagne gold accents, and a clear
/// 4-stage delivery timeline without decorative clutter.
class CustomerOrdersPage extends StatefulWidget {
  final VoidCallback? onBrowseCatalog;

  const CustomerOrdersPage({
    super.key,
    this.onBrowseCatalog,
  });

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _orders = [];
  String _selectedFilter = 'Semua';

  static const List<String> _filters = [
    'Semua',
    'Berlangsung',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/orders'),
        ApiService.get('/api/v1/order-tracking').catchError((_) => null),
      ]);

      if (!mounted) return;

      final ordersRes = results[0];
      final trackingRes = results[1];

      final Map<int, Map<String, dynamic>> trackingByOrderId = {};
      if (trackingRes is Map && trackingRes['deliveries'] is List) {
        for (final item in trackingRes['deliveries'] as List) {
          if (item is Map) {
            final orderId = int.tryParse('${item['id_order']}');
            if (orderId != null) {
              trackingByOrderId[orderId] = Map<String, dynamic>.from(item);
            }
          }
        }
      }

      final rawOrders = ordersRes is Map && ordersRes['orders'] is List
          ? ordersRes['orders'] as List
          : <dynamic>[];

      final merged = <Map<String, dynamic>>[];
      for (final raw in rawOrders) {
        if (raw is Map) {
          final order = Map<String, dynamic>.from(raw);
          final orderId = int.tryParse('${order['id_order']}');
          if (orderId != null && trackingByOrderId.containsKey(orderId)) {
            final tr = trackingByOrderId[orderId]!;
            order['tracking_number'] ??= tr['tracking_number'];
            order['delivery_status'] ??= tr['delivery_status'];
          }
          merged.add(order);
        }
      }

      setState(() {
        _orders = merged;
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

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'Semua') return _orders;
    return _orders.where((o) {
      final status = (o['order_status'] ?? '').toString().toLowerCase();
      switch (_selectedFilter) {
        case 'Berlangsung':
          return status != 'finished' && status != 'canceled';
        case 'Selesai':
          return status == 'finished';
        case 'Dibatalkan':
          return status == 'canceled';
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _openOrderDetail(Map<String, dynamic> order) async {
    final orderId = int.tryParse('${order['id_order']}');
    if (orderId == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerOrderDetailPage(
          orderId: orderId,
          initialSummary: order,
        ),
      ),
    );

    if (changed == true && mounted) {
      await _fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildScaffold(context));
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        backgroundColor: AppColors.obsidianBlack,
        elevation: 0,
        centerTitle: false,
        title: const TText(
          'PESANAN SAYA',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _fetchOrders,
            icon: const Icon(
              Icons.sync_rounded,
              color: AppColors.ashGrey,
              size: 20,
            ),
            tooltip: 'Muat ulang'.tr(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterStrip(),
          const Divider(
            color: AppColors.surfaceBorder,
            height: 1,
            thickness: 0.8,
          ),
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
                    : _filteredOrders.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            color: AppColors.champagneGold,
                            backgroundColor: AppColors.charcoalVelvet,
                            onRefresh: _fetchOrders,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                28,
                              ),
                              itemCount: _filteredOrders.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) =>
                                  _buildOrderCard(_filteredOrders[index]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStrip() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final label = _filters[index];
          final selected = label == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = label),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TText(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.champagneGold
                        : AppColors.ashGrey,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 1.5,
                  width: selected ? 20 : 0,
                  color: AppColors.champagneGold,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id_order'];
    final orderDate = order['order_date'];
    final totalPrice = order['total_price'];
    final orderStatus = (order['order_status'] ?? 'Process').toString();
    final paymentStatus = (order['payment_status'] ?? '-').toString();
    final deliveryStatus = order['delivery_status']?.toString();
    final trackingNumber = order['tracking_number']?.toString();

    final statusMeta = _resolveOrderStatusMeta(
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
      deliveryStatus: deliveryStatus,
    );

    final needsProof = deliveryStatus == 'Out for delivery' &&
        orderStatus.toLowerCase() != 'canceled' &&
        orderStatus.toLowerCase() != 'finished';

    final needsPayment =
        paymentStatus.toLowerCase() == 'waiting for payment' &&
            orderStatus.toLowerCase() != 'canceled';

    return InkWell(
      onTap: () => _openOrderDetail(order),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.charcoalVelvet,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: needsProof
                ? AppColors.champagneGold.withOpacity(0.45)
                : AppColors.surfaceBorder,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top header: Order ID & subtle dot status
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TText(
                          'Pesanan #$orderId',
                          style: const TextStyle(
                            color: AppColors.ivorySilk,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormatHelper.toReadable(orderDate),
                          style: const TextStyle(
                            color: AppColors.ashGreySubtle,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusMeta.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      TText(
                        statusMeta.label,
                        style: TextStyle(
                          color: statusMeta.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Optional tracking reference or payment cue
            if (trackingNumber != null && trackingNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 14,
                      color: AppColors.ashGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      trackingNumber,
                      style: const TextStyle(
                        color: AppColors.champagneGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(
              color: AppColors.surfaceBorder,
              height: 1,
              thickness: 0.8,
            ),

            // Footer: Total & detail cue
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TText(
                        'TOTAL PEMBAYARAN',
                        style: TextStyle(
                          color: AppColors.ashGreySubtle,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        CurrencyFormat.toRupiah(totalPrice),
                        style: const TextStyle(
                          color: AppColors.ivorySilk,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TText(
                        needsPayment
                            ? 'Bayar Sekarang'
                            : needsProof
                                ? 'Konfirmasi Terima'
                                : 'Lihat Detail',
                        style: TextStyle(
                          color: (needsPayment || needsProof)
                              ? AppColors.champagneGold
                              : AppColors.ashGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: (needsPayment || needsProof)
                            ? AppColors.champagneGold
                            : AppColors.ashGrey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: AppColors.ashGreySubtle,
            ),
            const SizedBox(height: 16),
            const TText(
              'Belum ada pesanan',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const TText(
              'Pesanan furnitur jati Anda akan tampil di sini lengkap dengan status pengiriman.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            if (widget.onBrowseCatalog != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: widget.onBrowseCatalog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.champagneGold,
                  side: const BorderSide(
                    color: AppColors.champagneGold,
                    width: 0.8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const TText(
                  'Jelajahi Katalog',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
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
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.ashGreySubtle,
            ),
            const SizedBox(height: 16),
            const TText(
              'Gagal memuat daftar pesanan',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ashGrey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _fetchOrders,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.champagneGold,
                side: const BorderSide(
                  color: AppColors.champagneGold,
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const TText('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Detailed order receipt, 4-stage delivery tracking timeline, payment settlement,
/// order cancellation, and delivery proof upload.
class CustomerOrderDetailPage extends StatefulWidget {
  final int orderId;
  final Map<String, dynamic>? initialSummary;

  const CustomerOrderDetailPage({
    super.key,
    required this.orderId,
    this.initialSummary,
  });

  @override
  State<CustomerOrderDetailPage> createState() =>
      _CustomerOrderDetailPageState();
}

class _CustomerOrderDetailPageState extends State<CustomerOrderDetailPage> {
  bool _isLoading = true;
  bool _isMutating = false;
  bool _hasChanges = false;
  String? _errorMessage;

  Map<String, dynamic>? _order;
  String _selectedPaymentMethod = 'Transfer Bank';
  XFile? _proofFile;
  Uint8List? _proofBytes;

  static const List<String> _paymentMethods = [
    'Transfer Bank',
    'E-Wallet',
    'Cash on Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _order = widget.initialSummary != null
        ? Map<String, dynamic>.from(widget.initialSummary!)
        : null;
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/orders/${widget.orderId}'),
        ApiService.get('/api/v1/order-tracking/${widget.orderId}')
            .catchError((_) => null),
      ]);

      if (!mounted) return;

      final orderRes = results[0];
      final trackRes = results[1];

      if (orderRes is Map && orderRes['order'] is Map) {
        final detail = Map<String, dynamic>.from(orderRes['order'] as Map);
        if (trackRes is Map && trackRes['delivery'] is Map) {
          final d = trackRes['delivery'] as Map;
          detail['tracking_number'] ??= d['tracking_number'];
          detail['delivery_status'] ??= d['delivery_status'];
        }
        setState(() {
          _order = detail;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Data pesanan tidak ditemukan';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _payOrder() async {
    setState(() => _isMutating = true);
    try {
      await ApiService.put('/api/v1/payments', {
        'id_order': widget.orderId,
        'payment_method': _selectedPaymentMethod,
      });
      if (!mounted) return;
      _hasChanges = true;
      await _fetchOrderDetail();
      _showSnack('Pembayaran berhasil dikonfirmasi', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        title: const TText(
          'Batalkan Pesanan',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const TText(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dikembalikan.',
          style: TextStyle(color: AppColors.ashGrey, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const TText(
              'Kembali',
              style: TextStyle(color: AppColors.ashGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.ivorySilk,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const TText('Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isMutating = true);
    try {
      await ApiService.put('/api/v1/order/${widget.orderId}/cancel', {});
      if (!mounted) return;
      _hasChanges = true;
      await _fetchOrderDetail();
      _showSnack('Pesanan berhasil dibatalkan', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TText(
                'UNGGAH BUKTI PENERIMAAN',
                style: TextStyle(
                  color: AppColors.ashGreySubtle,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.champagneGold,
                ),
                title: const TText(
                  'Ambil dari Kamera',
                  style: TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.champagneGold,
                ),
                title: const TText(
                  'Pilih dari Galeri',
                  style: TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _proofFile = picked;
        _proofBytes = bytes;
      });
    }
  }

  Future<void> _submitDeliveryProof() async {
    if (_proofBytes == null) return;

    setState(() => _isMutating = true);
    try {
      await ApiService.postMultipart(
        '/api/v1/delivery/${widget.orderId}/confirm',
        fileField: 'proof',
        filePath: _proofFile?.path,
        fileBytes: _proofBytes,
        filename: _proofFile?.name ?? 'proof.jpg',
      );
      if (!mounted) return;
      _hasChanges = true;
      setState(() {
        _proofFile = null;
        _proofBytes = null;
      });
      await _fetchOrderDetail();
      _showSnack(
        'Bukti penerimaan berhasil dikirim ke pengrajin',
        isError: false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
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
        content: Text(
          message,
          style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context, _hasChanges);
        }
      },
      child: L10nBuilder(
        builder: (context) => Scaffold(
          backgroundColor: AppColors.obsidianBlack,
          appBar: AppBar(
            backgroundColor: AppColors.obsidianBlack,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.champagneGold,
              ),
              onPressed: () => Navigator.pop(context, _hasChanges),
            ),
            title: TText(
              'PESANAN #${widget.orderId}',
              style: const TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _isLoading ? null : _fetchOrderDetail,
                icon: const Icon(
                  Icons.sync_rounded,
                  size: 20,
                  color: AppColors.ashGrey,
                ),
              ),
            ],
          ),
          body: _isLoading && _order == null
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
              : _errorMessage != null && _order == null
                  ? _buildErrorView()
                  : _buildDetailBody(),
        ),
      ),
    );
  }

  Widget _buildDetailBody() {
    final order = _order!;
    final orderStatus = (order['order_status'] ?? 'Process').toString();
    final paymentStatus = (order['payment_status'] ?? '-').toString();
    final paymentMethod = (order['payment_method'] ?? '-').toString();
    final deliveryStatus = order['delivery_status']?.toString();
    final trackingNumber = order['tracking_number']?.toString();
    final orderDate = order['order_date'];
    final totalPrice = order['total_price'];
    final items = order['items'] is List
        ? List<Map<String, dynamic>>.from(
            (order['items'] as List).whereType<Map>().map(
                  (e) => Map<String, dynamic>.from(e),
                ),
          )
        : <Map<String, dynamic>>[];

    final isCanceled = orderStatus.toLowerCase() == 'canceled';
    final isFinished = orderStatus.toLowerCase() == 'finished';
    final isWaitingPayment =
        paymentStatus.toLowerCase() == 'waiting for payment' && !isCanceled;
    final canUploadProof =
        deliveryStatus == 'Out for delivery' && !isCanceled && !isFinished;
    final canCancel = !isCanceled &&
        !isFinished &&
        deliveryStatus != 'Out for delivery' &&
        deliveryStatus != 'Arrived';

    final statusMeta = _resolveOrderStatusMeta(
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
      deliveryStatus: deliveryStatus,
    );

    return RefreshIndicator(
      color: AppColors.champagneGold,
      backgroundColor: AppColors.charcoalVelvet,
      onRefresh: _fetchOrderDetail,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Order Status & Tracking Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.charcoalVelvet,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const TText(
                        'STATUS PESANAN',
                        style: TextStyle(
                          color: AppColors.ashGreySubtle,
                          fontSize: 10,
                          letterSpacing: 1.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusMeta.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          TText(
                            statusMeta.label,
                            style: TextStyle(
                              color: statusMeta.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    DateFormatHelper.toReadable(orderDate),
                    style: const TextStyle(
                      color: AppColors.ashGrey,
                      fontSize: 12,
                    ),
                  ),
                  if (trackingNumber != null && trackingNumber.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(
                      color: AppColors.surfaceBorder,
                      height: 1,
                      thickness: 0.8,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const TText(
                          'NO. RESI PENGIRIMAN',
                          style: TextStyle(
                            color: AppColors.ashGreySubtle,
                            fontSize: 10,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          trackingNumber,
                          style: const TextStyle(
                            color: AppColors.champagneGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Delivery Timeline (when not canceled)
            if (!isCanceled) ...[
              const TText(
                'PELACAKAN PENGIRIMAN',
                style: TextStyle(
                  color: AppColors.ashGreySubtle,
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeliveryTimeline(
                paymentStatus: paymentStatus,
                deliveryStatus: deliveryStatus,
                orderStatus: orderStatus,
              ),
              const SizedBox(height: 24),
            ],

            // 3. Delivery Proof Upload (when Out for delivery)
            if (canUploadProof) ...[
              _buildProofUploadSection(),
              const SizedBox(height: 24),
            ],

            // 4. Payment Settlement Section (when Waiting for payment)
            if (isWaitingPayment) ...[
              _buildPaymentSection(),
              const SizedBox(height: 24),
            ],

            // 5. Ordered Items Receipt
            const TText(
              'RINCIAN PRODUK',
              style: TextStyle(
                color: AppColors.ashGreySubtle,
                fontSize: 11,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.charcoalVelvet,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(18),
                      child: TText(
                        'Memuat rincian item...',
                        style: TextStyle(
                          color: AppColors.ashGrey,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(
                        color: AppColors.surfaceBorder,
                        height: 1,
                        thickness: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final name = (item['product_name'] ?? '-').toString();
                        final qty = item['quantity'] ?? 1;
                        final subtotal = item['subtotal'] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppColors.ivorySilk,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$qty unit',
                                      style: const TextStyle(
                                        color: AppColors.ashGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                CurrencyFormat.toRupiah(subtotal),
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

                  const Divider(
                    color: AppColors.surfaceBorder,
                    height: 1,
                    thickness: 0.8,
                  ),

                  // Payment & Total Footer
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const TText(
                              'Metode Pembayaran',
                              style: TextStyle(
                                color: AppColors.ashGrey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              paymentMethod == '-' ? 'Belum dipilih' : paymentMethod,
                              style: const TextStyle(
                                color: AppColors.ivorySilk,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const TText(
                              'Total Pembayaran',
                              style: TextStyle(
                                color: AppColors.ivorySilk,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              CurrencyFormat.toRupiah(totalPrice),
                              style: const TextStyle(
                                color: AppColors.champagneGold,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
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

            // 6. Cancel Order Action
            if (canCancel) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isMutating ? null : _cancelOrder,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withOpacity(0.5),
                      width: 0.8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const TText(
                    'Batalkan Pesanan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimeline({
    required String paymentStatus,
    required String? deliveryStatus,
    required String orderStatus,
  }) {
    final isPaid = paymentStatus.toLowerCase() == 'paid off';
    final isOut = deliveryStatus == 'Out for delivery' ||
        deliveryStatus == 'Arrived' ||
        orderStatus.toLowerCase() == 'finished';
    final isArrived =
        deliveryStatus == 'Arrived' || orderStatus.toLowerCase() == 'finished';

    final steps = [
      (
        title: 'Pesanan Dibuat',
        subtitle: isPaid
            ? 'Pembayaran terverifikasi'
            : 'Menunggu penyelesaian pembayaran',
        done: true,
        active: !isPaid,
      ),
      (
        title: 'Diproses Pengrajin',
        subtitle: 'Furnitur disiapkan & dikemas untuk armada',
        done: isPaid,
        active: isPaid && !isOut,
      ),
      (
        title: 'Dalam Pengiriman',
        subtitle: 'Armada menuju alamat tujuan Anda',
        done: isOut,
        active: isOut && !isArrived,
      ),
      (
        title: 'Pesanan Tiba',
        subtitle: 'Diterima oleh kolektor',
        done: isArrived,
        active: isArrived,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final step = steps[i];
          final isLast = i == steps.length - 1;
          final dotColor =
              step.done ? AppColors.champagneGold : AppColors.ashGreySubtle;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      Container(
                        width: step.active ? 11 : 8,
                        height: step.active ? 11 : 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: step.done
                              ? AppColors.champagneGold
                              : AppColors.obsidianBlack,
                          shape: BoxShape.circle,
                          border: Border.all(color: dotColor, width: 1.5),
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: step.done && steps[i + 1].done
                                ? AppColors.champagneGold.withOpacity(0.6)
                                : AppColors.surfaceBorder,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TText(
                          step.title,
                          style: TextStyle(
                            color: step.done
                                ? AppColors.ivorySilk
                                : AppColors.ashGrey,
                            fontSize: 13,
                            fontWeight: step.active
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        TText(
                          step.subtitle,
                          style: const TextStyle(
                            color: AppColors.ashGreySubtle,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProofUploadSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.champagneGold.withOpacity(0.45),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TText(
            'KONFIRMASI PENERIMAAN BARANG',
            style: TextStyle(
              color: AppColors.champagneGold,
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const TText(
            'Unggah foto barang yang telah Anda terima agar pengrajin dapat memverifikasi dan menyelesaikan pesanan.',
            style: TextStyle(
              color: AppColors.ashGrey,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          if (_proofBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                _proofBytes!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isMutating ? null : _pickProofImage,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ashGrey,
                      side: const BorderSide(
                        color: AppColors.surfaceBorder,
                        width: 0.8,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const TText(
                      'Ganti Foto',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isMutating ? null : _submitDeliveryProof,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.champagneGold,
                      foregroundColor: AppColors.obsidianBlack,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isMutating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.obsidianBlack,
                              ),
                            ),
                          )
                        : const TText(
                            'Kirim Bukti Penerimaan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ] else
            OutlinedButton.icon(
              onPressed: _isMutating ? null : _pickProofImage,
              icon: const Icon(
                Icons.camera_alt_outlined,
                size: 16,
                color: AppColors.champagneGold,
              ),
              label: const TText(
                'Pilih atau Ambil Foto Bukti',
                style: TextStyle(
                  color: AppColors.champagneGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                side: const BorderSide(
                  color: AppColors.champagneGold,
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.champagneGold.withOpacity(0.45),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TText(
            'SELESAIKAN PEMBAYARAN',
            style: TextStyle(
              color: AppColors.champagneGold,
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const TText(
            'Pilih metode pembayaran untuk memproses pesanan dan menerbitkan resi pengiriman.',
            style: TextStyle(
              color: AppColors.ashGrey,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ..._paymentMethods.map((method) {
            final selected = _selectedPaymentMethod == method;
            return GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = method),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.obsidianBlack,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? AppColors.champagneGold
                        : AppColors.surfaceBorder,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 16,
                      color: selected
                          ? AppColors.champagneGold
                          : AppColors.ashGreySubtle,
                    ),
                    const SizedBox(width: 10),
                    TText(
                      method,
                      style: TextStyle(
                        color: selected
                            ? AppColors.ivorySilk
                            : AppColors.ashGrey,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isMutating ? null : _payOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.champagneGold,
                foregroundColor: AppColors.obsidianBlack,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isMutating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.obsidianBlack,
                        ),
                      ),
                    )
                  : const TText(
                      'Bayar Sekarang',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
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
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.ashGreySubtle,
            ),
            const SizedBox(height: 16),
            const TText(
              'Gagal memuat detail pesanan',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ashGrey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _fetchOrderDetail,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.champagneGold,
                side: const BorderSide(
                  color: AppColors.champagneGold,
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const TText('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

({String label, Color color}) _resolveOrderStatusMeta({
  required String orderStatus,
  required String paymentStatus,
  required String? deliveryStatus,
}) {
  final os = orderStatus.toLowerCase();
  final ps = paymentStatus.toLowerCase();

  if (os == 'canceled') {
    return (label: 'Dibatalkan', color: AppColors.error);
  }
  if (os == 'finished' || deliveryStatus == 'Arrived') {
    return (label: 'Selesai', color: AppColors.success);
  }
  if (ps == 'waiting for payment') {
    return (label: 'Menunggu Pembayaran', color: AppColors.warning);
  }
  if (deliveryStatus == 'Out for delivery') {
    return (label: 'Dikirim', color: AppColors.champagneGold);
  }
  return (label: 'Diproses', color: AppColors.warning);
}
