import 'package:flutter/material.dart';
import 'home_tab.dart';
import '../../../models/dashboard_models.dart';

class InventoryTab extends StatelessWidget {
  const InventoryTab({super.key});

  Widget _buildKpiSection(
    BuildContext context,
    String title,
    List<SummaryMetric> metrics,
  ) {
    final double cardWidth =
        MediaQuery.of(context).size.width > 600
            ? 260
            : MediaQuery.of(context).size.width / 2 - 22;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              metrics
                  .map(
                    (m) => SizedBox(
                      width: cardWidth,
                      child: SummaryCard(metric: m),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final wmsMetrics = [
      SummaryMetric(
        title: 'Items Received',
        value: '1,230',
        icon: Icons.move_to_inbox,
        color: Colors.green,
      ),
      SummaryMetric(
        title: 'Items Shipped',
        value: '980',
        icon: Icons.local_shipping,
        color: Colors.blue,
      ),
      SummaryMetric(
        title: 'Pending',
        value: '150',
        icon: Icons.pending_actions,
        color: Colors.orange,
      ),
      SummaryMetric(
        title: 'Damaged',
        value: '12',
        icon: Icons.report_problem,
        color: Colors.redAccent,
      ),
    ];

    final stockMetrics = [
      SummaryMetric(
        title: 'Low Stock',
        value: '5',
        icon: Icons.warning,
        color: Colors.redAccent,
      ),
      SummaryMetric(
        title: 'Out of Stock',
        value: '2',
        icon: Icons.block,
        color: Colors.deepOrange,
      ),
      SummaryMetric(
        title: 'Stock Value',
        value: '€12,300',
        icon: Icons.euro,
        color: Colors.indigo,
      ),
      SummaryMetric(
        title: 'Stock Turnover',
        value: '45 days',
        icon: Icons.refresh,
        color: Colors.teal,
      ),
    ];

    final items = [
      {'name': 'Coca Cola 500ml', 'stock': 23},
      {'name': 'Bread 400g', 'stock': 6},
      {'name': 'Tomato Sauce', 'stock': 0},
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKpiSection(
              context,
              'Akoma e pa perfunduar te dhena Fake',
              wmsMetrics,
            ),
            _buildKpiSection(context, 'Stock KPIs', stockMetrics),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = items[i];
                final isLow = (item['stock']! as int) <= 5;
                return ListTile(
                  leading: const Icon(Icons.inventory),
                  title: Text(item['name']! as String),
                  subtitle: Text('In stock: ${item['stock']}'),
                  trailing:
                      isLow
                          ? const Icon(Icons.warning, color: Colors.redAccent)
                          : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
