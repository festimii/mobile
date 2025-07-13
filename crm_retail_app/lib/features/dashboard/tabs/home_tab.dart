import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../metric_detail_screen.dart';
import '../store_detail_screen.dart';
import '../../../models/dashboard_models.dart';

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

class StoreSalesTable extends StatefulWidget {
  final List<StoreSales> salesData;

  const StoreSalesTable({super.key, required this.salesData});

  @override
  State<StoreSalesTable> createState() => _StoreSalesTableState();
}

class _StoreSalesTableState extends State<StoreSalesTable> {
  bool sortAscending = false;
  StoreFilter filter = StoreFilter.all;

  void _showStoreDetails(StoreSales sales) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailScreen(sales: sales)),
    );
  }

  List<StoreSales> get filteredSortedData {
    final filtered =
        widget.salesData.where((s) {
          switch (filter) {
            case StoreFilter.positive:
              return s.percentChange > 0;
            case StoreFilter.negative:
              return s.percentChange < 0;
            default:
              return true;
          }
        }).toList();

    filtered.sort(
      (a, b) =>
          sortAscending
              ? a.percentChange.compareTo(b.percentChange)
              : b.percentChange.compareTo(a.percentChange),
    );
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<SummaryMetric> metrics = [
      SummaryMetric(
        title: 'Total Revenue',
        value: '€12,430',
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      SummaryMetric(
        title: 'Transactions',
        value: '845',
        icon: Icons.shopping_cart_checkout,
        color: Colors.blue,
      ),
      SummaryMetric(
        title: 'Avg. Basket Size',
        value: '€14.71',
        icon: Icons.shopping_bag,
        color: Colors.indigo,
      ),
      SummaryMetric(
        title: 'Top Product',
        value: 'Milk 1L',
        icon: Icons.star,
        color: Colors.amber,
      ),
      SummaryMetric(
        title: 'Returns Today',
        value: '12',
        icon: Icons.undo,
        color: Colors.redAccent,
      ),
      SummaryMetric(
        title: 'Low Inventory',
        value: '5 Items',
        icon: Icons.inventory_2,
        color: Colors.orange,
      ),
    ];

    final List<SalesSeries> weekSales = [
      SalesSeries('Mon', 200),
      SalesSeries('Tue', 350),
      SalesSeries('Wed', 280),
      SalesSeries('Thu', 400),
      SalesSeries('Fri', 500),
      SalesSeries('Sat', 450),
      SalesSeries('Sun', 320),
    ];

    final List<SalesSeries> hourSales = List.generate(17, (i) {
      int hour = 8 + i; // display hours from 8 to 24
      return SalesSeries('${hour}h', 100 + i * 5);
    });

    final List<StoreSales> storeSales = List.generate(120, (i) {
      return StoreSales(
        store: 'VFS${i + 1}',
        lastYear: 10000 + i * 600,
        thisYear: 12000 + i * 650 - (i % 5 == 0 ? 3000 : 0),
      );
    });

    final List<RecentCustomer> customers = [
      RecentCustomer(
        name: 'Alice Johnson',
        totalSpent: 250.50,
        lastPurchase: '12 Sep',
      ),
      RecentCustomer(
        name: 'Bob Smith',
        totalSpent: 190.00,
        lastPurchase: '10 Sep',
      ),
      RecentCustomer(
        name: 'Caroline Lee',
        totalSpent: 320.10,
        lastPurchase: '09 Sep',
      ),
    ];

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
              children:
                  metrics
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
                child: SalesTrendCard(weekData: weekSales, hourData: hourSales),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Store Sales Comparison",
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
                child: StoreSalesTable(salesData: storeSales),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Recent Customers",
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
              child: Column(
                children:
                    customers
                        .map((c) => RecentCustomerTile(customer: c))
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Replace StoreSalesTable with AnimatedStoreSalesTable
// Place this at the end of your file or in a separate widget file if preferred

class AnimatedStoreSalesTable extends StatelessWidget {
  final List<StoreSales> salesData;

  const AnimatedStoreSalesTable({super.key, required this.salesData});

  void _showStoreDetails(BuildContext context, StoreSales sale) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoreDetailScreen(sales: sale)),
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
