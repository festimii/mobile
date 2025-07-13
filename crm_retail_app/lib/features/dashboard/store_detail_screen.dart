import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';

class StoreDetailScreen extends StatelessWidget {
  final StoreSales sales;

  const StoreDetailScreen({super.key, required this.sales});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<StoreKpi> salesKpis = [
      StoreKpi(
        'Last Year',
        '€${sales.lastYear.toStringAsFixed(2)}',
        Icons.calendar_today,
      ),
      StoreKpi(
        'This Year',
        '€${sales.thisYear.toStringAsFixed(2)}',
        Icons.today,
      ),
      StoreKpi(
        'Change',
        '${sales.percentChange.toStringAsFixed(1)}%',
        sales.percentChange > 0
            ? Icons.arrow_upward
            : sales.percentChange < 0
            ? Icons.arrow_downward
            : Icons.remove,
      ),
      StoreKpi('Revenue/Tx', '€14.20', Icons.calculate),
    ];

    final List<StoreKpi> customerKpis = [
      StoreKpi('Customers Today', '120', Icons.people),
      StoreKpi('Repeat Rate', '36%', Icons.replay),
      StoreKpi('Conversion Rate', '61%', Icons.show_chart),
      StoreKpi('Avg Time Spent', '8m 20s', Icons.timer),
    ];

    final List<StoreKpi> inventoryKpis = [
      StoreKpi('Low Stock Items', '4', Icons.inventory_2),
      StoreKpi('Top Product', 'Milk 1L', Icons.star),
      StoreKpi('Restock Time', '3d avg', Icons.timelapse),
      StoreKpi('Stock Value', '€2,300', Icons.monetization_on),
    ];

    final List<StoreKpi> opsKpis = [
      StoreKpi('Transactions', '85', Icons.receipt_long),
      StoreKpi('Avg Basket', '€14.20', Icons.shopping_basket),
      StoreKpi('Peak Hour', '13:00', Icons.access_time),
      StoreKpi('Refunds Today', '6', Icons.undo),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(sales.store)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildSection(context, '📊 Sales KPIs', salesKpis),
            _buildSection(context, '🛍️ Customer Behavior', customerKpis),
            _buildSection(context, '📦 Inventory KPIs', inventoryKpis),
            _buildSection(context, '🧮 Operational Metrics', opsKpis),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<StoreKpi> kpis,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children:
              kpis.map((kpi) {
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
        const SizedBox(height: 28),
      ],
    );
  }
}

class StoreKpi {
  final String title;
  final String value;
  final IconData icon;

  StoreKpi(this.title, this.value, this.icon);
}
