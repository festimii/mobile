import 'package:flutter/material.dart';
import '../../models/dashboard_models.dart';

class StoreDetailScreen extends StatelessWidget {
  final StoreKpiMetrics metrics;

  const StoreDetailScreen({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<StoreKpi> salesKpis = [
      StoreKpi('Revenue Today', '€${metrics.revenueToday.toStringAsFixed(2)}',
          Icons.today),
      StoreKpi('Revenue PY', '€${metrics.revenuePy.toStringAsFixed(2)}',
          Icons.calendar_today),
      StoreKpi(
        'Revenue %',
        '${metrics.revenuePct.toStringAsFixed(1)}%',
        metrics.revenuePct >= 0
            ? Icons.arrow_upward
            : metrics.revenuePct < 0
                ? Icons.arrow_downward
                : Icons.remove,
      ),
      StoreKpi('Avg Basket',
          '€${metrics.avgBasketToday.toStringAsFixed(2)}', Icons.shopping_basket),
    ];

    final List<StoreKpi> customerKpis = [
      StoreKpi('Tx Today', metrics.txToday.toString(), Icons.receipt_long),
      StoreKpi('Tx PY', metrics.txPy.toString(), Icons.history),
      StoreKpi(
        'Tx %',
        '${metrics.txPct.toStringAsFixed(1)}%',
        metrics.txPct >= 0
            ? Icons.arrow_upward
            : metrics.txPct < 0
                ? Icons.arrow_downward
                : Icons.remove,
      ),
      StoreKpi('Avg Basket PY',
          '€${metrics.avgBasketPy.toStringAsFixed(2)}', Icons.shopping_basket_outlined),
    ];

    final List<StoreKpi> inventoryKpis = [
      StoreKpi(
        'Avg Basket Diff',
        '€${metrics.avgBasketDiff.toStringAsFixed(2)}',
        metrics.avgBasketDiff >= 0
            ? Icons.trending_up
            : Icons.trending_down,
      ),
      StoreKpi('Top Product Code', metrics.topArtCode, Icons.qr_code),
      StoreKpi('Top Product Rev',
          '€${metrics.topArtRevenue.toStringAsFixed(2)}', Icons.monetization_on),
      StoreKpi('Top Product', metrics.topArtName, Icons.star),
    ];

    final List<StoreKpi> opsKpis = [
      StoreKpi('Revenue Diff',
          '€${metrics.revenueDiff.toStringAsFixed(2)}',
          metrics.revenueDiff >= 0
              ? Icons.arrow_upward
              : metrics.revenueDiff < 0
                  ? Icons.arrow_downward
                  : Icons.remove),
      StoreKpi('Tx Diff', metrics.txDiff.toString(),
          metrics.txDiff >= 0 ? Icons.arrow_upward : Icons.arrow_downward),
      StoreKpi('Peak Hour', metrics.peakHourLabel, Icons.access_time),
      StoreKpi('Peak Hour Rev',
          '€${metrics.peakHourRevenue.toStringAsFixed(2)}', Icons.bar_chart),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(metrics.storeName)),
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
