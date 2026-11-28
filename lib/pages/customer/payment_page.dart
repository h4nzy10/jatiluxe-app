import 'package:flutter/material.dart';

import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../service/l10n.dart';
import '../../utils/formatters.dart';

/// Settlement screen for a single pending order.
///
/// Reached after checkout creates the order and from the payment card in the
/// order detail. The receipt and the settlement call live here instead of
/// being duplicated across both screens.
class PaymentPage extends StatefulWidget {
  final int orderId;
  final String? initialPaymentMethod;
  final Map<String, dynamic>? initialOrder;

  const PaymentPage({
    super.key,
    required this.orderId,
    this.initialPaymentMethod,
    this.initialOrder,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const List<String> _paymentMethods = [
    'Transfer Bank',
    'E-Wallet',
    'Cash on Delivery',
  ];

  bool _isLoading = true;
  bool _isPaying = false;
  String? _errorMessage;
  Map<String, dynamic>? _order;
  String _selectedMethod = 'Transfer Bank';

  @override
  void initState() {
    super.initState();
    _selectedMethod = _methodLabel(widget.initialPaymentMethod);
    if (widget.initialOrder != null) {
      _order = Map<String, dynamic>.from(widget.initialOrder!);
      _isLoading = false;
    }
    _fetchOrder();
  }

  String _methodLabel(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return 'Transfer Bank';

    switch (raw.toLowerCase()) {
      case 'ewallet':
      case 'e-wallet':
        return 'E-Wallet';
      case 'cod':
        return 'Cash on Delivery';
      case 'transfer':
        return 'Transfer Bank';
      default:
        return _paymentMethods.contains(raw) ? raw : 'Transfer Bank';
    }
  }

  bool get _isPaid =>
      (_order?['payment_status'] ?? '').toString().toLowerCase() == 'paid off';

  Future<void> _fetchOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/api/v1/orders/${widget.orderId}');
      if (!mounted) return;

      if (response is Map && response['order'] is Map) {
        final detail = Map<String, dynamic>.from(response['order'] as Map);
        final storedMethod = detail['payment_method']?.toString();
        if (storedMethod != null && storedMethod.isNotEmpty) {
          detail['payment_method'] = _methodLabel(storedMethod);
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

  Future<void> _pay() async {
    setState(() => _isPaying = true);
    try {
      await ApiService.put('/api/v1/payments', {
        'id_order': widget.orderId,
        'payment_method': _selectedMethod,
      });
      if (!mounted) return;
      _showSnack('Pembayaran berhasil dikonfirmasi', isError: false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isPaying = false);
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
    return L10nBuilder(
      builder: (context) => Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        appBar: AppBar(
          backgroundColor: AppColors.obsidianBlack,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.champagneGold,
            ),
            onPressed: () => Navigator.pop(context, false),
          ),
          title: const TText(
            'PEMBAYARAN',
            style: TextStyle(
              color: AppColors.ivorySilk,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
          actions: const [LanguageSwitcher()],
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
            : RefreshIndicator(
                color: AppColors.champagneGold,
                backgroundColor: AppColors.charcoalVelvet,
                onRefresh: _fetchOrder,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAmountCard(),
                      const SizedBox(height: 24),
                      if (_isPaid)
                        _buildPaidCard()
                      else ...[
                        _buildMethodSection(),
                        const SizedBox(height: 24),
                        _buildPayButton(),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAmountCard() {
    final statusColor = _isPaid ? AppColors.success : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.champagneGold.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TText(
                'Pesanan #${widget.orderId}',
                style: const TextStyle(
                  color: AppColors.ashGreySubtle,
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  TText(
                    _isPaid ? 'Lunas' : 'Menunggu pembayaran',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(
            color: AppColors.surfaceBorder,
            height: 1,
            thickness: 0.8,
          ),
          const SizedBox(height: 14),
          const TText(
            'TOTAL PEMBAYARAN',
            style: TextStyle(
              color: AppColors.ashGreySubtle,
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormat.toRupiah(_order?['total_price']),
            style: const TextStyle(
              color: AppColors.champagneGoldLight,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            DateFormatHelper.toReadable(_order?['order_date']),
            style: const TextStyle(color: AppColors.ashGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TText(
          'METODE PEMBAYARAN',
          style: TextStyle(
            color: AppColors.ashGreySubtle,
            fontSize: 11,
            letterSpacing: 1.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
          final selected = _selectedMethod == method;
          return GestureDetector(
            onTap: () => setState(() => _selectedMethod = method),
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
                      color: selected ? AppColors.ivorySilk : AppColors.ashGrey,
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPaying ? null : _pay,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.champagneGold,
          foregroundColor: AppColors.obsidianBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isPaying
            ? const SizedBox(
                width: 18,
                height: 18,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
      ),
    );
  }

  Widget _buildPaidCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 28,
          ),
          const SizedBox(height: 10),
          const TText(
            'Pembayaran terverifikasi',
            style: TextStyle(
              color: AppColors.ivorySilk,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const TText(
            'Pesanan Anda sedang disiapkan pengrajin.',
            style: TextStyle(
              color: AppColors.ashGrey,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
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
            child: const TText('Lihat Pesanan'),
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
              style: const TextStyle(color: AppColors.ashGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchOrder,
              child: const TText('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
