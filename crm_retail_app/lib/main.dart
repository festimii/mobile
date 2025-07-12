import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/misty_dark_theme.dart'; // Save theme above to this file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retail CRM',
      theme: mistyDarkTheme,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
