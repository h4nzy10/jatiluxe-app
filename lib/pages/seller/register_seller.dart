import 'package:flutter/material.dart';
import '../register.dart';

/// Convenience page dedicated to Registering as a Seller
class RegisterSellerPage extends StatelessWidget {
  const RegisterSellerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegisterPage(initialIsSeller: true);
  }
}
