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
    String? otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          if (otp != null) 'otp': otp, // ✅ only include if available
        }),
      );

      if (response.statusCode == 200) {
        return response;
      } else {
        print('Login failed: ${response.statusCode} ${response.body}');
        return response;
      }
    } catch (e, stack) {
      print('HTTP error during login: $e\n$stack');
      return null;
    }
  }

  Future<List<SummaryMetric>> fetchMetrics() async {
    final res = await http.get(_uri(ApiRoutes.metrics));
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map(
          (e) => SummaryMetric(
            title: e['title'],
            value: e['value'],
            icon: Icons.insert_chart, // placeholder
            color: Colors.teal,
          ),
        )
        .toList();
  }

  Future<List<StoreSales>> fetchStoreSales() async {
    final res = await http.get(_uri(ApiRoutes.storeSales));
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map(
          (e) => StoreSales(
            store: e['store'],
            lastYear: (e['lastYear'] as num).toDouble(),
            thisYear: (e['thisYear'] as num).toDouble(),
          ),
        )
        .toList();
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
