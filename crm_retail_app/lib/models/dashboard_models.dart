import 'package:flutter/material.dart';

/// Basic data model representing a quick dashboard metric.
class SummaryMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  SummaryMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

/// Simple series used for sales charts.
class SalesSeries {
  final String day;
  final double sales;

  SalesSeries(this.day, this.sales);
}

/// Recent customer information for the dashboard.
class RecentCustomer {
  final String name;
  final double totalSpent;
  final String lastPurchase;

  RecentCustomer({
    required this.name,
    required this.totalSpent,
    required this.lastPurchase,
  });
}

/// Sales data per store for comparison tables.
class StoreSales {
  final String store;
  final double lastYear;
  final double thisYear;

  StoreSales({
    required this.store,
    required this.lastYear,
    required this.thisYear,
  });

  double get percentChange => ((thisYear - lastYear) / lastYear) * 100;
}

/// Aggregated payload returned from the backend for the dashboard screen.
///
/// It contains summary metrics, time series data for daily/hourly sales and
/// comparative store sales figures.
class DashboardData {
  final List<SummaryMetric> metrics;
  final List<SalesSeries> dailySales;
  final List<SalesSeries> hourlySales;
  final List<StoreSales> storeSales;

  DashboardData({
    required this.metrics,
    required this.dailySales,
    required this.hourlySales,
    required this.storeSales,
  });
}
