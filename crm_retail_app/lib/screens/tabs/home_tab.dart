import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  SummaryMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class SummaryCard extends StatelessWidget {
  final SummaryMetric metric;

  const SummaryCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: metric.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(metric.icon, size: 28, color: metric.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    metric.value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreSales {
  final String store;
  final double lastYear;
  final double thisYear;

  StoreSales({
    required this.store,
    required this.lastYear,
    required this.thisYear,
  });

  double get percentChange => ((thisYear - lastYear) / lastYear) * 100;
}

class StoreSalesTable extends StatefulWidget {
  final List<StoreSales> salesData;
  final void Function(StoreSales)? onRowTap;

  const StoreSalesTable({
    super.key,
    required this.salesData,
    this.onRowTap,
  });

  @override
  State<StoreSalesTable> createState() => _StoreSalesTableState();
}

class _StoreSalesTableState extends State<StoreSalesTable>
    with SingleTickerProviderStateMixin {
  String? selectedFilter = 'All';

  List<String> filters = ['All', 'Positive', 'Negative'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    List<StoreSales> filtered = widget.salesData;
    if (selectedFilter == 'Positive') {
      filtered = filtered.where((e) => e.percentChange >= 0).toList();
    } else if (selectedFilter == 'Negative') {
      filtered = filtered.where((e) => e.percentChange < 0).toList();
    }
    filtered.sort((a, b) => a.percentChange.compareTo(b.percentChange));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: selectedFilter,
          onChanged: (value) => setState(() => selectedFilter = value),
          items:
              filters
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            columns: const [
              DataColumn(label: Text('Store')),
              DataColumn(label: Text('Last Year')),
              DataColumn(label: Text('This Year')),
              DataColumn(label: Text('Change (%)')),
            ],
            rows:
                filtered.map((s) {
                  final isNegative = s.percentChange < 0;
                  return DataRow(
                    color: MaterialStateProperty.resolveWith<Color?>(
                      (_) => isNegative ? Colors.red.withOpacity(0.05) : null,
                    ),
                    onSelectChanged: widget.onRowTap == null
                        ? null
                        : (_) => widget.onRowTap!(s),
                    cells: [
                      DataCell(
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 800),
                          child: Text(s.store),
                        ),
                      ),
                      DataCell(Text('€${s.lastYear.toStringAsFixed(2)}')),
                      DataCell(Text('€${s.thisYear.toStringAsFixed(2)}')),
                      DataCell(Text('${s.percentChange.toStringAsFixed(1)}%')),
                    ],
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class Activity {
  final String title;
  final String time;

  Activity({required this.title, required this.time});
}

class ActivityList extends StatelessWidget {
  final List<Activity> activities;

  const ActivityList({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: activities
          .map(
            (a) => ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(a.title),
              trailing: Text(a.time, style: theme.textTheme.bodySmall),
            ),
          )
          .toList(),
    );
  }
}

class HomeTab extends StatelessWidget {
  HomeTab({super.key});

  final List<SummaryMetric> _metrics = [
    SummaryMetric(
        title: 'Total Sales',
        value: '€120k',
        icon: Icons.trending_up,
        color: Colors.greenAccent),
    SummaryMetric(
        title: 'Active Customers',
        value: '1,240',
        icon: Icons.people,
        color: Colors.blueAccent),
    SummaryMetric(
        title: 'New Leads',
        value: '150',
        icon: Icons.person_add,
        color: Colors.orangeAccent),
  ];

  final List<StoreSales> _sales = [
    StoreSales(store: 'Berlin', lastYear: 62000, thisYear: 68000),
    StoreSales(store: 'Munich', lastYear: 54000, thisYear: 51000),
    StoreSales(store: 'Paris', lastYear: 72000, thisYear: 75000),
    StoreSales(store: 'Prague', lastYear: 39000, thisYear: 42000),
  ];

  final List<Activity> _activities = [
    Activity(title: 'Call with James', time: '09:00'),
    Activity(title: 'New order from Berlin', time: '10:30'),
    Activity(title: 'Email Kate about invoice', time: '13:15'),
  ];

  List<FlSpot> get _trendPoints => [
        const FlSpot(0, 50),
        const FlSpot(1, 80),
        const FlSpot(2, 70),
        const FlSpot(3, 90),
        const FlSpot(4, 110),
      ];

  void _showSaleDetails(BuildContext context, StoreSales sale) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sale.store, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Last year: €${sale.lastYear.toStringAsFixed(2)}'),
            Text('This year: €${sale.thisYear.toStringAsFixed(2)}'),
            Text('Change: ${sale.percentChange.toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metrics
            Row(
              children: _metrics
                  .map((m) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SummaryCard(metric: m),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      color: theme.primaryColor,
                      spots: _trendPoints,
                      isCurved: true,
                      dotData: const FlDotData(show: false),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sales by Store', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            StoreSalesTable(
              salesData: _sales,
              onRowTap: (sale) => _showSaleDetails(context, sale),
            ),
            const SizedBox(height: 20),
            Text('Today', style: theme.textTheme.titleMedium),
            ActivityList(activities: _activities),
          ],
        ),
      ),
    );
  }
}
