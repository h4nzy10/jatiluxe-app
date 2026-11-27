import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../constants/theme.dart';
import '../../service/api.dart';
import '../../service/l10n.dart';
import '../login.dart';
import '../seller/register_seller.dart';

/// Customer account page: identity, password, profile photo, logout and the
/// one-way elevation path to a seller account.
class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  String? _errorMessage;

  String _customerName = '';
  String _customerAddress = '';
  String? _avatarUrl;

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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.get('/api/v1/profile');
      if (!mounted) return;

      final rawUser = response is Map ? response['user'] : null;
      if (rawUser == null) {
        throw Exception('Data profil tidak ditemukan.');
      }
      final user = Map<String, dynamic>.from(rawUser as Map);

      final name = (user['nama'] ?? '').toString();
      final email = (user['email'] ?? '').toString();
      final phone = (user['no_hp'] ?? '').toString();
      final address = (user['alamat'] ?? '').toString();

      setState(() {
        _customerName = name;
        _customerAddress = address;
        _avatarUrl = user['profile']?.toString();
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

    final newPassword = _newPasswordController.text;
    final currentPassword = _currentPasswordController.text.trim();

    if (newPassword.isNotEmpty) {
      if (currentPassword.isEmpty) {
        _showSnack('Kata sandi saat ini wajib diisi', isError: true);
        return;
      }
      if (newPassword.length < 6) {
        _showSnack('Kata sandi baru minimal 6 karakter', isError: true);
        return;
      }
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();

    final hasChanges =
        name != _savedName ||
        email != _savedEmail ||
        phone != _savedPhone ||
        address != _savedAddress ||
        newPassword.isNotEmpty;

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
    if (newPassword.isNotEmpty) {
      payload['current_password'] = currentPassword;
      payload['password'] = newPassword;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService.put('/api/v1/profile', payload);
      if (!mounted) return;
      setState(() {
        _customerName = name;
        _customerAddress = address;
        _savedName = name;
        _savedEmail = email;
        _savedPhone = phone;
        _savedAddress = address;
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });
      _showSnack('Profil berhasil disimpan', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Gagal menyimpan: ${e.toString().replaceFirst('Exception: ', '')}',
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
                'FOTO PROFIL',
                style: TextStyle(
                  color: AppColors.ashGreySubtle,
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
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

    if (!kIsWeb && source == ImageSource.camera) {
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
        _showSnack(
          'Izin kamera diperlukan untuk mengambil foto',
          isError: true,
        );
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
      final bytes = await picked.readAsBytes();
      final response = await ApiService.postMultipart(
        '/api/v1/profile-picture',
        fileField: 'profile',
        filePath: picked.path,
        fileBytes: bytes,
        filename: picked.name,
      );
      if (!mounted) return;

      final url = response is Map
          ? (response['profile_picture'] ?? response['profile'])?.toString()
          : null;
      if (url != null && url.isNotEmpty) {
        setState(() => _avatarUrl = url);
      }
      _showSnack('Foto profil berhasil diperbarui', isError: false);
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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        title: const TText(
          'Konfirmasi Keluar',
          style: TextStyle(
            color: AppColors.ivorySilk,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const TText(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(color: AppColors.ashGrey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const TText(
              'Batal',
              style: TextStyle(color: AppColors.ashGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.ivorySilk,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const TText('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openSellerRegistration() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterSellerPage()),
    );
    if (!mounted) return;
    await _fetchProfile();
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
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        title: const TText('PROFIL SAYA'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.ashGrey,
              size: 20,
            ),
            tooltip: 'Keluar'.tr(context),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: L10nBuilder(
        builder: (context) => SafeArea(
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
                          const SizedBox(height: 28),
                          _buildSectionTitle('IDENTITAS PELANGGAN'),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _nameController,
                            label: 'Nama lengkap',
                            icon: Icons.person_outline,
                            validator: (v) => _requiredField(v, 'Nama lengkap'),
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
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
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
                            label: 'Alamat',
                            icon: Icons.location_on_outlined,
                            keyboardType: TextInputType.multiline,
                            maxLines: 2,
                            validator: (v) => _requiredField(v, 'Alamat'),
                          ),
                          const SizedBox(height: 8),
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
                              tooltip:
                                  (_obscureCurrentPassword
                                          ? 'Tampilkan kata sandi'
                                          : 'Sembunyikan kata sandi')
                                      .tr(context),
                              onPressed: () => setState(
                                () => _obscureCurrentPassword =
                                    !_obscureCurrentPassword,
                              ),
                            ),
                          ),
                          _buildField(
                            controller: _newPasswordController,
                            label: 'Kata sandi baru',
                            hint: 'Minimal 6 karakter, kosongkan jika tidak diubah',
                            icon: Icons.lock_outline,
                            obscureText: _obscureNewPassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.ashGrey,
                                size: 18,
                              ),
                              tooltip:
                                  (_obscureNewPassword
                                          ? 'Tampilkan kata sandi'
                                          : 'Sembunyikan kata sandi')
                                      .tr(context),
                              onPressed: () => setState(
                                () =>
                                    _obscureNewPassword = !_obscureNewPassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildSaveButton(),
                          const SizedBox(height: 22),
                          _buildSellerCard(),
                          const SizedBox(height: 14),
                          _buildSyncNote(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final imageUrl = _cleanImageUrl(_avatarUrl);
    final initial = _customerName.isNotEmpty
        ? _customerName[0].toUpperCase()
        : 'J';

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
                  child: const Icon(
                    Icons.camera_alt,
                    size: 12,
                    color: AppColors.champagneGold,
                  ),
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
                _customerName.isNotEmpty ? _customerName : 'Pelanggan JatiLuxe',
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.champagneGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.champagneGold.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const TText(
                  'PELANGGAN JATILUXE',
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
                  const Icon(
                    Icons.place_outlined,
                    size: 13,
                    color: AppColors.ashGrey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _customerAddress.isNotEmpty
                          ? _customerAddress
                          : 'Lokasi belum diatur',
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
          hintStyle: const TextStyle(
            color: AppColors.ashGreySubtle,
            fontSize: 12,
          ),
          prefixIcon: Icon(icon, color: AppColors.warmBronze, size: 18),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.charcoalVelvet,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.surfaceBorder,
              width: 0.8,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.surfaceBorder,
              width: 0.8,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.champagneGold,
              width: 1.2,
            ),
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

  Widget _buildSellerCard() {
    return InkWell(
      onTap: _openSellerRegistration,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.charcoalVelvet,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: AppColors.champagneGold,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  TText(
                    'ELEVASI AKUN',
                    style: TextStyle(
                      color: AppColors.champagneGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  TText(
                    'Daftar sebagai Penjual',
                    style: TextStyle(
                      color: AppColors.ivorySilk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  TText(
                    'Buka etalase digital dan pasarkan furnitur kayu berkualitas langsung ke kolektor.',
                    style: TextStyle(color: AppColors.ashGrey, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.ashGreySubtle,
              size: 18,
            ),
          ],
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
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warmBronze, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: TText(
              'Perubahan profil Anda akan tersinkron dengan pesanan.',
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
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.ashGreySubtle,
            ),
            const SizedBox(height: 16),
            const TText(
              'Gagal memuat profil',
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
