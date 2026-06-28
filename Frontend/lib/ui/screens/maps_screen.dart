// lib/ui/screens/maps_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});
  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  static const _fallback = LatLng(48.137154, 11.576124); // München
  static const _kAuthTokenKey = 'auth_token';

  GoogleMapController? _map;
  LatLng? _me;
  bool _loading = true;
  Set<Marker> _markers = {};
  final Map<String, LatLng> _geocodeCache = {}; // city -> LatLng

  // For the debug popup
  String? _lastApiUrl;
  int? _lastApiStatus;
  String? _lastApiBody;

  // ===== API helpers =====
  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    // Android emulator talks to host with 10.0.2.2
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }
  Uri _bikesUri() => Uri.parse('${_apiBase()}/api/bicycles');

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      await _initLocation();
      await _loadAndShowAllBikes();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /* ---------- Location ---------- */

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Maps: location service disabled');
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      debugPrint('Maps: location permission denied');
      return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _me = LatLng(pos.latitude, pos.longitude);
    debugPrint('Maps: my position = $_me');
  }

  /* ---------- Load bikes & show markers (ALL bikes) ---------- */

  Future<void> _loadAndShowAllBikes() async {
    _markers.clear();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kAuthTokenKey) ?? '';

    final url = _bikesUri();
    _lastApiUrl = url.toString();

    final res = await http.get(
      url,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _lastApiStatus = res.statusCode;
    _lastApiBody = res.body;

    debugPrint('Maps: GET $url → ${res.statusCode}');
    debugPrint('Maps: Body: ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bikes load failed (${res.statusCode}).')),
        );
      }
      // Center to me/fallback so user sees something
      if (_me != null) {
        _moveCamera(_me!, zoom: 12.5);
      } else {
        _moveCamera(_fallback, zoom: 11.5);
      }
      setState(() {});
      return;
    }

    final decoded = jsonDecode(res.body);
    final List list = decoded is List
        ? decoded
        : (decoded is Map ? (decoded['content'] ?? decoded['data'] ?? []) : []);

    debugPrint('Maps: bikes count = ${list.length}');

    // 1) Geocode unique, non-empty cities and cache them
    final cities = <String>{
      for (final raw in list)
        ((raw as Map)['city']?.toString() ?? '').trim()
    }..removeWhere((c) => c.isEmpty);

    for (final city in cities) {
      if (_geocodeCache.containsKey(city)) continue;
      try {
        final locs = await geo.locationFromAddress(city);
        if (locs.isNotEmpty) {
          _geocodeCache[city] = LatLng(locs.first.latitude, locs.first.longitude);
          debugPrint('Maps: geocoded "$city" -> ${_geocodeCache[city]}');
        }
      } catch (e) {
        debugPrint('Maps: geocode failed for "$city": $e');
      }
    }

    // 2) Build markers (jitter markers per city so they don’t overlap)
    const d = 0.0006; // ~60m
    final cityIndex = <String, int>{};
    LatLng? firstCenter;

    for (final raw in list) {
      final m = raw as Map<String, dynamic>;

      final name = (m['name'] ?? m['title'] ?? 'Bike').toString();
      final city = (m['city'] ?? '').toString().trim();
      final price = m['price']?.toString();
      final idStr = (m['id'] ?? '').toString();

      LatLng? center;
      if (city.isNotEmpty) {
        center = _geocodeCache[city];
      }
      center ??= _me ?? _fallback;

      final i = (cityIndex[city] ?? 0);
      cityIndex[city] = i + 1;

      final angle = (i * 33.0) * math.pi / 180.0;
      final pos = LatLng(center.latitude + d * math.sin(angle),
                         center.longitude + d * math.cos(angle));

      final snippetParts = <String>[
        if (city.isNotEmpty) city,
        if (price != null) '$price €/Tag',
        if ((m['date'] ?? '').toString().isNotEmpty) (m['date'] as Object).toString(),
      ];
      final snippet = snippetParts.join(' • ');

      _markers.add(
        Marker(
          markerId: MarkerId('bike_${idStr}_$i'),
          position: pos,
          infoWindow: InfoWindow(title: name, snippet: snippet),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );

      firstCenter ??= center;
    }

    // 3) Move camera to the first center (or me/fallback)
    if (firstCenter != null) {
      _moveCamera(firstCenter!, zoom: 12.5);
    } else if (_me != null) {
      _moveCamera(_me!, zoom: 12.5);
    } else {
      _moveCamera(_fallback, zoom: 11.5);
    }

    if (mounted) setState(() {});
  }

  Future<void> _moveCamera(LatLng target, {double zoom = 13}) async {
    if (_map == null) return;
    await _map!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  /* ---------- Drawer & nav ---------- */

  void _handleDrawerSelect(BuildContext context, AppDrawerKey key) {
    Navigator.of(context).maybePop();
    switch (key) {
      case AppDrawerKey.logout:  context.go('/login');   break;
      case AppDrawerKey.home:    context.go('/home');    break;
      case AppDrawerKey.maps:    context.go('/maps');    break;
      case AppDrawerKey.setting: context.go('/settings');break;
      case AppDrawerKey.privacy: context.go('/privacy'); break;
      case AppDrawerKey.police:  context.go('/police');  break;
      case AppDrawerKey.bikes:   context.go('/bikes');   break;
      case AppDrawerKey.myBikes: context.go('/my-bikes');break;
      case AppDrawerKey.ownerOrders:  context.go('/orders');  break;
      case AppDrawerKey.myRentals: context.go('/my-orders'); break;
    }
  }

  /* ---------- Debug popup ---------- */

  void _showLastApiDialog() {
    final url = _lastApiUrl ?? '(no request yet)';
    final status = _lastApiStatus?.toString() ?? '(n/a)';
    final body = _lastApiBody ?? '(empty)';

    String pretty = body;
    try {
      final obj = jsonDecode(body);
      pretty = const JsonEncoder.withIndent('  ').convert(obj);
    } catch (_) {}

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Last API response'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText('URL: $url'),
              const SizedBox(height: 6),
              SelectableText('Status: $status'),
              const Divider(),
              const Text('Body:'),
              const SizedBox(height: 6),
              SelectableText(pretty),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close', style: TextStyle(color: orange)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(onSelect: (k) => _handleDrawerSelect(context, k)),
      appBar: AppBar(
        title: const Text('Fahrrad Auf Map'),
        centerTitle: true,
        backgroundColor: orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _bootstrap,
          ),
          IconButton(
            tooltip: 'Show last API',
            icon: const Icon(Icons.bug_report),
            onPressed: _showLastApiDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) {
              _map = c;
              // First visual location when the map appears
              if (_me != null) {
                _moveCamera(_me!, zoom: 12.5);
              } else {
                _map!.moveCamera(CameraUpdate.newLatLngZoom(_fallback, 11.5));
              }
            },
            initialCameraPosition: CameraPosition(
              target: _me ?? _fallback,
              zoom: _me != null ? 12.5 : 11.5,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
          ),
          if (_loading)
            const Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(child: CircularProgressIndicator(color: orange)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: 2, // Maps tab
        onTap: (i) {
          switch (i) {
            case 0: context.go('/home');     break;
            case 1: context.go('/bikes');    break;
            case 2: context.go('/maps');     break;
            case 3: context.go('/settings'); break;
          }
        },
      ),
    );
  }
}
