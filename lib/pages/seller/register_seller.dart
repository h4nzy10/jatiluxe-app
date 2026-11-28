import 'package:flutter/material.dart';
import '../register.dart';

/// Elevation path opened from the customer profile.
///
/// Reuses the registration screen's role tabs: the Seller tab upgrades the
/// current account with its own email and password, while the Customer tab
/// still offers a fresh customer registration.
class RegisterSellerPage extends StatelessWidget {
  final String email;

  const RegisterSellerPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return RegisterPage(
      initialIsSeller: true,
      elevateMode: true,
      currentEmail: email,
    );
  }
}
