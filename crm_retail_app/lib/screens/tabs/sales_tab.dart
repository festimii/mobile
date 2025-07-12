import 'package:flutter/material.dart';

class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Recent Sales", style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text("Order #1245"),
            subtitle: const Text("€48.00 • Cash • John D."),
            trailing: const Text("10:32"),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text("Order #1244"),
            subtitle: const Text("€86.00 • Card • Lisa K."),
            trailing: const Text("09:15"),
          ),
          // Add more dummy orders or dynamic source
        ],
      ),
    );
  }
}
