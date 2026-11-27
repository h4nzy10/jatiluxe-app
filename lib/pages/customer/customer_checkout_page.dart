import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';

import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../utils/formatters.dart';
import 'payment_page.dart';

/// Customer checkout: consolidates the Direct Buy (from product detail) and
/// cart-select (from cart page) routes into a single, linear purchase flow.
///
/// The page is structured as an editorial "order counter": a compact step
/// ribbon across the top, the chosen items in the middle, and a receipt card
/// at the bottom. On confirm it POSTs to the API to create a pending order and
/// replaces itself with [PaymentPage] for settlement.
class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String? initialAddress;
  final VoidCallback? onOrderCreated;
  final String? initialPaymentMethod;
  final String sourceLabel;

  const CheckoutPage({
    super.key,
    required this.items,
    this.initialAddress,
    this.onOrderCreated,
    this.initialPaymentMethod,
    this.sourceLabel = 'Produk',
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _addressController;
  String _selectedPayment = 'transfer';
  String _selectedDelivery = 'express';
  String _addressError = '';
  bool _isPlacing = false;

  static const _steps = ['Alamat', 'Pengiriman', 'Pembayaran', 'Ringkasan'];
  int _activeStep = 0;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.initialAddress?.trim(),
    );
    _selectedPayment = widget.initialPaymentMethod ?? 'transfer';
    _selectedDelivery = 'express';
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    setState(() {
      _activeStep += 1;
      _addressError = '';
    });
  }

  void _prevStep() {
    setState(() {
      _activeStep -= 1;
      _addressError = '';
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPayment.isEmpty) {
      setState(() => _addressError = 'Metode pembayaran wajib dipilih');
      return;
    }

    setState(() {
      _isPlacing = true;
      _addressError = '';
    });

    try {
      final itemsPayload = widget.items.map((item) {
        return {
          'id_product': (item['id_product'] ?? item['product_id']) as int,
          'quantity': (item['quantity'] ?? 1) as int,
        };
      }).toList();

      final response = await ApiService.post(
        widget.items.length == 1 && widget.initialAddress != null
            ? '/api/v1/order'
            : '/api/v1/order/partial',
        {
          'items': itemsPayload,
          'shipping_address': _addressController.text.trim(),
          'payment_method': _selectedPayment,
        },
      );

      final orderId = (response is Map && response['order'] is Map)
          ? ((response['order'] as Map)['id_order'] as int?)
          : null;

      if (!mounted) return;

      if (orderId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.charcoalVelvet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(
                color: AppColors.champagneGold,
                width: 0.8,
              ),
            ),
            content: const TText(
              'Pesanan berhasil dibuat',
              style: TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            ),
          ),
        );
        widget.onOrderCreated?.call();

        final order = response is Map && response['order'] is Map
            ? Map<String, dynamic>.from(response['order'] as Map)
            : null;
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => PaymentPage(
              orderId: orderId,
              initialPaymentMethod: _selectedPayment,
              initialOrder: order,
            ),
          ),
        );
        return;
      }

      _onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.charcoalVelvet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.error, width: 0.8),
            ),
            content: TText(
              'Gagal membuat pesanan: ${e.toString().replaceFirst('Exception: ', '')}',
              style: const TextStyle(color: AppColors.ivorySilk, fontSize: 13),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  void _onSuccess() {
    // Fallback when the API response does not carry an order id.
    widget.onOrderCreated?.call();
  }

  int get _itemCount => widget.items.length;

  num get _subtotal => widget.items
      .map((i) => (i['price'] ?? 0) * (i['quantity'] ?? 0))
      .fold(0, (a, b) => a + b);

  num get _total => _subtotal;

  int _quantityOf(Map<String, dynamic> item) => (item['quantity'] ?? 1) as int;

  String _cleanImage(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final clean = url.trim();
    return clean.startsWith('http://')
        ? 'https://${clean.substring(7)}'
        : clean;
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(
      builder: (context) => Scaffold(
        backgroundColor: AppColors.obsidianBlack,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: _activeStep > 0 ? _prevStep : null,
          ),
          title: const TText(
            'Pembayaran',
            style: TextStyle(fontSize: 14, letterSpacing: 1.0),
          ),
          actions: const [LanguageSwitcher()],
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        _buildStepRibbon(),
        const SizedBox(height: 18),
        _buildContent(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStepRibbon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final active = i == _activeStep;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.champagneGold
                        : AppColors.surfaceBorder,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: active ? 1 : 0.6,
                  child: TText(
                    _steps[i],
                    style: TextStyle(
                      color: active
                          ? AppColors.champagneGold
                          : AppColors.ashGreySubtle,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.4,
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

  Widget _buildContent() {
    switch (_activeStep) {
      case 0:
        return _buildAddressStep();
      case 1:
        return _buildDeliveryStep();
      case 2:
        return _buildPaymentStep();
      case 3:
        return _buildSummaryStep();
      default:
        return _buildAddressStep();
    }
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TText(
              'Alamat Pengiriman',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const TText(
              'Masukkan alamat pengiriman. Tinggal disalin dari profil toko saat ada.',
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildAddressField(),
            if (_addressError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TText(
                  _addressError,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              label: const TText('Lanjut'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
      cursorColor: AppColors.champagneGold,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Alamat lengkap (dari profil toko)',
        hintStyle: const TextStyle(
          color: AppColors.ashGreySubtle,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.location_on_outlined,
          color: AppColors.ashGreySubtle,
          size: 18,
        ),
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
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Alamat wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildDeliveryStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TText(
              'Metode Pengiriman',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const TText(
              'Pilih armada. Status ini dipantau oleh toko sampai barang tiba.',
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildDeliveryOption('express', 'Ekspres'),
            _buildDeliveryOption('standard', 'Standar'),
            _buildDeliveryOption('nextday', 'Next Day'),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _activeStep < 3 ? _nextStep : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.champagneGold,
                side: const BorderSide(
                  color: AppColors.champagneGold,
                  width: 0.8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const TText('Lanjut'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption(String value, String label) {
    final isSelected = _selectedDelivery == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedDelivery = value);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.champagneGold
                    : AppColors.charcoalVelvet,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.champagneGold
                      : AppColors.surfaceBorder,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Icon(
                  value == 'express'
                      ? Icons.trending_up_rounded
                      : value == 'standard'
                      ? Icons.arrow_downward_rounded
                      : Icons.fast_forward_rounded,
                  color: isSelected
                      ? AppColors.obsidianBlack
                      : AppColors.ivorySilk,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TText(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.ivorySilk
                          : AppColors.ivorySilk,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  TText(
                    value == 'express'
                        ? 'Sampai 1\u20132 hari kerja'
                        : value == 'standard'
                        ? 'Sampai 3\u20135 hari kerja'
                        : 'Sampai 1 hari',
                    style: const TextStyle(
                      color: AppColors.ashGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.champagneGold
                    : AppColors.surfaceBorder,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TText(
              'Metode Pembayaran',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const TText(
              'Pilih metode pembayaran. Transaksi baru dianggap selesai saat toko konfirmasi.',
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption('transfer', 'Transfer Bank'),
            _buildPaymentOption('ewallet', 'E-Wallet'),
            _buildPaymentOption('cod', 'Cash on Delivery'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _nextStep,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              label: const TText('Lanjut'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label) {
    final isSelected = _selectedPayment == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedPayment = value);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.champagneGold
                    : AppColors.charcoalVelvet,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppColors.champagneGold
                      : AppColors.surfaceBorder,
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Icon(
                  value == 'transfer'
                      ? Icons.account_balance_wallet_rounded
                      : value == 'ewallet'
                      ? Icons.account_balance_wallet_rounded
                      : Icons.wallet_rounded,
                  color: isSelected
                      ? AppColors.obsidianBlack
                      : AppColors.ivorySilk,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TText(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.ivorySilk
                          : AppColors.ivorySilk,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  TText(
                    value == 'transfer'
                        ? 'Transfer ke rekening toko'
                        : value == 'ewallet'
                        ? 'Via aplikasi e-wallet'
                        : 'Bayar langsung saat barang tiba',
                    style: const TextStyle(
                      color: AppColors.ashGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.champagneGold
                    : AppColors.surfaceBorder,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const TText(
                  'Ringkasan & Konfirmasi',
                  style: TextStyle(
                    color: AppColors.ivorySilk,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.champagneGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: TText(
                    '$_itemCount produk',
                    style: const TextStyle(
                      color: AppColors.champagneGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildSummaryList(),
            const SizedBox(height: 14),
            _buildSummaryRow('Subtotal', CurrencyFormat.toRupiah(_subtotal)),
            const SizedBox(height: 6),
            _buildSummaryRow(
              'Pengiriman',
              _selectedDelivery == 'express'
                  ? 'Rp 15.000'
                  : _selectedDelivery == 'standard'
                  ? 'Rp 8.000'
                  : 'Rp 12.000',
            ),
            const Divider(
              color: AppColors.surfaceBorder,
              height: 1,
              thickness: 0.8,
            ),
            const SizedBox(height: 6),
            _buildSummaryRow(
              'Total',
              CurrencyFormat.toRupiah(_total),
              isTotal: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isPlacing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.champagneGold,
                foregroundColor: AppColors.obsidianBlack,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isPlacing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.obsidianBlack,
                        ),
                      ),
                    )
                  : const TText(
                      'Konfirmasi & Bayar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _isPlacing
                  ? null
                  : () {
                      if (_activeStep > 0) {
                        _prevStep();
                      } else {
                        setState(() => _activeStep = 0);
                      }
                    },
              child: const TText('Kembali ke keranjang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryList() {
    if (widget.items.isEmpty) {
      return const Center(
        child: TText(
          'Tidak ada produk dipilih',
          style: TextStyle(color: AppColors.ashGrey, fontSize: 12),
        ),
      );
    }

    return Column(
      children: widget.items.map((item) {
        final qty = _quantityOf(item);
        final price = item['price'] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.charcoalVelvet,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.surfaceBorder,
                    width: 0.6,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child:
                        item['picture'] != null &&
                            item['picture'].toString().isNotEmpty
                        ? Image.network(
                            _cleanImage(item['picture'].toString()),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 18,
                                color: AppColors.ashGreySubtle,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 18,
                              color: AppColors.ashGreySubtle,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TText(
                      (item['product_name'] ?? '').toString().toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        TText(
                          'x$qty',
                          style: const TextStyle(
                            color: AppColors.ashGrey,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          CurrencyFormat.toRupiah(price),
                          style: const TextStyle(
                            color: AppColors.champagneGoldLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormat.toRupiah(price * qty),
                style: const TextStyle(
                  color: AppColors.champagneGoldLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TText(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.champagneGold : AppColors.ashGrey,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppColors.ivorySilk : AppColors.ashGrey,
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
