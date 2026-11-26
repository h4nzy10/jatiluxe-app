import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../utils/formatters.dart';

class SellerDeliveryPage extends StatefulWidget {
  const SellerDeliveryPage({super.key});

  @override
  State<SellerDeliveryPage> createState() => _SellerDeliveryPageState();
}

class _SellerDeliveryPageState extends State<SellerDeliveryPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _deliveries = [];

  late TabController _tabController;

  // Tab 0 = "Aktif" (In process + Out for delivery), Tab 1 = "Selesai" (Arrived/Finished)
  static const List<String> _tabLabels = ['Aktif', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDeliveries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchDeliveries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final res = await ApiService.get('/api/v1/seller-deliveries');
      if (!mounted) return;
      setState(() {
        _deliveries = res['deliveries'] ?? [];
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

  List<dynamic> get _activeDeliveries => _deliveries.where((d) {
        final s = d['delivery_status'] ?? '';
        return s == 'In process' || s == 'Out for delivery';
      }).toList();

  List<dynamic> get _finishedDeliveries => _deliveries.where((d) {
        final s = d['delivery_status'] ?? '';
        final os = d['order_status'] ?? '';
        return s == 'Arrived' || os == 'Finished';
      }).toList();

  Future<void> _updateDeliveryStatus(int idDelivery, String newStatus) async {
    try {
      await ApiService.put('/api/v1/delivery/$idDelivery/status',
          {'delivery_status': newStatus});
      if (!mounted) return;
      await _fetchDeliveries();
      _showSnack('Status armada diperbarui ke "$newStatus"', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal memperbarui status: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true);
    }
  }

  Future<void> _finishDelivery(int idApply) async {
    try {
      await ApiService.put('/api/v1/delivery-apply/$idApply/finish', {});
      if (!mounted) return;
      await _fetchDeliveries();
      _showSnack('Pesanan telah diselesaikan', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal menyelesaikan pesanan: ${e.toString().replaceFirst('Exception: ', '')}',
          isError: true);
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
        content: TText(
          message,
          style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
        ),
      ),
    );
  }

  void _showProofDialog(String proofUrl) {
    final clean = proofUrl.trim().startsWith('http://')
        ? 'https://${proofUrl.trim().substring(7)}'
        : proofUrl.trim();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.charcoalVelvet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TText(
                'BUKTI PENERIMAAN BARANG',
                style: TextStyle(
                  color: AppColors.ashGreySubtle,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  clean,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.champagneGold),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => Container(
                    height: 160,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const TText(
                      'Gagal memuat gambar bukti',
                      style: TextStyle(color: AppColors.ashGrey, fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const TText(
                    'Tutup',
                    style: TextStyle(color: AppColors.champagneGold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateStatusSheet(Map<String, dynamic> delivery) {
    final idDelivery = delivery['id_delivery'] as int;
    final currentStatus = delivery['delivery_status'] ?? 'In process';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: TText(
                      'PERBARUI STATUS ARMADA',
                      style: TextStyle(
                        color: AppColors.ashGreySubtle,
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.ashGrey, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TText(
                'No. Lacak  ${delivery['tracking_number'] ?? '-'}',
                style: const TextStyle(
                  color: AppColors.ivorySilk,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              // Pipeline visual
              _buildStatusPipeline(currentStatus),
              const SizedBox(height: 24),

              if (currentStatus == 'In process')
                _buildActionButton(
                  label: 'Tandai "Dikirim" — Barang Keluar Gudang',
                  icon: Icons.local_shipping_rounded,
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateDeliveryStatus(idDelivery, 'Out for delivery');
                  },
                )
              else if (currentStatus == 'Out for delivery')
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalVelvet,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.surfaceBorder, width: 0.8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.hourglass_top_rounded,
                          color: AppColors.warning, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: TText(
                          'Menunggu konfirmasi penerimaan dari pelanggan',
                          style: TextStyle(
                            color: AppColors.ashGrey,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinishConfirmDialog(int idApply, String trackingNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        title: const TText(
          'Selesaikan Pesanan',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TText(
          'Pesanan no. $trackingNumber telah diterima dan diverifikasi. Konfirmasi untuk menyelesaikan transaksi?',
          style: const TextStyle(color: AppColors.ashGrey, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const TText('Batal',
                style: TextStyle(color: AppColors.ashGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
              foregroundColor: AppColors.obsidianBlack,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _finishDelivery(idApply);
            },
            child: const TText('Selesaikan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Tab bar header
            _buildTabHeader(context),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.champagneGold),
                        ),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildList(_activeDeliveries, isActive: true),
                            _buildList(_finishedDeliveries, isActive: false),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      decoration: const BoxDecoration(
        color: AppColors.obsidianBlack,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TText(
                      'MANAJEMEN ARMADA',
                      style: TextStyle(
                        color: AppColors.ashGreySubtle,
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TText(
                      '${_activeDeliveries.length} pengiriman aktif',
                      style: const TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _fetchDeliveries,
                icon: const Icon(Icons.sync_rounded,
                    color: AppColors.ashGrey, size: 20),
                tooltip: 'Muat ulang'.tr(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.champagneGold,
            unselectedLabelColor: AppColors.ashGrey,
            indicatorColor: AppColors.champagneGold,
            indicatorWeight: 1.5,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            tabs: _tabLabels
                .map((l) => Tab(text: l))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<dynamic> items, {required bool isActive}) {
    if (items.isEmpty) {
      return _buildEmptyState(isActive);
    }

    return RefreshIndicator(
      color: AppColors.champagneGold,
      backgroundColor: AppColors.charcoalVelvet,
      onRefresh: _fetchDeliveries,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _buildDeliveryCard(items[i]),
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> d) {
    final trackingNo = d['tracking_number'] ?? '-';
    final deliveryStatus = d['delivery_status'] ?? 'In process';
    final orderStatus = d['order_status'] ?? '-';
    final customerName = d['customer_name'] ?? 'Pelanggan';
    final productsSummary = d['products_summary'] ?? '-';
    final totalPrice = d['total_price'];
    final orderId = d['id_order'];
    final idApply = d['id_apply'];
    final proofUrl = d['proof'];
    final applyStatus = d['apply_status'];
    final orderDate = d['order_date'];

    final bool hasProof = proofUrl != null && proofUrl.toString().isNotEmpty;
    final bool canFinish = hasProof && idApply != null && orderStatus != 'Finished';
    final bool isFinished = orderStatus == 'Finished';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFinished
              ? AppColors.warmBronze.withValues(alpha: 0.3)
              : AppColors.surfaceBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status indicator line
                Container(
                  width: 3,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(deliveryStatus),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Info block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              trackingNo,
                              style: const TextStyle(
                                color: AppColors.champagneGold,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          _buildStatusPill(deliveryStatus),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TText(
                        'Pesanan #$orderId · $customerName',
                        style: const TextStyle(
                          color: AppColors.ivorySilk,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (orderDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          DateFormatHelper.toReadable(orderDate.toString()),
                          style: const TextStyle(
                            color: AppColors.ashGreySubtle,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hairline
          const Divider(
              color: AppColors.surfaceBorder, height: 1, thickness: 0.8),

          // Products & Price
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TText(
                        'PRODUK',
                        style: TextStyle(
                          color: AppColors.ashGreySubtle,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productsSummary,
                        style: const TextStyle(
                          color: AppColors.ashGrey,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const TText(
                      'NILAI',
                      style: TextStyle(
                        color: AppColors.ashGreySubtle,
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormat.toRupiah(totalPrice ?? 0),
                      style: const TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Proof of delivery section (if exists)
          if (hasProof) ...[
            const Divider(
                color: AppColors.surfaceBorder, height: 1, thickness: 0.8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined,
                      color: AppColors.champagneGold, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const TText(
                          'Bukti penerimaan dari pelanggan',
                          style: TextStyle(
                            color: AppColors.ivorySilk,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (applyStatus != null)
                          TText(
                            'Status: $applyStatus',
                            style: const TextStyle(
                              color: AppColors.ashGrey,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showProofDialog(proofUrl),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                    child: const TText(
                      'Lihat Foto',
                      style: TextStyle(
                        color: AppColors.champagneGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action row
          if (!isFinished) ...[
            const Divider(
                color: AppColors.surfaceBorder, height: 1, thickness: 0.8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  // Update status button
                  if (deliveryStatus != 'Arrived')
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ivorySilk,
                          side: const BorderSide(
                              color: AppColors.surfaceBorder, width: 0.8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showUpdateStatusSheet(d),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.edit_road_rounded,
                                size: 15, color: AppColors.ashGrey),
                            SizedBox(width: 6),
                            TText(
                              'Perbarui Status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ashGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (canFinish) ...[
                    if (deliveryStatus != 'Arrived') const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.champagneGold,
                          foregroundColor: AppColors.obsidianBlack,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _showFinishConfirmDialog(
                            idApply, trackingNo),
                        child: const TText(
                          'Selesaikan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Finished ribbon
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.25), width: 0.8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppColors.success, size: 15),
                  SizedBox(width: 8),
                  TText(
                    'Transaksi selesai — Barang diterima kolektor',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'In process':
        return AppColors.warning;
      case 'Out for delivery':
        return AppColors.champagneGold;
      case 'Arrived':
        return AppColors.success;
      default:
        return AppColors.ashGrey;
    }
  }

  Widget _buildStatusPill(String status) {
    final color = _statusColor(status);
    final label = _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: TText(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'In process':
        return 'Diproses';
      case 'Out for delivery':
        return 'Dikirim';
      case 'Arrived':
        return 'Tiba';
      default:
        return status;
    }
  }

  Widget _buildStatusPipeline(String currentStatus) {
    final stages = ['In process', 'Out for delivery', 'Arrived'];
    final currentIdx = stages.indexOf(currentStatus);

    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final leftDone = (i ~/ 2) < currentIdx;
          return Expanded(
            child: Container(
              height: 1.5,
              color: leftDone
                  ? AppColors.champagneGold
                  : AppColors.surfaceBorder,
            ),
          );
        }
        final stageIdx = i ~/ 2;
        final isDone = stageIdx <= currentIdx;
        final isActive = stageIdx == currentIdx;
        final color = isDone ? AppColors.champagneGold : AppColors.ashGreySubtle;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isActive ? 12 : 8,
              height: isActive ? 12 : 8,
              decoration: BoxDecoration(
                color: isDone ? AppColors.champagneGold : AppColors.surfaceBorder,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? AppColors.champagneGold : AppColors.ashGreySubtle,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            TText(
              _stageShortLabel(stages[stageIdx]),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }

  String _stageShortLabel(String s) {
    switch (s) {
      case 'In process':
        return 'Diproses';
      case 'Out for delivery':
        return 'Dikirim';
      case 'Arrived':
        return 'Tiba';
      default:
        return s;
    }
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.champagneGold,
        foregroundColor: AppColors.obsidianBlack,
        elevation: 0,
        minimumSize: const Size(double.infinity, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          TText(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isActive) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive
                  ? Icons.local_shipping_outlined
                  : Icons.inventory_2_outlined,
              size: 44,
              color: AppColors.ashGreySubtle,
            ),
            const SizedBox(height: 16),
            TText(
              isActive
                  ? 'Tidak ada pengiriman aktif'
                  : 'Belum ada pesanan selesai',
              style: const TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TText(
              isActive
                  ? 'Pesanan yang sedang dalam proses pengiriman akan muncul di sini'
                  : 'Transaksi yang telah selesai dan diterima kolektor akan tercatat di sini',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ashGrey,
                fontSize: 12,
                height: 1.5,
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
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.ashGreySubtle),
            const SizedBox(height: 16),
            const TText(
              'Gagal memuat data logistik',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TText(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.ashGrey, fontSize: 12),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _fetchDeliveries,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.champagneGold,
                side: const BorderSide(color: AppColors.champagneGold, width: 0.8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const TText('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
