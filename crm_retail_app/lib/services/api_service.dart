import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/dashboard_models.dart';
import 'api_routes.dart';

/// Basic HTTP client for the real API.
class ApiService {
  ApiService({this.baseUrl = ApiRoutes.baseUrl});

  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Attempts to authenticate a user. Returns the raw HTTP response so
  /// callers can inspect the status code and body. A 200 response indicates
  /// successful authentication. A 403 response with body `OTP required`
  /// means a one-time code is needed.
  Future<http.Response?> login(
    String username,
    String password,
    String? otp, {
    String? deviceToken,
    bool rememberDevice = false,
  }) async {
    try {
      final payload = {
        'username': username,
        'password': password,
        if (otp != null) 'otp': otp,
        if (deviceToken != null && deviceToken.isNotEmpty)
          'deviceToken': deviceToken,
        if (rememberDevice) 'rememberDevice': rememberDevice,
      };

      print('📤 Sending login payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print('🔄 Login response [${response.statusCode}]: ${response.body}');
      return response;
    } catch (e, stack) {
      print('❌ HTTP error during login: $e\n$stack');
      return null;
    }
  }

  Future<List<SummaryMetric>> fetchMetrics() async {
    final res = await http.get(_uri(ApiRoutes.metrics));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final metricsJson = data['metrics'] as List<dynamic>? ?? [];
    return metricsJson.map((e) {
      final title = e['name'] as String;
      final subs = (e['subMetrics'] as List<dynamic>? ?? [])
          .map(
            (s) => SubMetric(
              title: s['name'] as String,
              value: s['value'].toString(),
              icon: _iconForTitle(s['name'] as String),
              color: _colorForTitle(s['name'] as String),
            ),
          )
          .toList();
      return SummaryMetric(
        title: title,
        value: e['value'].toString(),
        icon: _iconForTitle(title),
        color: _colorForTitle(title),
        subMetrics: subs,
      );
    }).toList();
  }

  /// Fetches dashboard data including metrics, sales series and store
  /// comparisons. The backend returns a `DashboardPayload` object which is
  /// mapped into strongly typed models for the UI layer.
  Future<DashboardData> fetchDashboard() async {
    final res = await http.get(_uri(ApiRoutes.metrics));
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final metrics =
        (data['metrics'] as List<dynamic>? ?? []).map((e) {
          final title = e['name'] as String;
          final subs = (e['subMetrics'] as List<dynamic>? ?? [])
              .map(
                (s) => SubMetric(
                  title: s['name'] as String,
                  value: s['value'].toString(),
                  icon: _iconForTitle(s['name'] as String),
                  color: _colorForTitle(s['name'] as String),
                ),
              )
              .toList();
          return SummaryMetric(
            title: title,
            value: e['value'].toString(),
            icon: _iconForTitle(title),
            color: _colorForTitle(title),
            subMetrics: subs,
          );
        }).toList();

    final daily =
        (data['dailySeries'] as List<dynamic>? ?? [])
            .map(
              (e) => SalesSeries(
                e['label'] as String,
                (e['amount'] as num).toDouble(),
              ),
            )
            .toList();

    final hourly =
        (data['hourlySeries'] as List<dynamic>? ?? [])
            .map(
              (e) => SalesSeries(
                e['label'] as String,
                (e['amount'] as num).toDouble(),
              ),
            )
            .toList();

    final stores =
        (data['storeComparison'] as List<dynamic>? ?? []).map((e) {
          final storeName = (e['store'] as String).trim();

          // Some backend versions omit the numeric store ID and only provide a
          // human readable store name like "Store 101". Extract the digits so
          // that downstream widgets can still fetch detailed KPIs.
          int parseStoreId() {
            final id = e['storeId'];
            if (id is int) return id;
            final match = RegExp(r'\d+').firstMatch(storeName);
            return match != null ? int.parse(match.group(0)!) : 0;
          }

          return StoreSales(
            storeId: parseStoreId(),
            store: storeName,
            lastYear: (e['lastYear'] as num).toDouble(),
            thisYear: (e['thisYear'] as num).toDouble(),
          );
        }).toList();

    return DashboardData(
      metrics: metrics,
      dailySales: daily,
      hourlySales: hourly,
      storeSales: stores,
    );
  }

  Future<StoreKpiDetail?> fetchStoreKpiDetail(int storeId) async {
    final res = await http.get(_uri(ApiRoutes.storeKpi(storeId)));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return StoreKpiDetail.fromJson(data);
  }

  IconData _iconForTitle(String title) {
    switch (title) {
      case 'Cutoff Hour':
        return Icons.schedule;
      case 'Total Revenue':
        return Icons.attach_money;
      case 'Total Revenue PY':
        return Icons.attach_money;
      case 'Transactions':
        return Icons.shopping_cart_checkout;
      case 'Transactions PY':
        return Icons.shopping_cart;
      case 'Avg Basket Size':
        return Icons.shopping_bag;
      case 'Avg Basket Size PY':
        return Icons.shopping_bag;
      case 'Revenue Yesterday':
        return Icons.today;
      case 'Revenue Vs Yesterday':
        return Icons.trending_up;
      case 'Revenue Vs PY':
        return Icons.show_chart;
      case 'Top Product Code':
      case 'Top Product Name':
        return Icons.star;
      case 'Top Store OE':
      case 'Top Store Name':
        return Icons.store;
      case 'Top Store Revenue':
        return Icons.storefront;
      case 'Returns Today':
      case 'Returns Value':
        return Icons.undo;
      case 'Returns Rate':
      case 'Discount Share':
        return Icons.percent;
      case 'Peak Hour':
      case 'Peak Hour Label':
        return Icons.access_time;
      case 'Low Inventory Count':
        return Icons.inventory_2;
      default:
        return Icons.insert_chart;
    }
  }

  Color _colorForTitle(String title) {
    switch (title) {
      case 'Cutoff Hour':
        return Colors.cyan;
      case 'Total Revenue':
        return Colors.green;
      case 'Total Revenue PY':
        return Colors.greenAccent;
      case 'Transactions':
        return Colors.blue;
      case 'Transactions PY':
        return Colors.blueGrey;
      case 'Avg Basket Size':
        return Colors.indigo;
      case 'Avg Basket Size PY':
        return Colors.indigoAccent;
      case 'Revenue Yesterday':
        return Colors.lightGreen;
      case 'Revenue Vs Yesterday':
        return Colors.purple;
      case 'Revenue Vs PY':
        return Colors.deepPurple;
      case 'Top Product Code':
      case 'Top Product Name':
        return Colors.amber;
      case 'Top Store OE':
      case 'Top Store Name':
        return Colors.brown;
      case 'Top Store Revenue':
        return Colors.green;
      case 'Returns Today':
      case 'Returns Value':
      case 'Returns Rate':
        return Colors.redAccent;
      case 'Discount Share':
        return Colors.deepPurple;
      case 'Low Inventory Count':
        return Colors.orange;
      case 'Peak Hour':
      case 'Peak Hour Label':
        return Colors.cyan;
      default:
        return Colors.teal;
    }
  }

  Future<List<StoreSales>> fetchStoreSales() async {
    final res = await http.get(_uri(ApiRoutes.storeSales));
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map(
          (e) => StoreSales(
            storeId: e['storeId'] as int,
            store: (e['store'] as String).trim(),
            lastYear: (e['lastYear'] as num).toDouble(),
            thisYear: (e['thisYear'] as num).toDouble(),
          ),
        )
        .toList();
  }

  /// Fetches detailed KPI metrics for a single store.
  Future<StoreKpiMetrics> fetchStoreKpi(int storeId) async {
    final res = await http.get(_uri(ApiRoutes.storeKpi(storeId)));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return StoreKpiMetrics.fromJson(data);
  }

  /// Returns whether OTP is enabled for the user.
  Future<bool> fetchOtpStatus(String username) async {
    final res = await http.get(
      Uri.parse('$baseUrl${ApiRoutes.totpStatus}?username=$username'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['enabled'] as bool;
    }
    return false;
  }

  /// Enables OTP and returns the generated secret.
  Future<String?> enableOtp(String username) async {
    final res = await http.post(
      _uri(ApiRoutes.enableTotp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['totpSecret'] as String;
    }
    return null;
  }

  /// Disables OTP for the user.
  Future<bool> disableOtp(String username) async {
    final res = await http.post(
      _uri(ApiRoutes.disableTotp),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );
    return res.statusCode == 200;
  }
}
