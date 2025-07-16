import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_notifier.dart';
import '../../profile/profile_screen.dart';
import '../../../providers/user_provider.dart'; // ✅ Add this import

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = context.watch<UserProvider>().username; // ✅ Get username

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Settings", style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(username: username),
                ),
              );
            },
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
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to log out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                // Preserve device token so trusted status isn't lost
                await context.read<UserProvider>().logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
