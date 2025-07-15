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
  Future<http.Response> login(
    String username,
    String password, {
    String? otp,
  }) async {
    final res = await http.post(
      _uri(ApiRoutes.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        if (otp != null) 'otp': otp,
      }),
    );
    return res;
  }

  Future<List<SummaryMetric>> fetchMetrics() async {
    final res = await http.get(_uri(ApiRoutes.metrics));
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => SummaryMetric(
              title: e['title'],
              value: e['value'],
              icon: Icons.insert_chart, // placeholder
              color: Colors.teal,
            ))
        .toList();
  }

  Future<List<StoreSales>> fetchStoreSales() async {
    final res = await http.get(_uri(ApiRoutes.storeSales));
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => StoreSales(
              store: e['store'],
              lastYear: (e['lastYear'] as num).toDouble(),
              thisYear: (e['thisYear'] as num).toDouble(),
            ))
        .toList();
  }
}
