import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  bool _otpEnabled = false;
  bool _loading = true;
  final String _username = 'demo'; // placeholder for demo

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _api.fetchOtpStatus(_username);
    setState(() {
      _otpEnabled = status;
      _loading = false;
    });
  }

  Future<void> _toggleOtp(bool value) async {
    setState(() => _loading = true);
    if (value) {
      final secret = await _api.enableOtp(_username);
      if (!mounted) return;
      if (secret != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP enabled. Secret: $secret')),
        );
      }
    } else {
      await _api.disableOtp(_username);
    }
    await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Enable OTP'),
                  value: _otpEnabled,
                  onChanged: _toggleOtp,
                ),
              ],
            ),
    );
  }
}
