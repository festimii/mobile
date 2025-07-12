import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';

class MetricDetailScreen extends StatelessWidget {
  final SummaryMetric metric;

  const MetricDetailScreen({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _metricDetails[metric.title] ?? <String>[];

    return Scaffold(
      appBar: AppBar(title: Text(metric.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: metric.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(metric.icon, size: 32, color: metric.color),
                ),
                const SizedBox(width: 16),
                Text(
                  metric.value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...details.map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(d, style: theme.textTheme.bodyLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const Map<String, List<String>> _metricDetails = {
    'Total Revenue': [
      'Revenue YTD: €98,400',
      'Avg daily revenue: €1,200',
    ],
    'Transactions': [
      'Avg daily transactions: 125',
      'Peak hour: 12pm-1pm',
    ],
    'Avg. Basket Size': [
      'Yesterday: €15.03',
      'Last week avg: €14.54',
    ],
    'Top Product': [
      'Units sold today: 120',
      'Weekly sales: 640',
    ],
    'Returns Today': [
      'Returns this week: 47',
      'Most returned item: Soft Drink 500ml',
    ],
    'Low Inventory': [
      'Orders pending: 3',
      'Restock ETA: 2 days',
    ],
  };
}
