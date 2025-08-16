import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../metric_detail_screen.dart';
import '../store_detail_screen.dart';
import '../../../models/dashboard_models.dart';
import '../../../services/api_service.dart';

class SummaryCard extends StatelessWidget {
  final SummaryMetric metric;

  const SummaryCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MetricDetailScreen(metric: metric)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Card(
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
      ),
    );
  }
}



class SalesBarChart extends StatelessWidget {
  final List<SalesSeries> data;

  const SalesBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                int index = value.toInt();
                if (index >= 0 && index < data.length) {
                  // On dense hour charts, only show every other label
                  if (data.length > 12 && index.isOdd) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    data[index].day,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups:
            data.asMap().entries.map((entry) {
              int x = entry.key;
              double y = entry.value.sales;
              return BarChartGroupData(
                x: x,
                barRods: [
                  BarChartRodData(
                    toY: y,
                    width: 14,
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.teal,
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

class SalesTrendCard extends StatelessWidget {
  final List<SalesSeries> weekData;
  final List<SalesSeries> hourData;

  const SalesTrendCard({
    super.key,
    required this.weekData,
    required this.hourData,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Theme.of(context).primaryColor,
            tabs: const [Tab(text: 'Week'), Tab(text: 'Hour')],
          ),
          SizedBox(
            height: 220,
            child: TabBarView(
              children: [
                SalesBarChart(data: weekData),
                SalesBarChart(data: hourData),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays basic information about a customer.
class RecentCustomerTile extends StatelessWidget {
  final RecentCustomer customer;

  const RecentCustomerTile({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(customer.name.substring(0, 1))),
      title: Text(customer.name),
      subtitle: Text('Spent €${customer.totalSpent.toStringAsFixed(2)}'),
      trailing: Text(customer.lastPurchase),
    );
  }
}

enum StoreFilter { all, positive, negative }

enum StoreSort { storeNumber, percentChange }

class StoreSalesTable extends StatefulWidget {
  final List<StoreSales> salesData;

  const StoreSalesTable({super.key, required this.salesData});

  @override
  State<StoreSalesTable> createState() => _StoreSalesTableState();
}

class _StoreSalesTableState extends State<StoreSalesTable> {
  bool sortAscending = true;
  StoreFilter filter = StoreFilter.all;
  StoreSort sortBy = StoreSort.storeNumber;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showStoreDetails(StoreSales sales) async {
    final api = ApiService();
    final metrics = await api.fetchStoreKpi(sales.storeId);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailScreen(metrics: metrics)),
    );
  }

  List<StoreSales> get filteredSortedData {
    final filtered = widget.salesData.where((s) {
      switch (filter) {
        case StoreFilter.positive:
          return s.percentChange > 0;
        case StoreFilter.negative:
          return s.percentChange < 0;
        default:
          return true;
      }
    }).toList();

    if (_searchCtrl.text.isNotEmpty) {
      final query = _searchCtrl.text.trim().toLowerCase();
      filtered.retainWhere(
          (s) => s.store.toLowerCase().trim().contains(query));
    }

    filtered.sort((a, b) {
      int comparison;
      if (sortBy == StoreSort.storeNumber) {
        final aNum = int.tryParse(RegExp(r'\d+').firstMatch(a.store)?.group(0) ?? '') ?? 0;
        final bNum = int.tryParse(RegExp(r'\d+').firstMatch(b.store)?.group(0) ?? '') ?? 0;
        comparison = aNum.compareTo(bNum);
      } else {
        comparison = a.percentChange.compareTo(b.percentChange);
      }
      return sortAscending ? comparison : -comparison;
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DropdownButton<StoreFilter>(
              value: filter,
              onChanged: (value) => setState(() => filter = value!),
              items: const [
                DropdownMenuItem(
                  value: StoreFilter.all,
                  child: Text("All Stores"),
                ),
                DropdownMenuItem(
                  value: StoreFilter.positive,
                  child: Text("Positive"),
                ),
              DropdownMenuItem(
                value: StoreFilter.negative,
                child: Text("Negative"),
              ),
            ],
            ),
        const SizedBox(width: 16),
        DropdownButton<StoreSort>(
          value: sortBy,
          onChanged: (value) => setState(() => sortBy = value!),
          items: const [
            DropdownMenuItem(
              value: StoreSort.storeNumber,
              child: Text('Store #'),
            ),
            DropdownMenuItem(
              value: StoreSort.percentChange,
              child: Text('% Change'),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            const Text("Ascending"),
            Switch(
              value: sortAscending,
              onChanged: (val) => setState(() => sortAscending = val),
            ),
          ],
        ),
      ],
    ),
    const SizedBox(height: 12),
    TextField(
      controller: _searchCtrl,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Search stores',
      ),
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 12),
    ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredSortedData.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final s = filteredSortedData[index];
            final pct = s.percentChange;
            final isPositive = pct > 0;
            final isNegative = pct < 0;

            final pctColor =
                isPositive
                    ? Colors.green
                    : isNegative
                    ? Colors.red
                    : Colors.grey;

            final bgColor =
                isPositive
                    ? Colors.green.withOpacity(0.06)
                    : isNegative
                    ? Colors.red.withOpacity(0.06)
                    : Colors.grey.withOpacity(0.04);

            return TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 500),
              tween: ColorTween(begin: Colors.white, end: bgColor),
              builder: (_, color, __) {
                return Material(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _showStoreDetails(s),
                    borderRadius: BorderRadius.circular(12),
                    splashColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.storefront,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.store,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '€${s.thisYear.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.arrow_upward
                                    : isNegative
                                    ? Icons.arrow_downward
                                    : Icons.remove,
                                size: 18,
                                color: pctColor,
                              ),
                              const SizedBox(width: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: pctColor,
                                ),
                                child: Text('${pct.toStringAsFixed(1)}%'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ApiService _api = ApiService();
  late Future<DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text('Error loading dashboard'));
        }

        final data = snapshot.data!;
        final metrics = data.metrics;
        final weekSales = data.dailySales;
        final hourSales = data.hourlySales;
        final storeSales = data.storeSales;

        final double cardWidth =
            MediaQuery.of(context).size.width > 600
                ? 260
                : MediaQuery.of(context).size.width / 2 - 22;

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            tooltip: 'New Sale',
            child: const Icon(Icons.add),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Retail KPIs",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .map(
                        (metric) => SizedBox(
                          width: cardWidth,
                          child: SummaryCard(metric: metric),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 32),
                Text(
                  "Weekly Sales Trend",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SalesTrendCard(
                      weekData: weekSales,
                      hourData: hourSales,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "Store Comparison",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: AnimatedStoreSalesTable(salesData: storeSales),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
// Replace StoreSalesTable with AnimatedStoreSalesTable
// Place this at the end of your file or in a separate widget file if preferred

class AnimatedStoreSalesTable extends StatelessWidget {
  final List<StoreSales> salesData;

  const AnimatedStoreSalesTable({super.key, required this.salesData});

  Future<void> _showStoreDetails(BuildContext context, StoreSales sale) async {
    final api = ApiService();
    final metrics = await api.fetchStoreKpi(sale.storeId);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailScreen(metrics: metrics)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<StoreSales>.from(salesData)
      ..sort((a, b) => b.percentChange.compareTo(a.percentChange));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final sale = sorted[index];
        final pct = sale.percentChange;
        final isPositive = pct > 0;
        final isNegative = pct < 0;

        final bgColor =
            isPositive
                ? Colors.green.withOpacity(0.06)
                : isNegative
                ? Colors.red.withOpacity(0.06)
                : Colors.grey.withOpacity(0.03);

        final pctColor =
            isPositive
                ? Colors.green
                : isNegative
                ? Colors.red
                : Colors.grey;

        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(begin: Colors.white, end: bgColor),
          duration: const Duration(milliseconds: 600),
          builder: (_, color, __) {
            return Material(
              color: color,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _showStoreDetails(context, sale),
                borderRadius: BorderRadius.circular(12),
                splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.storefront,
                        size: 28,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.store,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '€${sale.thisYear.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : isNegative
                                ? Icons.arrow_downward
                                : Icons.remove,
                            size: 18,
                            color: pctColor,
                          ),
                          const SizedBox(width: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: pctColor,
                            ),
                            child: Text('${pct.toStringAsFixed(1)}%'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
