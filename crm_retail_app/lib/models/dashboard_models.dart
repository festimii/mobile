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

/// Detailed KPI information for a specific store.
class StoreKpiDetail {
  final int storeId;
  final String storeName;
  final double revenueToday;
  final double revenuePY;
  final int txToday;
  final int txPY;
  final double avgBasketToday;
  final double avgBasketPY;
  final double revenueDiff;
  final double revenuePct;
  final int txDiff;
  final double txPct;
  final double avgBasketDiff;
  final int peakHour;
  final String peakHourLabel;
  final double peakHourRevenue;
  final String topArtCode;
  final double topArtRevenue;
  final String topArtName;

  StoreKpiDetail({
    required this.storeId,
    required this.storeName,
    required this.revenueToday,
    required this.revenuePY,
    required this.txToday,
    required this.txPY,
    required this.avgBasketToday,
    required this.avgBasketPY,
    required this.revenueDiff,
    required this.revenuePct,
    required this.txDiff,
    required this.txPct,
    required this.avgBasketDiff,
    required this.peakHour,
    required this.peakHourLabel,
    required this.peakHourRevenue,
    required this.topArtCode,
    required this.topArtRevenue,
    required this.topArtName,
  });

  factory StoreKpiDetail.fromJson(Map<String, dynamic> json) {
    return StoreKpiDetail(
      storeId: json['storeId'] as int,
      storeName: json['storeName'] as String,
      revenueToday: (json['revenueToday'] as num).toDouble(),
      revenuePY: (json['revenuePY'] as num).toDouble(),
      txToday: json['txToday'] as int,
      txPY: json['txPY'] as int,
      avgBasketToday: (json['avgBasketToday'] as num).toDouble(),
      avgBasketPY: (json['avgBasketPY'] as num).toDouble(),
      revenueDiff: (json['revenueDiff'] as num).toDouble(),
      revenuePct: (json['revenuePct'] as num).toDouble(),
      txDiff: json['txDiff'] as int,
      txPct: (json['txPct'] as num).toDouble(),
      avgBasketDiff: (json['avgBasketDiff'] as num).toDouble(),
      peakHour: json['peakHour'] as int,
      peakHourLabel: json['peakHourLabel'] as String,
      peakHourRevenue: (json['peakHourRevenue'] as num).toDouble(),
      topArtCode: json['topArtCode'] as String,
      topArtRevenue: (json['topArtRevenue'] as num).toDouble(),
      topArtName: json['topArtName'] as String,
    );
  }
}
