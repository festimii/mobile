import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';

class StoreDetailScreen extends StatelessWidget {
  final StoreSales sales;

  const StoreDetailScreen({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kpis = _storeKpis[sales.store] ?? _storeKpis['default']!;

    return Scaffold(
      appBar: AppBar(title: Text(sales.store)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Last year: €${sales.lastYear.toStringAsFixed(2)}'),
            Text('This year: €${sales.thisYear.toStringAsFixed(2)}'),
            Text('Change: ${sales.percentChange.toStringAsFixed(1)}%'),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: kpis.map((kpi) {
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
                          Icon(kpi.icon, color: theme.primaryColor, size: 28),
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

class StoreKpi {
  final String title;
  final String value;
  final IconData icon;

  StoreKpi(this.title, this.value, this.icon);
}

Map<String, List<StoreKpi>> _storeKpis = {
  'default': [
    StoreKpi('Customers Today', '120', Icons.people),
    StoreKpi('Transactions', '85', Icons.receipt_long),
    StoreKpi('Avg Basket', '€14.20', Icons.shopping_basket),
    StoreKpi('Conversion', '61%', Icons.show_chart),
  ],
};
