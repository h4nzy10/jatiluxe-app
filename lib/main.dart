import 'package:flutter/material.dart';
import 'constants/theme.dart';
import 'pages/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JatiLuxe());
}

class JatiLuxe extends StatelessWidget {
  const JatiLuxe({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JatiLuxe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashPage(),
    );
  }
}
