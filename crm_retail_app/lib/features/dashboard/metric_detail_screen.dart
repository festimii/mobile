import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import '../../models/dashboard_models.dart';

class MetricDetailScreen extends StatelessWidget {
  final SummaryMetric metric;

  const MetricDetailScreen({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subKpis = _shortKpis[metric.title] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(metric.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children:
                    subKpis.map((kpi) {
                      return Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(kpi.icon, color: metric.color, size: 28),
                              const SizedBox(height: 10),
                              Text(
                                kpi.title,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                kpi.value,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubKpi {
  final String title;
  final String value;
  final IconData icon;

  SubKpi(this.title, this.value, this.icon);
}

Map<String, List<SubKpi>> _shortKpis = {
  'Total Revenue': [
    SubKpi('Vs Last Week', '+12%', Icons.trending_up),
    SubKpi('Top Store', 'VFS3', Icons.store),
    SubKpi('Rev / Tx', '€14.71', Icons.calculate),
    SubKpi('Promos', '18%', Icons.local_offer),
  ],
  'Transactions': [
    SubKpi('Per Hour', '102', Icons.access_time),
    SubKpi('Peak Time', '15:00', Icons.schedule),
    SubKpi('Online %', '28%', Icons.wifi),
    SubKpi('Repeat', '36%', Icons.repeat),
  ],
  'Avg. Basket Size': [
    SubKpi('Trend', '+5.2%', Icons.trending_up),
    SubKpi('Add-On', 'Bread', Icons.add),
    SubKpi('> €20', '23%', Icons.shopping_cart),
    SubKpi('By Cat.', '€18.10', Icons.category),
  ],
  'Top Product': [
    SubKpi('Sold Today', '221', Icons.check_circle),
    SubKpi('Revenue %', '8.4%', Icons.pie_chart),
    SubKpi('Attach Rate', '41%', Icons.link),
    SubKpi('Stock Left', '52', Icons.inventory),
  ],
  'Returns Today': [
    SubKpi('Return %', '1.4%', Icons.percent),
    SubKpi('Top Item', 'Milk 1L', Icons.assignment_return),
    SubKpi('Damage', '46%', Icons.report_problem),
    SubKpi('Exchanges', '29%', Icons.swap_horiz),
  ],
  'Low Inventory': [
    SubKpi('Days Left', '3.1d', Icons.calendar_today),
    SubKpi('Daily Sales', '18', Icons.bar_chart),
    SubKpi('Lead Time', '5d', Icons.access_time_filled),
    SubKpi('Restock', 'Pending', Icons.timelapse),
  ],
};
