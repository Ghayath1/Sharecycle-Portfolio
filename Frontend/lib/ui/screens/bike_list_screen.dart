// Loads bikes, shows Booking dialog, and POSTs /api/orders

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/bike_card_booking.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';
import 'package:sharecycleapp/viewmodel/payment_view_model.dart';
import 'package:sharecycleapp/booking_models.dart';

class BikeListScreen extends StatefulWidget {
  const BikeListScreen({super.key});

  @override
  State<BikeListScreen> createState() => _BikeListScreenState();
}

class _BikeListScreenState extends State<BikeListScreen> {
  static const _kAuthTokenKey = 'auth_token';

  final TextEditingController _search = TextEditingController();

  bool _loading = true;
  String? _error;
  String _token = '';

  List<Bicycle> _all = [];
  List<Bicycle> _filtered = [];

  @override
  void initState() {
    super.initState();
    _search.addListener(_applyFilter);
    _loadBikes();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ===== API helpers =====
  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  Uri _listUri() => Uri.parse('${_apiBase()}/api/bicycles');

  Future<void> _loadBikes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_kAuthTokenKey) ?? '';

      final res = await http.get(
        _listUri(),
        headers: {
          if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final List list = decoded is List
            ? decoded
            : (decoded is Map ? (decoded['content'] ?? decoded['data'] ?? []) : []);

        final bikes = list
            .map((e) => Bicycle.fromJson(e as Map<String, dynamic>, _apiBase()))
            .toList();

        setState(() {
          _all = bikes;
          _applyFilter();
          _loading = false;
        });
      } else {
        String msg = 'Laden fehlgeschlagen(${res.statusCode}).';
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

  // ===== Booking flow =====
  Future<void> _book(Bicycle b) async {
    debugPrint('🚴 BikeListScreen - Starting booking process for bike: ${b.id} - ${b.name}');

    final dates = await showDialog<_BookingRange>(
      context: context,
      builder: (_) => const _BookingDialog(),
    );

    if (dates == null) {
      debugPrint('🚴 BikeListScreen - Booking cancelled by user (no dates selected)');
      return;
    }

    debugPrint('🚴 BikeListScreen - Dates selected - From: ${dates.from}, To: ${dates.to}');

    context.push(
      '/booking-details',
      extra: BookingDetails(
        bike: b,
        from: dates.from,
        to: dates.to,
      ),
    );
  }

  // ===== Drawer & nav =====
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

  void _goToAddBike() => context.push('/bikes/add');

  // Debug helper methods
  Color _getPaymentStateColor(PaymentState state) {
    switch (state) {
      case PaymentState.idle:
        return Colors.grey;
      case PaymentState.creatingOrder:
        return Colors.blue;
      case PaymentState.awaitingApproval:
        return Colors.orange;
      case PaymentState.authorizing:
        return Colors.purple;
      case PaymentState.completed:
        return Colors.green;
      case PaymentState.failed:
        return Colors.red;
      case PaymentState.cancelled:
        return Colors.yellow;
    }
  }

  String _getPaymentStateText(PaymentState state) {
    switch (state) {
      case PaymentState.idle:
        return 'IDL';
      case PaymentState.creatingOrder:
        return 'ORD';
      case PaymentState.awaitingApproval:
        return 'PAY';
      case PaymentState.authorizing:
        return 'ATH';
      case PaymentState.completed:
        return 'OK';
      case PaymentState.failed:
        return 'ERR';
      case PaymentState.cancelled:
        return 'CAN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentViewModel = context.watch<PaymentViewModel>();

    Widget content;

    if (_loading) {
      content = const Center(child: CircularProgressIndicator(color: orange));
    } else if (_error != null) {
      content = _ErrorState(message: _error!, onRetry: _loadBikes);
    } else if (_filtered.isEmpty) {
      content = _EmptyState(onAdd: _goToAddBike);
    } else {
      content = RefreshIndicator(
        color: orange,
        onRefresh: _loadBikes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Suchen',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: orange, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: orange, width: 1.6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 220, // 🚀 Reduced from 245 by 10px
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (context, i) {
                    final b = _filtered[i];
                    return BikeCardBooking(
                      image: b.imageUrl ?? 'assets/images/bike.png',
                      title: b.name ?? b.title ?? 'Fahrrad',
                      location: b.city ?? '—',
                      date: b.date ?? '',
                      price: b.price != null ? '${b.price}€/Tag' : (b.priceText ?? ''),
                      onBook: () => _book(b),
                      networkHeaders: _token.isNotEmpty ? {'Authorization': 'Bearer $_token'} : null,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AppDrawer(onSelect: _handleDrawerSelect),
      appBar: AppBar(
        title: const Text('Fahrrad'),
        centerTitle: true,
        backgroundColor: orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Debug indicator for payment state
          Container(
            constraints: const BoxConstraints(maxWidth: 35, minWidth: 25),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: _getPaymentStateColor(paymentViewModel.state),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getPaymentStateText(paymentViewModel.state),
              style: const TextStyle(
                fontSize: 7,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          IconButton(
            tooltip: 'Aktualisieren',
            onPressed: _loading ? null : _loadBikes,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _goToAddBike,
            icon: const Icon(Icons.add),
            tooltip: 'Fahrrad hinzufügen',
          ),
        ],
      ),
      body: SafeArea(
        child: content,
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

// ===== Booking dialog =====

class _BookingRange {
  final DateTime from;
  final DateTime to;
  const _BookingRange(this.from, this.to);
}

class _BookingDialog extends StatefulWidget {
  const _BookingDialog();

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  DateTime? _from;
  DateTime? _to;

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _from = picked;
        if (_to == null || !_to!.isAfter(_from!)) {
          _to = _from!.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _pickTo() async {
    if (_from == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _to ?? _from!.add(const Duration(days: 1)),
      firstDate: _from!.add(const Duration(days: 1)),
      lastDate: DateTime(_from!.year + 2),
    );
    if (picked != null) setState(() => _to = picked);
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Datum auswählen' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buchungsdaten auswählen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('von: ${_fmt(_from)}'),
            trailing: const Icon(Icons.date_range),
            onTap: _pickFrom,
          ),
          ListTile(
            title: Text('bis: ${_fmt(_to)}'),
            trailing: const Icon(Icons.date_range),
            onTap: _pickTo,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        ElevatedButton(
          onPressed: (_from != null && _to != null && _to!.isAfter(_from!))
              ? () => Navigator.pop(context, _BookingRange(_from!, _to!))
              : null,
          style: ElevatedButton.styleFrom(backgroundColor: orange),
          child: const Text('Buchen'),
        ),
      ],
    );
  }
}

// ===== Empty/Error helpers =====

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pedal_bike, size: 96, color: Colors.black26),
            const SizedBox(height: 12),
            const Text(
              "Keine Fahrräder.\nBitte eines hinzufügen.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Jetzt hinzufügen!', style: TextStyle(color: Colors.white)),
            ),
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

// ===== Model =====

class Bicycle {
  final String? id;
  final String? name;
  final String? title;
  final String? city;
  final num? price;
  final String? priceText;
  final String? date;
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
