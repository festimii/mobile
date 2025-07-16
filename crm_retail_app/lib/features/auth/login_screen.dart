import 'dart:async';
import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _needsOtp = false;
  final ApiService _api = ApiService();

  // 🔁 TOTP countdown state
  Timer? _otpTimer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _startOtpCountdown();
  }

  void _startOtpCountdown() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = 30 - (DateTime.now().second % 30);
      setState(() => _secondsLeft = remaining);
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final otp = _needsOtp ? _otpCtrl.text.trim() : null;

    final res = await _api.login(username, password, otp);

    if (res == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Network error')));
      return;
    }

    if (res.statusCode == 200) {
      await context.read<UserProvider>().setUsername(
        username,
      ); // ✅ Save to SharedPreferences
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (res.statusCode == 403 && res.body.contains('OTP required')) {
      setState(() => _needsOtp = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter one-time code')));
    } else if (res.statusCode == 403 && res.body.contains('Invalid OTP')) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid code')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid credentials')));
    }
  }

  @override
  void dispose() {
    _otpTimer?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(Icons.store, size: 80, color: theme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Retail CRM Login',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Email field
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter username or email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                if (_needsOtp) ...[
                  // OTP field
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'One-time code',
                      prefixIcon: Icon(Icons.shield),
                    ),
                    validator: (value) {
                      if (_needsOtp && (value == null || value.isEmpty)) {
                        return 'Enter code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Animated countdown
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 30, end: _secondsLeft),
                    duration: const Duration(milliseconds: 300),
                    builder: (_, value, __) {
                      final color =
                          value > 20
                              ? Colors.green
                              : value > 10
                              ? Colors.orange
                              : Colors.red;

                      return Text(
                        'Code refreshes in $value s',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
