import 'dart:async';
import 'dart:convert';
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
  bool _rememberDevice = false;

  final ApiService _api = ApiService();
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

    final userProvider = context.read<UserProvider>();
    final deviceToken = userProvider.deviceToken;

    final loginPayload = {
      'username': username,
      'password': '*' * password.length,
      'otp': otp,
      'deviceToken': deviceToken.isNotEmpty ? deviceToken : null,
      'rememberDevice': otp != null && _rememberDevice,
    };

    debugPrint('🔐 Login Request:\n${jsonEncode(loginPayload)}');

    final res = await _api.login(
      username,
      password,
      otp,
      deviceToken: deviceToken.isNotEmpty ? deviceToken : null,
      rememberDevice: otp != null && _rememberDevice,
    );

    if (res == null) {
      _showSnack('Network error');
      return;
    }

    debugPrint('🔄 Login Response [${res.statusCode}]: ${res.body}');

    if (res.statusCode == 200) {
      final data =
          res.body.isNotEmpty
              ? jsonDecode(res.body) as Map<String, dynamic>
              : <String, dynamic>{};

      await userProvider.setUsername(username);

      final newToken = data['deviceToken'] as String?;
      if (newToken != null && newToken.isNotEmpty) {
        debugPrint('✅ New deviceToken received: $newToken');
        await userProvider.setDeviceToken(newToken);
      } else {
        debugPrint('ℹ️ No new deviceToken returned.');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (res.statusCode == 403) {
      if (res.body.contains('OTP required')) {
        debugPrint('🔐 OTP required response received.');
        setState(() => _needsOtp = true);
        _showSnack('Enter one-time code');
      } else if (res.body.contains('Invalid OTP')) {
        debugPrint('❌ Invalid OTP response received.');
        _showSnack('Invalid code');
      } else {
        debugPrint('❌ 403 but unknown body: ${res.body}');
        _showSnack('Invalid credentials');
      }
    } else {
      debugPrint('❌ Login failed with status: ${res.statusCode}');
      _showSnack('Invalid credentials');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter username or email'
                              : null,
                ),
                const SizedBox(height: 16),

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
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter password'
                              : null,
                ),
                const SizedBox(height: 24),

                if (_needsOtp) ...[
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'One-time code',
                      prefixIcon: Icon(Icons.shield),
                    ),
                    validator:
                        (value) =>
                            _needsOtp && (value == null || value.isEmpty)
                                ? 'Enter code'
                                : null,
                  ),
                  const SizedBox(height: 8),
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
                  CheckboxListTile(
                    title: const Text('Trust this device'),
                    value: _rememberDevice,
                    onChanged:
                        (v) => setState(() => _rememberDevice = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 24),
                ],

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
