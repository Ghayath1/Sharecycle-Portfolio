import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // reads API_BASE_URL
import 'package:sharecycleapp/theme/color.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onRegisterTap;

  const LoginScreen({Key? key, this.onRegisterTap}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String email = '';
  String password = '';
  bool passwordVisible = false;
  bool loading = false;

  // Storage keys (change if you prefer other names)
  static const _kAuthTokenKey = 'auth_token';
  static const _kAuthStatusKey = 'auth_status';
  static const _kUserJsonKey = 'auth_user_json';

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("owner_id");
    await prefs.remove("renter_id");
    if (email.trim().isEmpty || password.isEmpty) {
      _toast('Please enter email and password');
      return;
    }

    final base = dotenv.maybeGet('API_BASE_URL');
    final url = Uri.parse('$base/api/auth/login');

    setState(() => loading = true);
    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // Expecting: { token: "...", status: "success", user: {...} }
        final token = data['token'] as String?;
        final status = data['status']?.toString();
        final user = data['user'];

        if (token == null) {
          _toast('Login succeeded but token is missing.');
          setState(() => loading = false);
          return;
        }

        print("token: "+ token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kAuthTokenKey, token);
        if (status != null) await prefs.setString(_kAuthStatusKey, status);
        if (user != null) await prefs.setString(_kUserJsonKey, jsonEncode(user));
        if(user != null) await prefs.setString("current_user_id", user['id'].toString());
        await prefs.setString("is_logged_in", "true");
        final fcmToken = prefs.getString("fcm_token") ?? "";
        await sendFcmTokenToServer(fcmToken, token);
        // Navigate to Home
        if (!mounted) return;
        context.go('/home');
      } else {
        // Try to read error message
        String message = 'Login failed (${res.statusCode}).';
        try {
          final err = jsonDecode(res.body);
          if (err is Map && err['message'] != null) {
            message = err['message'].toString();
          }
        } catch (_) {}
        _toast(message);
      }
    } catch (e) {
      _toast('Network error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 500,
                child: Image.asset('assets/images/login_bike.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              Text(
                'Share Cycle',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: orange),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'E Mail',
                        prefixIcon: Icon(Icons.email, color: orange),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: orange)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: orange, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) => setState(() => email = value),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        hintText: 'Passwort',
                        prefixIcon: Icon(Icons.lock, color: orange),
                        suffixIcon: IconButton(
                          icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off, color: orange),
                          onPressed: () => setState(() => passwordVisible = !passwordVisible),
                        ),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: orange)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: orange, width: 2)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.visiblePassword,
                      onChanged: (value) => setState(() => password = value),
                    ),
                    // const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Passwort vergessen?',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                        ),
                        child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Haben Sie kein Konto?", style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: Text('Registrieren', style: TextStyle(fontSize: 14, color: orange)),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> sendFcmTokenToServer(String fcmToken, String token) async {
  try {
    // Get device ID using device_info_plus package
    final deviceInfo = DeviceInfoPlugin();
    String? deviceId;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      print("device_id: " + deviceId);
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    } else {
      deviceId = 'unknown_device';
    }

    final baseUrl = dotenv.maybeGet("API_BASE_URL") ?? "";
    // Send to your server
    final response = await http.post(
      Uri.parse('$baseUrl/api/fcm/token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'fcmToken': fcmToken,
        'deviceId': deviceId,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ FCM token and device ID sent successfully');
    } else {
      print('❌ Failed to send FCM token: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ Error sending FCM token: $e');
  }
}
