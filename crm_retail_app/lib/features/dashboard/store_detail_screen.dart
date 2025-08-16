import 'package:flutter/material.dart';
import '../../models/dashboard_models.dart';
import '../../services/api_service.dart';

class StoreDetailScreen extends StatefulWidget {
  final StoreSales sales;

  const StoreDetailScreen({super.key, required this.sales});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  late Future<StoreKpiDetail?> _kpiFuture;

  @override
  void initState() {
    super.initState();
    final id = int.tryParse(
            RegExp(r'\d+').firstMatch(widget.sales.store)?.group(0) ?? '0') ??
        0;
    _kpiFuture = ApiService().fetchStoreKpi(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sales.store)),
      body: FutureBuilder<StoreKpiDetail?>(
        future: _kpiFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data == null) {
            return const Center(child: Text('No data'));
          }
          final data = snap.data!;
          final kpis = [
            StoreKpi('Revenue Today',
                '€${data.revenueToday.toStringAsFixed(2)}', Icons.attach_money),
            StoreKpi('Revenue PY',
                '€${data.revenuePY.toStringAsFixed(2)}', Icons.history),
            StoreKpi('Tx Today', '${data.txToday}', Icons.receipt_long),
            StoreKpi('Tx PY', '${data.txPY}', Icons.history_toggle_off),
            StoreKpi('Avg Basket',
                '€${data.avgBasketToday.toStringAsFixed(2)}',
                Icons.shopping_basket),
            StoreKpi('Avg Basket PY',
                '€${data.avgBasketPY.toStringAsFixed(2)}',
                Icons.shopping_basket_outlined),
            StoreKpi('Peak Hour', data.peakHourLabel, Icons.access_time),
            StoreKpi('Top Article', data.topArtName, Icons.star),
          ];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSection(context, 'Store KPIs', kpis),
          );
        },
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
