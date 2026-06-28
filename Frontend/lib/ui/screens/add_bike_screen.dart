import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sharecycleapp/theme/color.dart';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddBikeScreen extends StatefulWidget {
  const AddBikeScreen({super.key});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  // Use the SAME key your login saved the token with
  static const _kAuthTokenKey = 'auth_token';

  final _formKey = GlobalKey<FormState>();

  final _nameCtrl  = TextEditingController(text: 'My Bike');
  final _cityCtrl  = TextEditingController(text: 'Köln');
  final _priceCtrl = TextEditingController(text: '75');
  final _dateCtrl  = TextEditingController(text: '2025-08-02');
  final _descCtrl  = TextEditingController(text: 'Great bike');

  DateTime? _date;
  XFile? _image;
  bool _submitting = false;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _priceCtrl.dispose();
    _dateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // Base URL from .env, with emulator-safe fallback
  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  Uri _endpointUri() => Uri.parse('${_apiBase()}/api/bicycles');

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Galerie'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Kamera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ]),
      ),
    );
    if (source == null) return;

    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 1);
    final last  = DateTime(now.year + 3);
    final initial = _date ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      _date = picked;
      _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  Future<void> _saveBike() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    FocusScope.of(context).unfocus();

    try {
      // 1) read token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kAuthTokenKey);
      debugPrint('AddBike → JWT Token: $token');

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein Token. Bitte melden Sie sich an.')),
        );
        setState(() => _submitting = false);
        return;
      }

      // 2) build multipart request
      final request = http.MultipartRequest('POST', _endpointUri())
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields.addAll({
          'name'          :    _nameCtrl.text.trim(),
          'city'          :    _cityCtrl.text.trim(),
          'price'         :    _priceCtrl.text.trim(), // backend parses number
          'availableFrom' :    _dateCtrl.text.trim(),  // yyyy-MM-dd
          'description'   :    _descCtrl.text.trim(),
        });

      if (_image != null) {
        final mime = lookupMimeType(_image!.path) ?? 'image/jpeg';
        final parts = mime.split('/');
        request.files.add(
          await http.MultipartFile.fromPath(
            'imageUrl', // IMPORTANT: matches your backend & edit screen
            _image!.path,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      // 3) send
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      debugPrint('AddBike → Response ${response.statusCode}: ${response.body}');

      // 4) handle
      if (response.statusCode == 200 || response.statusCode == 201) {
        // (Optional) log returned imageUrl
        try {
          final json = response.body.isNotEmpty ? jsonDecode(response.body) : null;
          debugPrint('Created bike imageUrl: ${json?['imageUrl']}');
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fahrrad erfolgreich hinzugefügt')),
          );
          Navigator.pop(context, true); // tell caller to refresh
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehlgeschlagen: ${response.statusCode} ${response.reasonPhrase}\n${response.body}')),
        );
      }
    } catch (e) {
      debugPrint('AddBike → Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fahrrad hinzufügen'), backgroundColor: orange),
      body: AbsorbPointer(
        absorbing: _submitting,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: orange.withOpacity(.7)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _image == null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.black45),
                                    SizedBox(height: 8),
                                    Text('Foto hinzufügen'),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_image!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Fahrradname'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Fahrradname eingeben' : null,
                    ),
                    TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(labelText: 'Stadt'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Stadt eingeben' : null,
                    ),
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(labelText: 'Price pro Tag (€)'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Price eingeben';
                        final n = num.tryParse(v);
                        if (n == null || n <= 0) return 'Price must be > 0';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'verfügbar ab (yyyy-MM-dd)',
                        suffixIcon: Icon(Icons.date_range),
                      ),
                      onTap: _pickDate,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wähle das Datum' : null,
                    ),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(labelText: 'Beschreibung eingeben'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saveBike,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Speichern ', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_submitting) Container(color: Colors.black12),
          ],
        ),
      ),
    );
  }
}
