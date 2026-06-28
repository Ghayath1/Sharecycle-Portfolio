import 'dart:convert';
import 'dart:io' show Platform, File;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _first = TextEditingController();
  final _last  = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController(); // iphoneNumber
  final _city  = TextEditingController();
  final _dob   = TextEditingController();

  final _imageUrl = TextEditingController();     // server path or absolute URL
  final _idCardNumber = TextEditingController(); // optional

  XFile? _pickedImage; // local (not yet uploaded)

  bool _loading = true;
  bool _saving  = false;
  bool _uploadingImage = false;

  // 🔑 make sure your login saves the token under this key
  static const _kAuthTokenKey = 'auth_token';
  static const _kUserJsonKey  = 'auth_user_json';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _first.dispose(); _last.dispose(); _email.dispose();
    _phone.dispose(); _city.dispose(); _dob.dispose();
    _imageUrl.dispose(); _idCardNumber.dispose();
    super.dispose();
  }

  // ================= Drawer =================
  void _handleDrawerSelect(BuildContext context, AppDrawerKey key) {
    Navigator.of(context).maybePop();
    switch (key) {
      case AppDrawerKey.logout: context.go('/login'); break;
      case AppDrawerKey.home:   context.go('/home'); break;
      case AppDrawerKey.maps:   context.go('/maps'); break;
      case AppDrawerKey.setting:context.go('/settings'); break;
      case AppDrawerKey.privacy:context.go('/privacy'); break;
      case AppDrawerKey.police: context.go('/police'); break;
      case AppDrawerKey.bikes:  context.go('/bikes'); break;
      case AppDrawerKey.myBikes: context.go('/my-bikes');  break;
      case AppDrawerKey.ownerOrders: context.go('/orders');  break;
      case AppDrawerKey.myRentals: context.go("/my-orders"); break;
    }
  }

  // ================= Helpers =================
  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  // Resolve /uploads/... to full URL
  String? _resolveToFullUrl(String? path) {
    if (path == null) return null;
    final p = path.trim();
    if (p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    final base = _apiBase();
    if (p.startsWith('/')) return '$base$p';
    return '$base/$p';
  }

  Map<String, String> _jsonAuthHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, String> _multipartAuthHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: orange, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: orange, width: 1.6),
    ),
  );

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Erforderlich' : null;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dob.text) ?? DateTime(now.year - 20, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      _dob.text = '${picked.year.toString().padLeft(4, '0')}-'
          '${picked.month.toString().padLeft(2, '0')}-'
          '${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  int? _calcAge(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      final now = DateTime.now();
      int age = now.year - d.year;
      if (now.month < d.month || (now.month == d.month && now.day < d.day)) age--;
      return age;
    } catch (_) {
      return null;
    }
  }

  // ================= API: GET profile =================
  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kAuthTokenKey);

      // 🔍 print on fetch too (optional)
      debugPrint('Profile fetch → JWT Token: $token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nicht authentifiziert. Bitte melden Sie sich an')),
        );
        context.go('/login');
        return;
      }

      final url = Uri.parse('${_apiBase()}/api/user/profile');
      final res = await http.get(url, headers: _jsonAuthHeaders(token));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        // Split "name" -> first/last
        final name = (data['name'] ?? '').toString().trim();
        String first = '';
        String last  = '';
        if (name.isNotEmpty) {
          final parts = name.split(RegExp(r'\s+'));
          first = parts.isNotEmpty ? parts.first : '';
          last  = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }

        _first.text = first.isNotEmpty ? first : _first.text;
        _last.text  = last.isNotEmpty  ? last  : _last.text;
        _email.text = (data['email'] ?? _email.text).toString();
        _phone.text = (data['iphoneNumber'] ?? data['phone'] ?? data['phoneNumber'] ?? _phone.text).toString();
        _city.text  = (data['city'] ?? _city.text).toString();
        _dob.text   = (data['birthDate'] ?? _dob.text).toString();
        _imageUrl.text = (data['imageUrl'] ?? _imageUrl.text).toString();
        _idCardNumber.text = (data['idCardNumber'] ?? _idCardNumber.text).toString();

        _pickedImage = null; // clear any local pick
        await prefs.setString(_kUserJsonKey, jsonEncode(data));
      } else {
        String msg = 'Profil konnte nicht geladen werden (${res.statusCode})';
        try {
          final j = jsonDecode(res.body);
          if (j is Map && j['message'] != null) msg = j['message'].toString();
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Netzwerkfehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= Avatar: pick from Gallery DIRECTLY + upload =================
  Future<void> _pickFromGalleryAndUpload() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (img == null) return;

      setState(() {
        _pickedImage = img;       // show immediately
        _uploadingImage = true;   // spinner overlay
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kAuthTokenKey);

      // 🔍 print token when uploading avatar
      debugPrint('Avatar upload → JWT Token: $token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nicht authentifiziert. Bitte melden Sie sich an.')),
        );
        context.go('/login');
        return;
      }

      final uri = Uri.parse('${_apiBase()}/api/user/profile');
      final req = http.MultipartRequest('PUT', uri)
        ..headers.addAll(_multipartAuthHeaders(token));

      final mime = lookupMimeType(img.path) ?? 'image/jpeg';
      final parts = mime.split('/');
      req.files.add(await http.MultipartFile.fromPath(
        'image', // server must expect this field
        img.path,
        contentType: MediaType(parts.first, parts.last),
      ));

      final resp = await http.Response.fromStream(await req.send());
      debugPrint('Avatar upload → Response ${resp.statusCode}: ${resp.body}');

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Hochladen fehlgeschlagen (${resp.statusCode}): ${resp.body}');
      }

      try {
        final map = jsonDecode(resp.body);
        if (map is Map<String, dynamic>) {
          await prefs.setString(_kUserJsonKey, jsonEncode(map));
          if (map['imageUrl'] != null) {
            _imageUrl.text = map['imageUrl'].toString();
          }
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profilbild aktualisiert')),
      );
      await _fetchProfile(); // fetch canonical URL from server
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  // ================= Save profile (JSON) =================
  Future<void> _updateProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kAuthTokenKey);

      // 🔍 print token when updating profile
      debugPrint('Profile update → JWT Token: $token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nicht authentifiziert. Bitte melden Sie sich an.')),
        );
        context.go('/login');
        return;
      }

      final url = Uri.parse('${_apiBase()}/api/user/profile');
      final payload = <String, dynamic>{
        "name": "${_first.text.trim()} ${_last.text.trim()}".trim(),
        "email": _email.text.trim(),
        "birthDate": _dob.text.trim(),
        "iphoneNumber": _phone.text.trim(),
        "city": _city.text.trim(),
        if (_imageUrl.text.trim().isNotEmpty) "imageUrl": _imageUrl.text.trim(),
        if (_idCardNumber.text.trim().isNotEmpty) "idCardNumber": _idCardNumber.text.trim(),
      };

      final res = await http.put(
        url,
        headers: _jsonAuthHeaders(token),
        body: jsonEncode(payload),
      );

      debugPrint('Profile update → Response ${res.statusCode}: ${res.body}');

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }

      try {
        final updated = jsonDecode(res.body);
        if (updated is Map<String, dynamic>) {
          await prefs.setString(_kUserJsonKey, jsonEncode(updated));
        }
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile aktualisiert')),
      );
      await _fetchProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktualisierung fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = _calcAge(_dob.text);
    final resolvedUrl = _resolveToFullUrl(_imageUrl.text);

    final ImageProvider avatarImage = _pickedImage != null
        ? FileImage(File(_pickedImage!.path))
        : (resolvedUrl != null
            ? NetworkImage(resolvedUrl)
            : const AssetImage('assets/images/profile.jpg')) as ImageProvider;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(onSelect: (key) => _handleDrawerSelect(context, key)),
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
        backgroundColor: orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _fetchProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar + edit button + spinner overlay
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(radius: 44, backgroundImage: avatarImage),
                          if (_uploadingImage)
                            const Positioned.fill(
                              child: Center(
                                child: SizedBox(
                                  height: 28, width: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                              ),
                            ),
                          Material(
                            color: orange,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: _uploadingImage ? null : _pickFromGalleryAndUpload,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(Icons.edit, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (age != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEBD6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Alt: $age',
                              style: const TextStyle(color: orange, fontWeight: FontWeight.w700)),
                        ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _first,
                              decoration: _dec('Vorname'),
                              validator: _required,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _last,
                              decoration: _dec('Nachname'),
                              validator: _required,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _email,
                        decoration: _dec('Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (_required(v) != null) return 'Erforderlich';
                          final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                          if (!re.hasMatch(v!.trim())) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phone,
                        decoration: _dec('Phone (+49 …)'),
                        keyboardType: TextInputType.phone,
                        validator: _required,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _city,
                        decoration: _dec('Stadt'),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _dob,
                        readOnly: true,
                        decoration: _dec('Geburtsdatum (YYYY-MM-DD)').copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today, color: orange),
                            onPressed: _pickDate,
                          ),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _idCardNumber,
                        decoration: _dec('Ausweisnummer(optional)'),
                      ),
                      const SizedBox(height: 12),

                      /* If you want to expose manual URL edit:
                      TextFormField(
                        controller: _imageUrl,
                        decoration: _dec('Profile Image URL (optional)'),
                        keyboardType: TextInputType.url,
                      ),*/

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _saving ? null : _updateProfile,
                          child: _saving
                              ? const SizedBox(
                                  height: 22, width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Speichern', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: 3,
        onTap: (i) {
          switch (i) {
            case 0: context.go('/home'); break;
            case 1: context.go('/bikes'); break;
            case 2: context.go('/maps'); break;
            case 3: context.go('/profile'); break;
          }
        },
      ),
    );
  }
}
