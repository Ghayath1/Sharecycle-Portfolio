// lib/ui/screens/home_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';
import 'package:sharecycleapp/ui/components/header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tabs: 0=Bikes, 1=Home, 2=Maps, 3=Profile
  int _currentIndex = 1;
  final _searchCtrl = TextEditingController();

  // Header-Daten
  String? _userName;
  String? _imageUrlResolved; // absolut aufgelöst (mit API-Base)
  String _authToken = '';

  // Neueste Bestellungen (Owner)
  List<_OrderMini> _latest = [];
  bool _ordersLoading = false;
  String? _ordersError;

  static const _kUserJsonKey = 'auth_user_json';
  static const _kAuthTokenKey = 'auth_token';

  @override
  void initState() {
    super.initState();
    _loadUserFromStorage();
    _loadLatestOrders();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------------- Helpers ----------------
  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  String? _resolveUrl(String? path) {
    if (path == null) return null;
    final p = path.trim();
    if (p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return '${_apiBase()}$p';
    return '${_apiBase()}/uploads/$p';
  }

  Uri _ownerOrdersUri() => Uri.parse('${_apiBase()}/api/orders/for-owner');

  // ---------------- Header laden ----------------
  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_kAuthTokenKey) ?? '';

      final raw = prefs.getString(_kUserJsonKey);
      if (raw == null) return;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final apiName = (map['name'] as String?)?.trim();
      final email = (map['email'] as String?)?.trim();
      final avatar = (map['avatar'] ?? map['imageUrl'])?.toString();

      setState(() {
        _userName = (apiName?.isNotEmpty == true) ? apiName : (email ?? 'User');
        _imageUrlResolved = _resolveUrl(avatar);
      });
    } catch (_) {
      // Ignorieren; Header zeigt Initialen
    }
  }

  // ---------------- Neueste Bestellungen laden ----------------
  Future<void> _loadLatestOrders() async {
    setState(() {
      _ordersLoading = true;
      _ordersError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(_kAuthTokenKey) ?? '';
      if (_authToken.isEmpty) {
        setState(() {
          _ordersLoading = false;
          _ordersError = 'Nicht authentifiziert. Bitte melden Sie sich an.';
        });
        return;
      }

      final res = await http.get(
        _ownerOrdersUri(),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final List data =
            decoded is List ? decoded : (decoded['data'] ?? decoded['content'] ?? []);

        final items = data
            .map((e) => _OrderMini.fromJson(e as Map<String, dynamic>,
                resolver: _resolveUrl))
            .toList();

        // optional nach ID absteigend
        items.sort((a, b) => b.orderId.compareTo(a.orderId));

        setState(() {
          _latest = items.take(3).toList();
          _ordersLoading = false;
        });
      } else {
        String msg = 'Laden fehlgeschlagen (${res.statusCode}).';
        try {
          final j = jsonDecode(res.body);
          if (j is Map && j['message'] != null) msg = j['message'].toString();
        } catch (_) {}
        setState(() {
          _ordersError = msg;
          _ordersLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _ordersError = 'Netzwerkfehler: $e';
        _ordersLoading = false;
      });
    }
  }

  // ---------------- Drawer ----------------
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
        break;
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(onSelect: _handleDrawerSelect, version: 'v 1.0'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            // Header inkl. Auth-Header für geschützte Bilder
            HeaderComponent(
              name: _userName,
              imageUrl: _imageUrlResolved,
              networkHeaders: _authToken.isNotEmpty
                  ? {'Authorization': 'Bearer $_authToken'}
                  : null,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Suchen',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _BannerCard(
                imagePath: 'assets/images/bike.png',
                title1: 'Sei sportlich',
                title2: 'Umwelt schützen',
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Neueste Bestellungen',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/orders'),
                    child: const Text('Alle anzeigen'),
                  ),
                ],
              ),
            ),

            if (_ordersLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(color: orange)),
              )
            else if (_ordersError != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _OrdersInlineError(
                  message: _ordersError!,
                  onRetry: _loadLatestOrders,
                ),
              )
            else if (_latest.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Noch keine Buchungen.',
                    style: TextStyle(color: Colors.black54)),
              )
            else
              ..._latest.map(
                (o) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: _MiniOrderCard(order: o, authToken: _authToken),
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          switch (i) {
            case 0:
              context.go('/bikes');
              break;
            case 1:
              context.go('/home');
              break;
            case 2:
              context.go('/maps');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}

/* ---------------- Models & Widgets ---------------- */

class _OrderMini {
  final int orderId;
  final String bikeName;
  final int rentalDays;
  final num totalPrice;
  final String dateFrom;
  final String dateTo;
  final String? imageUrl;

  _OrderMini({
    required this.orderId,
    required this.bikeName,
    required this.rentalDays,
    required this.totalPrice,
    required this.dateFrom,
    required this.dateTo,
    this.imageUrl,
  });

  factory _OrderMini.fromJson(
    Map<String, dynamic> j, {
    required String? Function(String?) resolver,
  }) {
    String? img = (j['bikeImageUrl'] ??
            j['imageUrl'] ??
            (j['bike'] is Map ? (j['bike']['imageUrl']) : null))
        ?.toString();
    img = resolver(img);

    return _OrderMini(
      orderId: int.tryParse('${j['orderId'] ?? j['id'] ?? 0}') ?? 0,
      bikeName: (j['bikeName'] ?? j['bike'] ?? 'Fahrrad').toString(),
      rentalDays:
          int.tryParse('${j['rentalDays'] ?? j['durationDays'] ?? 0}') ?? 0,
      totalPrice: j['totalPrice'] is num
          ? j['totalPrice'] as num
          : num.tryParse('${j['totalPrice'] ?? j['amount'] ?? 0}') ?? 0,
      dateFrom: (j['dateFrom'] ?? j['from'] ?? '').toString(),
      dateTo: (j['dateTo'] ?? j['to'] ?? '').toString(),
      imageUrl: img,
    );
  }
}

class _MiniOrderCard extends StatelessWidget {
  final _OrderMini order;
  final String authToken;
  const _MiniOrderCard({required this.order, required this.authToken});

  @override
  Widget build(BuildContext context) {
    final daysLabel = order.rentalDays == 1 ? 'Tag' : 'Tage';

    Widget avatar;
    if (order.imageUrl != null && order.imageUrl!.isNotEmpty) {
      avatar = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          order.imageUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          headers:
              authToken.isNotEmpty ? {'Authorization': 'Bearer $authToken'} : null,
          errorBuilder: (_, __, ___) => const CircleAvatar(
              radius: 18, child: Icon(Icons.pedal_bike, color: Colors.white)),
        ),
      );
    } else {
      avatar = const CircleAvatar(
          radius: 18, child: Icon(Icons.pedal_bike, color: Colors.white));
    }

    return Container(
      decoration: BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.bikeName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                Text('${order.rentalDays} $daysLabel',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 12)),
                Text('${order.dateFrom} → ${order.dateTo}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.9), fontSize: 11)),
              ],
            ),
          ),
          Text('${order.totalPrice.toStringAsFixed(2)} €',
              style: const TextStyle(
                  color: Color(0xFFFFE066), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _OrdersInlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _OrdersInlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final String imagePath;
  final String title1;
  final String title2;

  const _BannerCard({
    required this.imagePath,
    required this.title1,
    required this.title2,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(imagePath, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                children: [
                  TextSpan(text: '$title1  '),
                  WidgetSpan(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: orange, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Und',
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  const TextSpan(text: '  '),
                  TextSpan(text: title2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
