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
      'Revenue vs Last Week: % increase/decrease compared to last week',
      'Top Contributing Store: store with the highest revenue',
      'Revenue per Transaction: Total Revenue ÷ Number of Transactions',
      'Revenue from Promotions: % of revenue from discounts/promotions',
    ],
    'Transactions': [
      'Avg. Transactions per Hour: helps monitor peak times',
      'Peak Transaction Time: hour with the most transactions',
      'Online vs In-store Ratio: % split if applicable',
      'Repeat Customers %: transactions from loyalty customers',
    ],
    'Avg. Basket Size': [
      'Basket Size Trend: % change over the last 7 days',
      'Top Add-On Product: most frequent secondary product',
      '% Large Baskets (> €20): helps identify upsell success',
      'Basket Size by Category: average per product category',
    ],
    'Top Product': [
      'Units Sold Today: quantity sold of top product',
      'Revenue Contribution: portion of total revenue',
      'Attach Rate: % of transactions including the product',
      'Stock Remaining: inventory status of top product',
    ],
    'Returns Today': [
      'Return %: Returns ÷ Total Transactions × 100',
      'Top Returned Item: most commonly returned product',
      'Reason Breakdown: aggregated reasons e.g. damaged',
      'Refund vs Exchange Ratio: customer behaviour on return',
    ],
    'Low Inventory': [
      'Days Left (Forecasted): estimated days before stockout',
      'Avg Daily Sales (Last 7d): per low-inventory item',
      'Supplier Lead Time: average time to replenish stock',
      'Restock Status: pending/ordered/delayed',
    ],
  };
}
