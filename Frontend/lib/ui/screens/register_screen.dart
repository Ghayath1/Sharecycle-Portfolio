import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:sharecycleapp/theme/color.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _hidePass = true;
  bool _hideConfirm = true;
  bool _isSubmitting = false;

  // Schlüssel, die nach erfolgreicher Registrierung gelöscht werden
  static const _kAuthTokenKey = 'auth_token';
  static const _kAuthStatusKey = 'auth_status';
  static const _kUserJsonKey   = 'auth_user_json';

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _day.dispose();
    _month.dispose();
    _year.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'E-Mail ist erforderlich';
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!re.hasMatch(v.trim())) return 'Ungültige E-Mail-Adresse';
    return null;
  }

  String? _required(String? v, {String field = 'Dieses Feld'}) {
    if (v == null || v.trim().isEmpty) return '$field ist erforderlich';
    return null;
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Passwort ist erforderlich';
    if (v.length < 6) return 'Mindestens 6 Zeichen erforderlich';
    return null;
  }

  String? _dobPartValidator(String? v, int min, int max, String label) {
    if (v == null || v.isEmpty) return '$label ist erforderlich';
    final n = int.tryParse(v);
    if (n == null) return '$label muss eine Zahl sein';
    if (n < min || n > max) return '$label muss zwischen $min und $max liegen';
    return null;
  }

  DateTime? _composeDate() {
    final d = int.tryParse(_day.text);
    final m = int.tryParse(_month.text);
    final y = int.tryParse(_year.text);
    if (d == null || m == null || y == null) return null;
    try {
      final date = DateTime(y, m, d);
      if (date.year == y && date.month == m && date.day == d) return date;
    } catch (_) {}
    return null;
  }

  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  Future<void> _clearAuthStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuthTokenKey);
    await prefs.remove(_kAuthStatusKey);
    await prefs.remove(_kUserJsonKey);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final dob = _composeDate();
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültiges Geburtsdatum')),
      );
      return;
    }
    if (_password.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwörter stimmen nicht überein')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final base = _apiBase();
      final url = Uri.parse("$base/api/auth/signup");

      final body = {
        "firstName": _firstName.text.trim(),
        "lastName": _lastName.text.trim(),
        "email": _email.text.trim(),
        "password": _password.text,
        "birthDate":
            "${dob.year.toString().padLeft(4, '0')}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}"
      };

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        // ✅ Erfolg: Alte Authentifizierungsdaten löschen, zur Anmeldung gehen
        await _clearAuthStorage();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konto erstellt. Bitte melden Sie sich an.')),
        );
        context.go('/login'); // weiter zur Anmeldung
      } else {
        String msg = 'Fehler ${res.statusCode}';
        try {
          if (res.body.isNotEmpty) {
            final j = jsonDecode(res.body);
            if (j is Map && j['message'] != null) msg = j['message'].toString();
            else msg = res.body;
          }
        } catch (_) {
          if (res.body.isNotEmpty) msg = res.body;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Netzwerkfehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _input(String hint) {
    return const InputDecoration(hintText: '')
        .copyWith(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: orange, width: 1.2),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: orange, width: 1.6),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Registrieren',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: orange),
                    ),
                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstName,
                            decoration: _input('Vorname'),
                            validator: (v) => _required(v, field: 'Vorname'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _lastName,
                            decoration: _input('Nachname'),
                            validator: (v) => _required(v, field: 'Nachname'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _email,
                      decoration: _input('E-Mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _day,
                            decoration: _input('TT'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (v) => _dobPartValidator(v, 1, 31, 'Tag'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _month,
                            decoration: _input('MM'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator: (v) => _dobPartValidator(v, 1, 12, 'Monat'),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _year,
                            decoration: _input('JJJJ'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            validator: (v) => _dobPartValidator(v, 1900, DateTime.now().year, 'Jahr'),
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _password,
                      obscureText: _hidePass,
                      decoration: _input('Passwort').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_hidePass ? Icons.visibility_off : Icons.visibility, color: orange),
                          onPressed: () => setState(() => _hidePass = !_hidePass),
                        ),
                      ),
                      validator: _passwordValidator,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: _hideConfirm,
                      decoration: _input('Passwort wiederholen').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_hideConfirm ? Icons.visibility_off : Icons.visibility, color: orange),
                          onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                        ),
                      ),
                      validator: _passwordValidator,
                      textInputAction: TextInputAction.done,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: orange),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Konto erstellen', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sie haben bereits ein Konto? Anmelden'),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
