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
  late final Future<StoreKpiDetail?> _kpiFuture;

  @override
  void initState() {
    super.initState();
    _kpiFuture = ApiService().fetchStoreKpiDetail(widget.sales.storeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sales.store,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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

          // ===== Data for comparison =====
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

          // ===== Single scrollable with slivers =====
          return CustomScrollView(
            slivers: [
              _sliverHeader('📈 Vit per Vit Krahasimi'),
              _sliverGridComparison(comparisonMetrics, crossAxisCount: 2),

              if (inventoryKpis.isNotEmpty) ...[
                _sliverHeader('📦 Inventory KPIs'),
                _sliverGridKpis(inventoryKpis, crossAxisCount: 2),
              ],

              _sliverHeader('🧮 Operational Metrics'),
              _sliverGridKpis(opsKpis, crossAxisCount: 2),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  // ===== Sliver builders =====

  SliverToBoxAdapter _sliverHeader(String title) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }

  SliverPadding _sliverGridComparison(
    List<_ComparisonMetric> items, {
    int crossAxisCount = 2,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _ComparisonCard(metric: items[i]),
          childCount: items.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
      ),
    );
  }

  SliverPadding _sliverGridKpis(
    List<_KpiTile> items, {
    int crossAxisCount = 2,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => _KpiCard(kpi: items[i]),
          childCount: items.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
      ),
    );
  }
}

// ===== Value objects / widgets =====

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
    final isUp = diff >= 0;
    final color = isUp ? Colors.green : Colors.red;

    String fmt(num v) => metric.isCurrency ? _eur(v) : v.toStringAsFixed(0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(metric.icon, color: theme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              metric.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fmt(metric.current),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prev: ${fmt(metric.previous)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${isUp ? '+' : ''}${fmt(diff)} (${pct.toStringAsFixed(1)}%)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

    // Note: avoid Flexible here inside a Column; rely on maxLines/ellipsis instead
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(kpi.icon, color: theme.primaryColor, size: 24),
            const SizedBox(height: 8),
            Text(
              kpi.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              kpi.value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
