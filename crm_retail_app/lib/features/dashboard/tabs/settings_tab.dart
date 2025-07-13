import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_notifier.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Settings", style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {}, // Navigate to profile settings
          ),
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, _) {
              return SwitchListTile(
                secondary: const Icon(Icons.palette),
                title: const Text('Dark Mode'),
                value: themeNotifier.isDarkMode,
                onChanged: (_) => themeNotifier.toggle(),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              // Confirm and return to login
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
