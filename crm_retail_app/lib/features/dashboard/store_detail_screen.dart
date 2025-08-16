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

          // ===== Derived metrics (safe guards for division by zero) =====
          double _pct(double cur, double py) {
            if (py == 0) return cur == 0 ? 0 : 100;
            return ((cur - py) / py) * 100.0;
          }

          final revenuePct = _pct(data.revenueToday, data.revenuePY);
          final txPct = _pct(data.txToday.toDouble(), data.txPY.toDouble());
          final revenueDiff = data.revenueToday - data.revenuePY;
          final txDiff = data.txToday - data.txPY;
          final avgBasketDiff = data.avgBasketToday - data.avgBasketPY;

          // ===== KPI groups =====
          final salesKpis = <_KpiTile>[
            _KpiTile('Revenue Today', _eur(data.revenueToday), Icons.today),
            _KpiTile('Revenue PY', _eur(data.revenuePY), Icons.calendar_today),
            _KpiTile(
              'Revenue %',
              '${revenuePct.toStringAsFixed(1)}%',
              revenuePct >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            _KpiTile(
              'Revenue Δ',
              _eur(revenueDiff),
              revenueDiff >= 0 ? Icons.trending_up : Icons.trending_down,
            ),
          ];

          final customerKpis = <_KpiTile>[
            _KpiTile('Tx Today', '${data.txToday}', Icons.receipt_long),
            _KpiTile('Tx PY', '${data.txPY}', Icons.history),
            _KpiTile(
              'Tx %',
              '${txPct.toStringAsFixed(1)}%',
              txPct >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            _KpiTile(
              'Avg Basket Today',
              _eur(data.avgBasketToday),
              Icons.shopping_basket,
            ),
            _KpiTile(
              'Avg Basket PY',
              _eur(data.avgBasketPY),
              Icons.shopping_basket_outlined,
            ),
            _KpiTile(
              'Avg Basket Δ',
              _eur(avgBasketDiff),
              avgBasketDiff >= 0 ? Icons.trending_up : Icons.trending_down,
            ),
          ];

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
                _buildSection(context, '📊 Sales KPIs', salesKpis),
                _buildSection(context, '🛍️ Customer Behavior', customerKpis),
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
          childAspectRatio: 1.2,
          children: kpis.map((kpi) => _KpiCard(kpi: kpi)).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ===== Small value objects / widgets =====

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
  }
}

// ===== Formatting =====
String _eur(num v) => '€${v.toStringAsFixed(2)}';
