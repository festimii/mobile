import 'dart:async';
import 'package:flutter/material.dart';

import '../models/dashboard_models.dart';

/// Returns hard coded data used during development.
class MockApiService {
  Future<List<SummaryMetric>> fetchMetrics({DateTime? date}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
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
        title: 'Avg Basket Size',
        value: '€14.71',
        icon: Icons.shopping_bag,
        color: Colors.indigo,
      ),
      SummaryMetric(
        title: 'Top Product Code',
        value: '018867',
        icon: Icons.star,
        color: Colors.amber,
      ),
      SummaryMetric(
        title: 'Top Product Name',
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
        title: 'Returns Value',
        value: '€150',
        icon: Icons.undo,
        color: Colors.redAccent,
      ),
      SummaryMetric(
        title: 'Returns Rate',
        value: '2.5%',
        icon: Icons.percent,
        color: Colors.redAccent,
      ),
      SummaryMetric(
        title: 'Discount Share',
        value: '1.2%',
        icon: Icons.percent,
        color: Colors.deepPurple,
      ),
      SummaryMetric(
        title: 'Low Inventory Count',
        value: '5',
        icon: Icons.inventory_2,
        color: Colors.orange,
      ),
    ];
  }

  Future<List<SalesSeries>> fetchWeeklySales() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      SalesSeries('Mon', 200),
      SalesSeries('Tue', 350),
      SalesSeries('Wed', 280),
      SalesSeries('Thu', 400),
      SalesSeries('Fri', 500),
      SalesSeries('Sat', 450),
      SalesSeries('Sun', 320),
    ];
  }

  Future<List<SalesSeries>> fetchHourlySales() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.generate(17, (i) {
      int hour = 8 + i;
      return SalesSeries('${hour}h', 100 + i * 5);
    });
  }

  Future<List<StoreSales>> fetchStoreSales() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.generate(120, (i) {
      return StoreSales(
        storeId: i + 1,
        store: 'VFS${i + 1}',
        lastYear: 10000 + i * 600,
        thisYear: 12000 + i * 650 - (i % 5 == 0 ? 3000 : 0),
      );
    });
  }

  Future<StoreKpiMetrics> fetchStoreKpi(int storeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return StoreKpiMetrics(
      storeId: storeId,
      storeName: 'VFS 01 Ferizaj',
      revenueToday: 6105.48,
      revenuePy: 7170.55,
      txToday: 780,
      txPy: 1078,
      avgBasketToday: 7.83,
      avgBasketPy: 6.65,
      revenueDiff: -1065.07,
      revenuePct: -14.85,
      txDiff: -298,
      txPct: -27.64,
      avgBasketDiff: 1.18,
      peakHour: 18,
      peakHourLabel: '18h',
      peakHourRevenue: 723.62,
      topArtCode: '017419',
      topArtRevenue: 185.10,
      topArtName: 'Red Bull 0.25L',
    );
  }
}
