import 'package:flutter/material.dart';
import 'home_tab.dart';
import '../../../models/dashboard_models.dart';

/// Sales tab showing KPIs for both B2C and B2B online sales.
class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  Widget _buildContent(
    BuildContext context,
    List<SummaryMetric> metrics,
    List<SalesSeries> week,
    List<SalesSeries> hour,
  ) {
    final double cardWidth =
        MediaQuery.of(context).size.width > 600
            ? 260
            : MediaQuery.of(context).size.width / 2 - 22;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Akoma e Pa perfunduar te dhena FAKE",
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
                      (m) => SizedBox(
                        width: cardWidth,
                        child: SummaryCard(metric: m),
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
              child: SalesTrendCard(weekData: week, hourData: hour),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b2cMetrics = [
      SummaryMetric(
        title: 'Online Revenue',
        value: '€12,430',
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      SummaryMetric(
        title: 'Orders',
        value: '845',
        icon: Icons.shopping_cart_checkout,
        color: Colors.blue,
      ),
      SummaryMetric(
        title: 'Avg Order Value',
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
        title: 'Return Rate',
        value: '2%',
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

    final b2bMetrics = [
      SummaryMetric(
        title: 'Online Revenue',
        value: '€24,800',
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      SummaryMetric(
        title: 'Orders',
        value: '52',
        icon: Icons.shopping_cart_checkout,
        color: Colors.blue,
      ),
      SummaryMetric(
        title: 'Avg Order Value',
        value: '€477',
        icon: Icons.shopping_bag,
        color: Colors.indigo,
      ),
      SummaryMetric(
        title: 'Top Region',
        value: 'North',
        icon: Icons.location_city,
        color: Colors.amber,
      ),
      SummaryMetric(
        title: 'New Customers',
        value: '4',
        icon: Icons.person_add,
        color: Colors.teal,
      ),
      SummaryMetric(
        title: 'Pending Payments',
        value: '3',
        icon: Icons.access_time,
        color: Colors.redAccent,
      ),
    ];

    final weekSalesB2c = [
      SalesSeries('Mon', 200),
      SalesSeries('Tue', 350),
      SalesSeries('Wed', 280),
      SalesSeries('Thu', 400),
      SalesSeries('Fri', 500),
      SalesSeries('Sat', 450),
      SalesSeries('Sun', 320),
    ];

    final weekSalesB2b = [
      SalesSeries('Mon', 400),
      SalesSeries('Tue', 520),
      SalesSeries('Wed', 480),
      SalesSeries('Thu', 610),
      SalesSeries('Fri', 710),
      SalesSeries('Sat', 680),
      SalesSeries('Sun', 430),
    ];

    final hourSalesB2c = List.generate(17, (i) {
      int hour = 8 + i;
      return SalesSeries('${hour}h', 100 + i * 5);
    });

    final hourSalesB2b = List.generate(17, (i) {
      int hour = 8 + i;
      return SalesSeries('${hour}h', 200 + i * 8);
    });

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const TabBar(tabs: [Tab(text: 'B2C'), Tab(text: 'B2B')]),
        body: TabBarView(
          children: [
            _buildContent(context, b2cMetrics, weekSalesB2c, hourSalesB2c),
            _buildContent(context, b2bMetrics, weekSalesB2b, hourSalesB2b),
          ],
        ),
      ),
    );
  }
}
