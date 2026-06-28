// lib/ui/screens/my_bike_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/bike_card.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';

class MyBikeScreen extends StatefulWidget {
  const MyBikeScreen({super.key});

  @override
  State<MyBikeScreen> createState() => _MyBikeScreenState();
}

class _MyBikeScreenState extends State<MyBikeScreen> {
  final TextEditingController _search = TextEditingController();
  bool _loading = true;
  String? _error;

  String _token = '';
  List<Bicycle> _all = [];
  List<Bicycle> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadMyBikes();
    _search.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  Uri _myBikesUri() => Uri.parse('${_apiBase()}/api/bicycles/my');
  Uri _updateUri(String id) => Uri.parse('${_apiBase()}/api/bicycles/$id');

  Future<void> _loadMyBikes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token') ?? '';
      if (_token.isEmpty) {
        setState(() {
          _error = 'Nicht authentifiziert. Bitte melden Sie sich an.';
          _loading = false;
        });
        return;
      }

      final res = await http.get(
        _myBikesUri(),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final List list = (decoded is List)
            ? decoded
            : (decoded is Map ? (decoded['content'] ?? decoded['data'] ?? []) : []);

        final bikes = list
            .map((e) => Bicycle.fromJson(e as Map<String, dynamic>, _apiBase()))
            .toList()
            .cast<Bicycle>();

        setState(() {
          _all = bikes;
          _applyFilter();
          _loading = false;
        });
      } else {
        String msg = 'Laden fehlgeschlagen (${res.statusCode}).';
        try {
          final j = jsonDecode(res.body);
          if (j is Map && j['message'] != null) msg = j['message'].toString();
        } catch (_) {}
        setState(() {
          _error = msg;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Netzwerkfehler: $e';
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }
    setState(() {
      _filtered = _all.where((b) {
        final hay = [
          b.name,
          b.title,
          b.city,
          b.description,
          b.price?.toString(),
          b.date,
        ].whereType<String>().map((s) => s.toLowerCase()).join(' ');
        return hay.contains(q);
      }).toList();
    });
  }

  Future<void> _goToAddBike() async {
    final changed = await context.push('/bikes/add');
    if (changed == true && mounted) {
      await _loadMyBikes();
    }
  }

  Future<void> _openEdit(Bicycle bike) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _EditBikeSheet(
        bike: bike,
        updateUri: _updateUri(bike.id ?? ''),
        onUpdated: () => Navigator.pop(ctx, true),
      ),
    );

    if (changed == true && mounted) {
      await _loadMyBikes();
    }
  }

  Future<void> _confirmDelete(Bicycle bike) async {
    if (bike.id == null || bike.id!.isEmpty) return;

    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fahrrad löschen'),
        content: Text('Möchten Sie dieses Fahrrad wirklich löschen? "${bike.name ?? 'dieses Fahrrad'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (yes == true) {
      await _deleteBike(bike);
    }
  }

  Future<void> _deleteBike(Bicycle bike) async {
    final id = bike.id!;
    final prevAll = List<Bicycle>.from(_all);
    setState(() {
      _all.removeWhere((b) => b.id == id);
      _applyFilter();
    });

    try {
      final res = await http.delete(
        _updateUri(id),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fahrrad gelöscht')),
        );
      } else {
        if (mounted) {
          setState(() {
            _all = prevAll;
            _applyFilter();
          });
          String msg = 'Löschen fehlgeschlagen (${res.statusCode}).';
          try {
            final j = jsonDecode(res.body);
            if (j is Map && j['message'] != null) msg = j['message'].toString();
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _all = prevAll;
        _applyFilter();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  // ---------- Drawer navigation ----------
  void _handleDrawerSelect(AppDrawerKey key) {
    Navigator.of(context).maybePop();
    switch (key) {
      case AppDrawerKey.logout:
        context.go('/login');
        break;
      case AppDrawerKey.home:
        context.go('/home');
        break;
      case AppDrawerKey.maps:
        context.go('/maps');
        break;
      case AppDrawerKey.setting:
        context.go('/settings');
        break;
      case AppDrawerKey.privacy:
        context.go('/privacy');
        break;
      case AppDrawerKey.police:
        context.go('/police');
        break;
      case AppDrawerKey.bikes:
        context.go('/bikes');
        break;
      case AppDrawerKey.myBikes:
        context.go('/my-bikes');
        break;
      case AppDrawerKey.ownerOrders:
        context.go('/orders');
        break;
      case AppDrawerKey.myRentals:
        context.go('/my-orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    final content = _loading
        ? const Center(child: CircularProgressIndicator(color: orange))
        : _error != null
            ? _ErrorState(message: _error!, onRetry: _loadMyBikes)
            : list.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
                    color: orange,
                    onRefresh: _loadMyBikes,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final b = list[i];
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: BikeCard(
                                image: b.imageUrl ?? 'assets/images/bike.png',
                                title: b.name ?? b.title ?? 'Fahrrad',
                                location: b.city ?? '—',
                                date: b.date ?? '',
                                price: b.price != null
                                    ? '${b.price}€/Tag'
                                    : (b.priceText ?? ''),
                                onDelete: () => _confirmDelete(b),
                                // Token für geschützte Bilder mitschicken
                                networkHeaders: _token.isNotEmpty
                                    ? {'Authorization': 'Bearer $_token'}
                                    : null,
                              ),
                            ),

                            // Bearbeiten-Button
                            Positioned(
                              right: 6,
                              top: 30,
                              child: Material(
                                color: Colors.white,
                                shape: const CircleBorder(),
                                elevation: 2,
                                child: IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: orange),
                                  onPressed: () => _openEdit(b),
                                  tooltip: 'Bearbeiten',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );

    return Scaffold(
      drawer: AppDrawer(onSelect: _handleDrawerSelect),
      appBar: AppBar(
        title: const Text('Meine Fahrräder'),
        centerTitle: true,
        backgroundColor: orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Fahrrad hinzufügen',
            onPressed: _goToAddBike,
            icon: const Icon(Icons.add),
          ),
          IconButton(
            tooltip: 'Aktualisieren',
            onPressed: _loading ? null : _loadMyBikes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'In meinen Fahrrädern suchen…',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: orange, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: orange, width: 1.6),
                ),
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: content),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAddBike,
        backgroundColor: orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/bikes');
              break;
            case 2:
              context.go('/maps');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.pedal_bike, size: 96, color: Colors.black26),
            SizedBox(height: 12),
            Text('Noch keine Fahrräder.', style: TextStyle(color: Colors.black54, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: orange),
              child: const Text('Erneut versuchen', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet mit geschützter Bildvorschau + PUT /api/bicycles/{id}
class _EditBikeSheet extends StatefulWidget {
  final Bicycle bike;
  final VoidCallback onUpdated;
  final Uri updateUri;

  const _EditBikeSheet({
    required this.bike,
    required this.onUpdated,
    required this.updateUri,
  });

  @override
  State<_EditBikeSheet> createState() => _EditBikeSheetState();
}

class _EditBikeSheetState extends State<_EditBikeSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.bike.name ?? widget.bike.title ?? '');
  late final TextEditingController _cityCtrl =
      TextEditingController(text: widget.bike.city ?? '');
  late final TextEditingController _priceCtrl =
      TextEditingController(text: (widget.bike.price ?? '').toString());
  late final TextEditingController _dateCtrl =
      TextEditingController(text: widget.bike.date ?? '');
  late final TextEditingController _descCtrl =
      TextEditingController(text: widget.bike.description ?? '');

  bool _saving = false;
  XFile? _pickedImage;

  Future<void> _pickImage() async {
    final src = await showModalBottomSheet<ImageSource?>(
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
    if (src == null) return;
    final img = await ImagePicker().pickImage(source: src, imageQuality: 85);
    if (img != null) setState(() => _pickedImage = img);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_dateCtrl.text) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      _dateCtrl.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<String> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final token = await _readToken();
      if (token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein Token. Bitte melden Sie sich an.')),
        );
        return;
      }

      final authHeader = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

      if (_pickedImage == null) {
        // ✅ Kein neues Bild: JSON PUT
        final body = jsonEncode({
          'name': _nameCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          // WICHTIG: richtiger Feldname
          'availableFrom': _dateCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
        });

        final res = await http.put(
          widget.updateUri,
          headers: {...authHeader, 'Content-Type': 'application/json'},
          body: body,
        );

        if (res.statusCode >= 200 && res.statusCode < 300) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fahrrad aktualisiert')),
          );
          widget.onUpdated();
        } else {
          String msg = 'Aktualisierung fehlgeschlagen (${res.statusCode}).';
          try {
            final j = jsonDecode(res.body);
            if (j is Map && j['message'] != null) msg = j['message'].toString();
          } catch (_) {}
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
        return;
      }

      // ✅ Mit neuem Bild: Multipart PUT
      final req = http.MultipartRequest('PUT', widget.updateUri)
        ..headers.addAll(authHeader)
        ..fields.addAll({
          'name': _nameCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'availableFrom': _dateCtrl.text.trim(), // <— richtiges Feld
          'description': _descCtrl.text.trim(),
        });

      final mime = lookupMimeType(_pickedImage!.path) ?? 'image/jpeg';
      final parts = mime.split('/');
      req.files.add(await http.MultipartFile.fromPath(
        // Falls Backend 'image' erwartet, hier 'image' eintragen
        'imageUrl',
        _pickedImage!.path,
        contentType: MediaType(parts[0], parts[1]),
      ));

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fahrrad aktualisiert')),
        );
        widget.onUpdated();
      } else {
        String msg = 'Aktualisierung fehlgeschlagen (${res.statusCode}).';
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
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
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

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return FutureBuilder<String>(
      future: _readToken(),
      builder: (context, snap) {
        final token = snap.data ?? '';

        final currentImage = _pickedImage != null
            ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
            : (widget.bike.imageUrl != null
                ? Image.network(
                    widget.bike.imageUrl!,
                    fit: BoxFit.cover,
                    headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : null,
                    errorBuilder: (_, __, ___) =>
                        Image.asset('assets/images/bike.png', fit: BoxFit.cover),
                  )
                : Image.asset('assets/images/bike.png', fit: BoxFit.cover));

        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: SafeArea(
            top: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text('Fahrrad bearbeiten #${widget.bike.id ?? ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),

                      SizedBox(
                        height: 150,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: currentImage,
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.photo_camera),
                                label: const Text('Bild ändern'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: _saving ? null : _pickImage,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _dec('Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Erforderlich' : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _cityCtrl,
                        decoration: _dec('Stadt'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Erforderlich' : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _dec('Preis'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Erforderlich';
                          final n = num.tryParse(v);
                          if (n == null || n <= 0) return 'Ungültiger Preis';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: _dec('Datum (yyyy-MM-dd)',
                            suffix: IconButton(
                              icon: const Icon(Icons.date_range, color: orange),
                              onPressed: _pickDate,
                            )),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Erforderlich' : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: _dec('Beschreibung'),
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          onPressed: _saving ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Speichern', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Model & URL-Resolver
class Bicycle {
  final String? id;
  final String? name;
  final String? title;
  final String? city;
  final num? price;
  final String? priceText;
  final String? date; // kann availableFrom/createdAt sein
  final String? description;
  final String? imageUrl;

  Bicycle({
    this.id,
    this.name,
    this.title,
    this.city,
    this.price,
    this.priceText,
    this.date,
    this.description,
    this.imageUrl,
  });

  static String? _resolveUrl(String? path, String base) {
    if (path == null) return null;
    final p = path.trim();
    if (p.isEmpty) return null;

    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return '$base$p';
    return '$base/uploads/$p';
  }

  factory Bicycle.fromJson(Map<String, dynamic> j, String base) {
    return Bicycle(
      id: (j['id'] ?? j['_id'] ?? '').toString(),
      name: j['name']?.toString(),
      title: j['title']?.toString(),
      city: j['city']?.toString(),
      price: j['price'] is num ? j['price'] as num : num.tryParse(j['price']?.toString() ?? ''),
      priceText: j['priceText']?.toString(),
      date: j['date']?.toString() ??
          j['availableFrom']?.toString() ??
          j['createdAt']?.toString(),
      description: j['description']?.toString(),
      imageUrl: _resolveUrl(j['imageUrl']?.toString() ?? j['image']?.toString(), base),
    );
  }
}