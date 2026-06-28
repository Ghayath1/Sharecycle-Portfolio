import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharecycleapp/payment_models.dart';

/// Service für Aufrufe an die Zahlungs-API (PayPal-Flow)
class PaymentService {
  static const String _authTokenKey = 'auth_token';

  /// API-Basis ermitteln
  String _getApiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return 'http://localhost:8080';
  }

  /// Token aus SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  /// Zahlungsauftrag erstellen – POST /api/payment/orders
  Future<PaymentOrderResponse> createPaymentOrder({
    required int bicycleId,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final apiBase = _getApiBase();
    final token = await _getAuthToken();
    final uri = Uri.parse('$apiBase/api/payment/orders');

    // Datum formatieren (YYYY-MM-DD)
    final dateFormatter = (DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final body = jsonEncode({
      'bicycleId': bicycleId,
      'dateFrom': dateFormatter(dateFrom),
      'dateTo': dateFormatter(dateTo),
    });

    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return PaymentOrderResponse.fromJson(jsonResponse);
      } else {
        String errorMessage =
            'Erstellung des Zahlungsauftrags fehlgeschlagen (${response.statusCode}).';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson is Map && errorJson['message'] != null) {
            errorMessage = errorJson['message'].toString();
          }
        } catch (_) {}
        throw PaymentException(errorMessage, response.statusCode);
      }
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Netzwerkfehler: $e', null);
    }
  }

  /// Zahlung autorisieren – POST /api/payment/orders/{paypalOrderId}/authorize
  Future<void> authorizePayment(String paypalOrderId) async {
    final apiBase = _getApiBase();
    final token = await _getAuthToken();
    final uri = Uri.parse('$apiBase/api/payment/orders/$paypalOrderId/authorize');

    final headers = {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(uri, headers: headers);

      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorMessage =
            'Zahlungsautorisierung fehlgeschlagen (${response.statusCode}).';
        try {
          final errorJson = jsonDecode(response.body);
          if (errorJson is Map && errorJson['message'] != null) {
            errorMessage = errorJson['message'].toString();
          }
        } catch (_) {}
        throw PaymentException(errorMessage, response.statusCode);
      }
      // Erfolg – keine Rückgabe nötig
    } catch (e) {
      if (e is PaymentException) rethrow;
      throw PaymentException('Netzwerkfehler während der Autorisierung: $e', null);
    }
  }
}

/// Eigene Exception für Zahlungsfehler
class PaymentException implements Exception {
  final String message;
  final int? statusCode;

  const PaymentException(this.message, this.statusCode);

  @override
  String toString() => 'PaymentException: $message (Status: $statusCode)';
}
