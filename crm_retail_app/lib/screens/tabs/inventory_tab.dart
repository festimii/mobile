import 'package:flutter/material.dart';

class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = [
      {'name': 'Coca Cola 500ml', 'stock': 23},
      {'name': 'Bread 400g', 'stock': 6},
      {'name': 'Tomato Sauce', 'stock': 0},
    ];

    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final item = items[i];
          final isLow = (item['stock']! as int) <= 5;
          return ListTile(
            leading: const Icon(Icons.inventory),
            title: Text(item['name']! as String),
            subtitle: Text("In stock: ${item['stock']}"),
            trailing:
                isLow
                    ? const Icon(Icons.warning, color: Colors.redAccent)
                    : null,
          );
        },
      ),
    );
  }
}
