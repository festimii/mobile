import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  bool _otpEnabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOtpStatus();
  }

  Future<void> _loadOtpStatus() async {
    try {
      final status = await _api.fetchOtpStatus(widget.username);
      if (!mounted) return;
      setState(() {
        _otpEnabled = status;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading OTP status: $e')));
    }
  }

  Future<void> _toggleOtp(bool value) async {
    setState(() => _loading = true);
    try {
      if (value) {
        final secret = await _api.enableOtp(widget.username);
        if (!mounted) return;

        if (secret != null) {
          final uri = Uri.encodeFull(
            'otpauth://totp/RetailCRM:${widget.username}?secret=$secret&issuer=RetailCRM',
          );

          if (!mounted) return;

          await Future.delayed(Duration.zero); // Let layout complete
          await showDialog(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: const Text('OTP Enabled'),
                  content: SizedBox(
                    width: 300, // ✅ Constrain width
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Scan with an Authenticator app'),
                        const SizedBox(height: 12),
                        QrImageView(
                          data: uri,
                          size: 180.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Manual key:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SelectableText(
                          secret,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to enable OTP')));
        }
      } else {
        final ok = await _api.disableOtp(widget.username);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to disable OTP')),
          );
        }
      }

      await _loadOtpStatus();
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SwitchListTile(
                    title: const Text('Enable OTP'),
                    subtitle: const Text('Two-factor authentication'),
                    value: _otpEnabled,
                    onChanged: _toggleOtp,
                  ),
                ],
              ),
    );
  }
}
