import 'package:flutter/material.dart';
import '../../models/dashboard_models.dart';
import '../../services/api_service.dart';

/// Store detail screen
/// - Accepts a `StoreSales` item (has store name and id)
/// - Fetches KPIs from backend
/// - Displays organized KPI sections with derived metrics (%, diffs)
class StoreDetailScreen extends StatefulWidget {
  final StoreSales sales;

  const StoreDetailScreen({super.key, required this.sales});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  late final Future<StoreKpiDetail?> _kpiFuture;

  @override
  void initState() {
    super.initState();
    _kpiFuture = ApiService().fetchStoreKpiDetail(widget.sales.storeId);
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

          // ===== Data for comparison table =====
          final comparisonMetrics = <_ComparisonMetric>[
            _ComparisonMetric(
              'Shitje',
              data.revenueToday,
              data.revenuePY,
              icon: Icons.attach_money,
              isCurrency: true,
            ),
            _ComparisonMetric(
              'Kupona',
              data.txToday.toDouble(),
              data.txPY.toDouble(),
              icon: Icons.receipt_long,
            ),
            _ComparisonMetric(
              'Shporta mesatare',
              data.avgBasketToday,
              data.avgBasketPY,
              icon: Icons.shopping_cart,
              isCurrency: true,
            ),
          ];

          final txDiff = data.txToday - data.txPY;

          final inventoryKpis = <_KpiTile>[
            if ((data.topArtCode ?? '').isNotEmpty)
              _KpiTile('Top Product Code', data.topArtCode!, Icons.qr_code),
            if ((data.topArtName ?? '').isNotEmpty)
              _KpiTile('Top Product', data.topArtName!, Icons.star),
            if (data.topArtRevenue != null)
              _KpiTile(
                'Top Product Rev',
                _eur(data.topArtRevenue!),
                Icons.monetization_on,
              ),
          ];

          final opsKpis = <_KpiTile>[
            _KpiTile('Peak Hour', data.peakHourLabel, Icons.access_time),
            if (data.peakHourRevenue != null)
              _KpiTile(
                'Peak Hour Rev',
                _eur(data.peakHourRevenue!),
                Icons.bar_chart,
              ),
            _KpiTile(
              'Tx Δ',
              txDiff.toString(),
              txDiff >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            ),
          ];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _buildComparisonSection(context, comparisonMetrics),
                if (inventoryKpis.isNotEmpty)
                  _buildSection(context, '📦 Inventory KPIs', inventoryKpis),
                _buildSection(context, '🧮 Operational Metrics', opsKpis),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== UI helpers =====

  Widget _buildComparisonSection(
    BuildContext context,
    List<_ComparisonMetric> metrics,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 Vit per Vit Krahasimi',
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
          childAspectRatio: 1.1,
          children: metrics.map((m) => _ComparisonCard(metric: m)).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<_KpiTile> kpis,
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
          childAspectRatio: 1.1,
          children: kpis.map((kpi) => _KpiCard(kpi: kpi)).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ===== Small value objects / widgets =====

class _ComparisonMetric {
  final String label;
  final double current;
  final double previous;
  final IconData icon;
  final bool isCurrency;

  const _ComparisonMetric(
    this.label,
    this.current,
    this.previous, {
    required this.icon,
    this.isCurrency = false,
  });
}

class _ComparisonCard extends StatelessWidget {
  final _ComparisonMetric metric;
  const _ComparisonCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = metric.current - metric.previous;
    final pct = _pct(metric.current, metric.previous);
    final color = diff >= 0 ? Colors.green : Colors.red;
    String format(num v) => metric.isCurrency ? _eur(v) : v.toStringAsFixed(0);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(metric.icon, color: theme.primaryColor, size: 28),
            const SizedBox(height: 8),
            Text(
              metric.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              format(metric.current),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prev: ${format(metric.previous)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${diff >= 0 ? '+' : ''}${format(diff)} (${pct.toStringAsFixed(1)}%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiTile {
  final String title;
  final String value;
  final IconData icon;

  const _KpiTile(this.title, this.value, this.icon);
}

class _KpiCard extends StatelessWidget {
  final _KpiTile kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(kpi.icon, color: theme.primaryColor, size: 28),
            const SizedBox(height: 10),
            Text(
              kpi.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                kpi.value,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Formatting =====
String _eur(num v) => '€${v.toStringAsFixed(2)}';
double _pct(num cur, num py) {
  if (py == 0) return cur == 0 ? 0 : 100;
  return ((cur - py) / py) * 100.0;
}
