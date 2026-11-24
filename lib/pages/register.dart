import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../service/api.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  final bool initialIsSeller;

  const RegisterPage({
    super.key,
    this.initialIsSeller = false,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  late bool _isSeller;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isSeller = widget.initialIsSeller;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final endpoint = _isSeller ? '/api/v1/register/seller' : '/api/v1/register';

    final payload = {
      'nama': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'no_hp': _phoneController.text.trim(),
      'alamat': _addressController.text.trim(),
    };

    try {
      final response = await ApiService.post(endpoint, payload);

      if (!mounted) return;

      final message = response != null && response['message'] != null
          ? response['message'].toString()
          : 'Register successfuly! Please login.';

      _showSuccessDialog(message);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      _showErrorSnackBar(errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 0.8),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.champagneGold,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              'Register Successfuly',
              style: TextStyle(
                color: AppColors.ivorySilk,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.ashGrey,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.champagneGold,
              foregroundColor: AppColors.obsidianBlack,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Login Now'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.error.withOpacity(0.6), width: 0.8),
        ),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.ivorySilk,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: AppBar(
        title: const Text('J A T I L U X E'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title
                Text(
                  _isSeller ? 'Register As Seller' : 'Register As Customer',
                  style: const TextStyle(
                    color: AppColors.ivorySilk,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSeller
                      ? 'Open a digital showcase and market quality teak furniture works directly to collectors.'
                      : 'Join to explore and order premium Jepara teak furniture.',
                  style: const TextStyle(
                    color: AppColors.ashGrey,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),

                // Luxury Role Selector Tabs
                Container(
                  padding: const EdgeInsets.all(4),
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
                      // Customer Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_isSeller) setState(() => _isSeller = false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isSeller
                                  ? AppColors.champagneGold
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                  color: !_isSeller
                                      ? AppColors.obsidianBlack
                                      : AppColors.ashGrey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Customer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: !_isSeller
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: !_isSeller
                                        ? AppColors.obsidianBlack
                                        : AppColors.ashGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Seller Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!_isSeller) setState(() => _isSeller = true);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isSeller
                                  ? AppColors.champagneGold
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 16,
                                  color: _isSeller
                                      ? AppColors.obsidianBlack
                                      : AppColors.ashGrey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Seller',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _isSeller
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _isSeller
                                        ? AppColors.obsidianBlack
                                        : AppColors.ashGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Name Field
                _buildFieldLabel(_isSeller ? 'Store Name' : 'Your Name'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                  cursorColor: AppColors.champagneGold,
                  decoration: InputDecoration(
                    hintText: _isSeller ? 'Example: Galeri Jati Makmur' : 'Full name',
                    prefixIcon: Icon(
                      _isSeller ? Icons.storefront_outlined : Icons.person_outline_rounded,
                      color: AppColors.ashGreySubtle,
                      size: 18,
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),

                const SizedBox(height: 18),

                // Email Field
                _buildFieldLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                  cursorColor: AppColors.champagneGold,
                  decoration: const InputDecoration(
                    hintText: 'example@email.com',
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: AppColors.ashGreySubtle,
                      size: 18,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(val.trim())) return 'Invalid email format';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Phone Number Field
                _buildFieldLabel('Phone Number'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                  cursorColor: AppColors.champagneGold,
                  decoration: const InputDecoration(
                    hintText: '62812xxxxxxxx',
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.ashGreySubtle,
                      size: 18,
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required' : null,
                ),

                const SizedBox(height: 18),

                // Address Field
                _buildFieldLabel(_isSeller ? 'Workshop / Gallery Address' : 'Shipping Address'),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                  cursorColor: AppColors.champagneGold,
                  decoration: InputDecoration(
                    hintText: _isSeller
                        ? 'Jl. Pengrajin No. XX, Jepara'
                        : 'Shipping Address',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: AppColors.ashGreySubtle,
                        size: 18,
                      ),
                    ),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
                ),

                const SizedBox(height: 18),

                // Password Field
                _buildFieldLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                  cursorColor: AppColors.champagneGold,
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 characters',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.ashGreySubtle,
                      size: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.ashGreySubtle,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                // Confirm Password Field
                _buildFieldLabel('Confirm Password'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  style: const TextStyle(color: AppColors.ivorySilk, fontSize: 14),
                  cursorColor: AppColors.champagneGold,
                  decoration: InputDecoration(
                    hintText: 'Repeat your password',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.ashGreySubtle,
                      size: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.ashGreySubtle,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Confirm password is required';
                    if (val != _passwordController.text) return 'Password does not match';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.champagneGold,
                      foregroundColor: AppColors.obsidianBlack,
                      disabledBackgroundColor: AppColors.champagneGold.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
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
                        : Text(
                            _isSeller ? 'Register As Seller' : 'Register Account',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.ashGrey,
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Login Now',
                        style: TextStyle(
                          color: AppColors.champagneGoldLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
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
        style: const TextStyle(
          color: AppColors.ivorySilk,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
