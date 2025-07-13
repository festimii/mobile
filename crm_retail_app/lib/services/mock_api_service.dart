import 'dart:async';
import 'package:flutter/material.dart';

import '../models/dashboard_models.dart';

/// Returns hard coded data used during development.
class MockApiService {
  Future<List<SummaryMetric>> fetchMetrics() async {
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
        store: 'VFS${i + 1}',
        lastYear: 10000 + i * 600,
        thisYear: 12000 + i * 650 - (i % 5 == 0 ? 3000 : 0),
      );
    });
  }

  Future<List<RecentCustomer>> fetchRecentCustomers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
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
  }
}
