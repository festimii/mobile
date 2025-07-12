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

  const StoreSalesTable({super.key, required this.salesData});

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
