import 'package:flutter/material.dart';
import 'package:jatiluxe_app/service/l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/theme.dart';
import '../../service/api.dart';

class SellerProfilePage extends StatefulWidget {
  final VoidCallback? onNavigateToInventory;
  final VoidCallback? onOpenOnboarding;

  const SellerProfilePage({
    super.key,
    this.onNavigateToInventory,
    this.onOpenOnboarding,
  });

  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _currentPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _obscurePassword = true;
  bool _obscureCurrentPassword = true;
  String? _errorMessage;

  String _sellerName = '';
  String _sellerAddress = '';
  String? _avatarUrl;
  int _productCount = 0;
  int _stockUnits = 0;

  // Last values received from the server, used to detect no-op saves.
  String _savedName = '';
  String _savedEmail = '';
  String _savedPhone = '';
  String _savedAddress = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.get('/api/v1/profile'),
        ApiService.get('/api/v1/seller-products').catchError((_) => null),
      ]);

      if (!mounted) return;

      final profileRes = results[0];
      final rawUser = profileRes is Map ? profileRes['user'] : null;
      if (rawUser == null) {
        throw Exception('Data profil workshop tidak ditemukan.');
      }
      final user = Map<String, dynamic>.from(rawUser as Map);

      final productsRes = results[1];
      int productCount = 0;
      int stockUnits = 0;
      if (productsRes is Map && productsRes['products'] is List) {
        final products = productsRes['products'] as List;
        productCount = products.length;
        stockUnits = products.fold<int>(
          0,
          (sum, item) =>
              sum + (int.tryParse(item['stock']?.toString() ?? '0') ?? 0),
        );
      }

      final name = (user['nama'] ?? '').toString();
      final address = (user['alamat'] ?? '').toString();
      final email = (user['email'] ?? '').toString();
      final phone = (user['no_hp'] ?? '').toString();

      setState(() {
        _sellerName = name;
        _sellerAddress = address;
        _avatarUrl = user['profile']?.toString();
        _productCount = productCount;
        _stockUnits = stockUnits;
        _savedName = name;
        _savedEmail = email;
        _savedPhone = phone;
        _savedAddress = address;
        _nameController.text = name;
        _emailController.text = email;
        _phoneController.text = phone;
        _addressController.text = address;
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    final currentPassword = _currentPasswordController.text.trim();

    if (password.isNotEmpty) {
      if (currentPassword.isEmpty) {
        _showSnack('Kata sandi saat ini wajib diisi', isError: true);
        return;
      }
      if (password.length < 6) {
        _showSnack('Kata sandi baru minimal 6 karakter', isError: true);
        return;
      }
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    final hasChanges = name != _savedName ||
        email != _savedEmail ||
        phone != _savedPhone ||
        address != _savedAddress ||
        password.isNotEmpty;

    if (!hasChanges) {
      _showSnack('Tidak ada perubahan untuk disimpan', isError: false);
      return;
    }

    final payload = <String, dynamic>{
      'nama': name,
      'email': email,
      'no_hp': phone,
      'alamat': address,
    };
    if (password.isNotEmpty) {
      payload['current_password'] = currentPassword;
      payload['password'] = password;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService.put('/api/v1/profile', payload);
      if (!mounted) return;
      setState(() {
        _sellerName = name;
        _sellerAddress = address;
        _savedName = name;
        _savedEmail = email;
        _savedPhone = phone;
        _savedAddress = address;
        _currentPasswordController.clear();
        _passwordController.clear();
      });
      _showSnack('Profil workshop berhasil disimpan', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Gagal menyimpan profil: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TText(
                'FOTO PROFIL WORKSHOP',
                style: TextStyle(
                  color: AppColors.ashGreySubtle,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.champagneGold),
                title: const TText('Ambil dari Kamera',
                    style: TextStyle(color: AppColors.ivorySilk, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.champagneGold),
                title: const TText('Pilih dari Galeri',
                    style: TextStyle(color: AppColors.ivorySilk, fontSize: 14)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isPermanentlyDenied) {
        _showSnack(
          'Izin kamera ditolak. Aktifkan dari pengaturan perangkat.',
          isError: true,
          actionLabel: 'Pengaturan',
          onAction: openAppSettings,
        );
        return;
      }
      if (!status.isGranted) {
        _showSnack('Izin kamera diperlukan untuk mengambil foto', isError: true);
        return;
      }
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final response = await ApiService.postMultipart(
        '/api/v1/profile-picture',
        fileField: 'profile',
        filePath: picked.path,
      );
      if (!mounted) return;

      final url = response is Map
          ? (response['profile_picture'] ?? response['profile'])?.toString()
          : null;
      if (url != null && url.isNotEmpty) {
        setState(() => _avatarUrl = url);
      }
      _showSnack('Foto profil workshop diperbarui', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Gagal mengunggah foto: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showSnack(
    String message, {
    required bool isError,
    String? actionLabel,
    VoidCallback? onAction,
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
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel.tr(context),
                textColor: AppColors.champagneGold,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  String? _cleanImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    return clean.startsWith('http://')
        ? 'https://${clean.substring(7)}'
        : clean;
  }

  String? _requiredField(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return L10nBuilder(builder: (context) => _buildPage(context));
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
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
                : RefreshIndicator(
                    color: AppColors.champagneGold,
                    backgroundColor: AppColors.charcoalVelvet,
                    onRefresh: _fetchProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHero(),
                            const SizedBox(height: 24),
                            _buildStats(),
                            const SizedBox(height: 14),
                            _buildOnboardingCard(),
                            const SizedBox(height: 28),
                            _buildSectionTitle('IDENTITAS PENGRAJIN'),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _nameController,
                              label: 'Nama workshop / pengrajin',
                              icon: Icons.storefront_outlined,
                              validator: (v) =>
                                  _requiredField(v, 'Nama workshop'),
                            ),
                            _buildField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.alternate_email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final required = _requiredField(v, 'Email');
                                if (required != null) return required;
                                final emailRegex = RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                return emailRegex.hasMatch(v!.trim())
                                    ? null
                                    : 'Format email tidak valid'.tr(context);
                              },
                            ),
                            _buildField(
                              controller: _phoneController,
                              label: 'Nomor telepon',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  _requiredField(v, 'Nomor telepon'),
                            ),
                            _buildField(
                              controller: _addressController,
                              label: 'Alamat galeri',
                              icon: Icons.location_on_outlined,
                              keyboardType: TextInputType.multiline,
                              maxLines: 2,
                              validator: (v) => _requiredField(v, 'Alamat'),
                            ),
                            const SizedBox(height: 2),
                            _buildSectionTitle('KEAMANAN AKUN'),
                            const SizedBox(height: 6),
                            const TText(
                              'Kata sandi saat ini wajib diisi untuk mengubah kata sandi.',
                              style: TextStyle(
                                color: AppColors.ashGrey,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _currentPasswordController,
                              label: 'Kata sandi saat ini',
                              hint: 'Wajib diisi jika ingin mengubah kata sandi',
                              icon: Icons.verified_user_outlined,
                              obscureText: _obscureCurrentPassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureCurrentPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.ashGrey,
                                  size: 18,
                                ),
                                tooltip: (_obscureCurrentPassword
                                        ? 'Tampilkan kata sandi'
                                        : 'Sembunyikan kata sandi')
                                    .tr(context),
                                onPressed: () => setState(() =>
                                    _obscureCurrentPassword =
                                        !_obscureCurrentPassword),
                              ),
                            ),
                            _buildField(
                              controller: _passwordController,
                              label: 'Kata sandi baru',
                              hint: 'Minimal 6 karakter, kosongkan jika tidak diubah',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: AppColors.ashGrey,
                                  size: 18,
                                ),
                                tooltip: (_obscurePassword
                                        ? 'Tampilkan kata sandi'
                                        : 'Sembunyikan kata sandi')
                                    .tr(context),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildSaveButton(),
                            const SizedBox(height: 22),
                            _buildSyncNote(),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildHero() {
    final imageUrl = _cleanImageUrl(_avatarUrl);
    final initial = _sellerName.isNotEmpty ? _sellerName[0].toUpperCase() : 'J';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isUploadingPhoto ? null : _changePhoto,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.charcoalVelvet,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: _isUploadingPhoto
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.champagneGold,
                              ),
                            ),
                          ),
                        )
                      : imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
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
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: AppColors.champagneGold,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.champagneGold,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: AppColors.champagneGold, width: 0.8),
                    ),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 12, color: AppColors.champagneGold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _sellerName.isNotEmpty ? _sellerName : 'Workshop JatiLuxe',
                style: const TextStyle(
                  color: AppColors.ivorySilk,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.champagneGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.champagneGold.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const TText(
                  'MITRA PENJUAL TERVERIFIKASI',
                  style: TextStyle(
                    color: AppColors.champagneGold,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 13, color: AppColors.ashGrey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _sellerAddress.isNotEmpty
                          ? _sellerAddress
                          : 'Lokasi galeri belum diatur',
                      style: const TextStyle(
                        color: AppColors.ashGrey,
                        fontSize: 12,
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
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: Row(
        children: [
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
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TText(
                      '$_productCount Desain',
                      style: const TextStyle(
                        color: AppColors.ivorySilk,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(width: 0.8, height: 42, color: AppColors.surfaceBorder),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TText(
                    'TOTAL STOK',
                    style: TextStyle(
                      color: AppColors.ashGreySubtle,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TText(
                    '$_stockUnits Unit',
                    style: const TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingCard() {
    return InkWell(
      onTap: widget.onOpenOnboarding,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.charcoalVelvet,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
        ),
        child: Row(
          children: const [
            Icon(Icons.school_outlined, color: AppColors.champagneGold, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TText(
                    'Panduan Orientasi Toko',
                    style: TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  TText(
                    'Ulangi tutorial 4 langkah untuk mengelola etalase',
                    style: TextStyle(color: AppColors.ashGrey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.ashGreySubtle, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return TText(
      title,
      style: const TextStyle(
        color: AppColors.champagneGold,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
        decoration: InputDecoration(
          labelText: label.tr(context),
          hintText: hint?.tr(context),
          labelStyle: const TextStyle(color: AppColors.ashGrey, fontSize: 13),
          hintStyle:
              const TextStyle(color: AppColors.ashGreySubtle, fontSize: 12),
          prefixIcon: Icon(icon, color: AppColors.warmBronze, size: 18),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.charcoalVelvet,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.champagneGold, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.0),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.champagneGold,
          foregroundColor: AppColors.obsidianBlack,
          elevation: 0,
          disabledBackgroundColor: AppColors.warmBronze,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSaving ? null : _saveProfile,
        child: _isSaving
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
                'SIMPAN PERUBAHAN',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _buildSyncNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.charcoalVelvet,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: AppColors.warmBronze, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: TText(
              'Perubahan identitas dan foto workshop akan langsung tersinkron dengan katalog dan pesanan Anda.',
              style: TextStyle(
                color: AppColors.ashGrey,
                fontSize: 11,
                height: 1.5,
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
            const Icon(Icons.wifi_off_rounded,
                size: 40, color: AppColors.ashGreySubtle),
            const SizedBox(height: 16),
            const TText(
              'Gagal memuat profil workshop',
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
              onPressed: _fetchProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.champagneGold,
                side:
                    const BorderSide(color: AppColors.champagneGold, width: 0.8),
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
