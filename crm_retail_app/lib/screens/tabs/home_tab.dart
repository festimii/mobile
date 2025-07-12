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

class SalesTrendChart extends StatelessWidget {
  final List<FlSpot> data;

  const SalesTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data,
              color: theme.primaryColor,
              isCurved: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: theme.primaryColor.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreSalesTable extends StatefulWidget {
  final List<StoreSales> salesData;

  const StoreSalesTable({super.key, required this.salesData});

  @override
  State<StoreSalesTable> createState() => _StoreSalesTableState();
}

class _StoreSalesTableState extends State<StoreSalesTable>
    with SingleTickerProviderStateMixin {
  String? selectedFilter = 'All';

  List<String> filters = ['All', 'Positive', 'Negative'];

  void _showDetails(BuildContext context, StoreSales sale) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Details - ${sale.store}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last year: €${sale.lastYear.toStringAsFixed(2)}'),
            Text('This year: €${sale.thisYear.toStringAsFixed(2)}'),
            Text('Change: ${sale.percentChange.toStringAsFixed(1)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
                    onSelectChanged: (_) => _showDetails(context, s),
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

class HomeTab extends StatelessWidget {
  HomeTab({super.key});

  final List<SummaryMetric> metrics = [
    SummaryMetric(
      title: 'Total Sales',
      value: '€12.5k',
      icon: Icons.show_chart,
      color: Colors.green,
    ),
    SummaryMetric(
      title: 'Customers',
      value: '430',
      icon: Icons.people,
      color: Colors.blue,
    ),
    SummaryMetric(
      title: 'Open Orders',
      value: '23',
      icon: Icons.shopping_cart,
      color: Colors.orange,
    ),
    SummaryMetric(
      title: 'Avg. Ticket',
      value: '€42.80',
      icon: Icons.receipt_long,
      color: Colors.purple,
    ),
  ];

  final List<StoreSales> sampleSales = [
    StoreSales(store: 'Downtown', lastYear: 18234, thisYear: 19540),
    StoreSales(store: 'Mall', lastYear: 15500, thisYear: 14920),
    StoreSales(store: 'Airport', lastYear: 9900, thisYear: 12200),
  ];

  final List<FlSpot> trendData = const [
    FlSpot(1, 5),
    FlSpot(2, 6.2),
    FlSpot(3, 7.1),
    FlSpot(4, 6.8),
    FlSpot(5, 7.5),
    FlSpot(6, 8.2),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, i) => SummaryCard(metric: metrics[i]),
        ),
        const SizedBox(height: 20),
        Text('Monthly Sales', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        SalesTrendChart(data: trendData),
        const SizedBox(height: 20),
        Text('Store Performance', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        StoreSalesTable(salesData: sampleSales),
      ],
    );
  }
}

