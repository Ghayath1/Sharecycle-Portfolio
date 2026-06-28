import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final String _baseUrl;
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  AuthService() : _baseUrl = dotenv.maybeGet('API_BASE_URL') ?? 
      (Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080');

  /// Sends a password reset request to the specified email
  /// Returns true if the request was successful
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email.trim()}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to send reset email';
        throw Exception(error);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Resets the password using the provided OTP and new password
  /// Returns true if the password was successfully reset
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/reset-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Failed to reset password';
        throw Exception(error);
      }
    } catch (e) {
      rethrow;
    }
  }
}
