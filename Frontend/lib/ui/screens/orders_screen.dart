import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';
import 'package:sharecycleapp/ui/screens/chat_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  static const _kAuthTokenKey = 'auth_token';

  // Label (DE) + Code (API)
  static const List<_StatusTab> _statusTabs = [
    _StatusTab(label: 'Alle', code: 'ALL'),
    _StatusTab(label: 'Ausstehend', code: 'PENDING'),
    _StatusTab(label: 'Genehmigt', code: 'APPROVED'),
    _StatusTab(label: 'Abgelehnt', code: 'REJECTED'),
    _StatusTab(label: 'Abgeschlossen', code: 'COMPLETED'),
    _StatusTab(label: 'Storniert', code: 'CANCELED'),
  ];

  late final TabController _tabController;
  bool _loading = true;
  String? _error;
  String _token = '';
  List<OrderItem> _items = [];
  String _currentStatusCode = 'ALL';
  String? _currentUserId;

  // ---------- API helpers ----------
  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  Uri _ownerOrdersUri() => Uri.parse('${_apiBase()}/api/orders/for-owner');
  Uri _approveOrderUri(int orderId) => Uri.parse('${_apiBase()}/api/orders/$orderId/approve');
  Uri _rejectOrderUri(int orderId) => Uri.parse('${_apiBase()}/api/orders/$orderId/reject');

  // --- Anzeige-Übersetzung für Status ---
  String _deStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'ausstehend';
      case 'APPROVED':
        return 'genehmigt';
      case 'REJECTED':
        return 'abgelehnt';
      case 'CANCELLED':
      case 'CANCELED':
        return 'storniert';
      case 'COMPLETED':
        return 'abgeschlossen';
      default:
        return status.toLowerCase();
    }
  }

  Future<void> _handleAction(String action, int orderId) async {
    if (action == 'chat') {
      _navigateToChat(orderId);
      return;
    }

    final success = await _updateOrderStatus(
      orderId,
      action,
    );

    if (success && mounted) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve'
                ? 'Bestellung wurde genehmigt.'
                : 'Bestellung wurde abgelehnt.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<bool> _updateOrderStatus(int orderId, String action) async {
    try {
      final uri = action == 'approve' ? _approveOrderUri(orderId) : _rejectOrderUri(orderId);

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        String errorMessage = 'Bestellung konnte nicht ${action == "approve" ? "genehmigt" : "abgelehnt"} werden. Bitte erneut versuchen.';
        try {
          final responseBody = json.decode(response.body);
          if (responseBody is Map && responseBody.containsKey('message')) {
            errorMessage = responseBody['message'] ?? errorMessage;
          }
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('SocketException')
                ? 'Netzwerkfehler. Bitte Verbindung prüfen.'
                : 'Es ist ein Fehler aufgetreten: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
      initialIndex: 0,
    )..addListener(_handleTabChange);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentStatusCode = _statusTabs[_tabController.index].code;
      });
    }
  }

  List<OrderItem> _getFilteredItems(String statusCode) {
    if (statusCode == 'ALL') return _items;
    return _items.where((item) => item.orderStatus == statusCode).toList();
  }

  void _navigateToChat(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final order = _items.firstWhere((item) => item.orderId == orderId);
      prefs.setString("owner_id", order.owner['id'].toString());
      prefs.setString("renter_id", order.renter['id'].toString());
      final otherUser = order.renter['id'].toString() == _currentUserId
          ? order.owner
          : order.renter;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            otherUserName: otherUser['name'] ?? 'Benutzer',
            otherUserImageUrl: otherUser['imageUrl'],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat konnte nicht gestartet werden. Bitte erneut versuchen.')),
        );
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_kAuthTokenKey) ?? '';
      if (_token.isEmpty) {
        setState(() {
          _error = 'Nicht authentifiziert. Bitte melden Sie sich an.';
          _loading = false;
        });
        return;
      }

      final res = await http.get(
        _ownerOrdersUri(),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        final List data =
            decoded is List ? decoded : (decoded['data'] ?? decoded['content'] ?? []);
        final base = _apiBase();

        final items =
            data.map((e) => OrderItem.fromJson(e as Map<String, dynamic>, base)).toList();

        setState(() {
          _items = items.reversed.toList();
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
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildTabContent(String statusCode) {
      final displayItems = _getFilteredItems(statusCode);

      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Fehler: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        );
      }

      if (displayItems.isEmpty) {
        final label = _statusTabs[_tabController.index].label;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Keine ${label == 'Alle' ? '' : '$label-'}Bestellungen gefunden',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            return _OrderCard(
              item: displayItems[index],
              authToken: _token,
              statusText: _deStatus(displayItems[index].orderStatus),
              onAction: (action) => _handleAction(action, displayItems[index].orderId),
            );
          },
        ),
      );
    }

    return Scaffold(
      drawer: AppDrawer(onSelect: _handleDrawerSelect),

      appBar: AppBar(
        title: const Text('Bestellungen'),
        centerTitle: true,
        backgroundColor: orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _statusTabs.map((s) => Tab(text: s.label)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            tooltip: 'Aktualisieren',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: TabBarView(
        controller: _tabController,
        children: _statusTabs.map((s) => _buildTabContent(s.code)).toList(),
      ),

      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: 0,
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

/* ---------- Helper ---------- */

class _StatusTab {
  final String label; // German display
  final String code;  // API code
  const _StatusTab({required this.label, required this.code});
}

/* ---------- Model ---------- */

class OrderItem {
  final int orderId;
  final String bikeName;
  final String dateFrom;
  final String dateTo;
  final int rentalDays;
  final num totalPrice;
  final int? bicycleId;
  final String? bikeImageUrlResolved;
  final Map<String, dynamic> renter;
  final Map<String, dynamic> owner;
  final String orderStatus;

  String get renterName => renter['name']?.toString() ?? 'Unbekannt';
  String get renterEmail => renter['email']?.toString() ?? '';
  String get ownerName => owner['name']?.toString() ?? 'Vermieter';
  String? get bikeImageUrl => bikeImageUrlResolved;

  OrderItem({
    required this.orderId,
    required this.bikeName,
    required this.dateFrom,
    required this.dateTo,
    required this.rentalDays,
    required this.totalPrice,
    required this.renter,
    required this.owner,
    required this.orderStatus,
    this.bicycleId,
    this.bikeImageUrlResolved,
  });

  static String? _resolveUrl(String? path, String base) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$base$path';
    return '$base/uploads/$path';
  }

  factory OrderItem.fromJson(Map<String, dynamic> json, String base) {
    return OrderItem(
      orderId: int.tryParse('${json['orderId'] ?? json['id'] ?? 0}') ?? 0,
      bikeName: (json['bikeName'] ?? 'Unbekanntes Fahrrad').toString(),
      dateFrom: (json['dateFrom'] ?? '').toString(),
      dateTo: (json['dateTo'] ?? '').toString(),
      rentalDays: (json['rentalDays'] is int) ? json['rentalDays'] : 0,
      totalPrice: (json['totalPrice'] is num)
          ? json['totalPrice'] as num
          : num.tryParse('${json['totalPrice'] ?? 0}') ?? 0,
      renter: (json['renter'] is Map)
          ? Map<String, dynamic>.from(json['renter'])
          : <String, dynamic>{},
      owner: (json['owner'] is Map)
          ? Map<String, dynamic>.from(json['owner'])
          : <String, dynamic>{},
      orderStatus: (json['orderStatus'] ?? 'PENDING').toString().toUpperCase(),
      bicycleId: json['bicycleId'] == null ? null : int.tryParse('${json['bicycleId']}'),
      bikeImageUrlResolved: _resolveUrl(json['bikeImageUrl']?.toString(), base),
    );
  }
}

/* ---------- UI widgets ---------- */

class _OrderCard extends StatelessWidget {
  final OrderItem item;
  final String authToken;
  final String statusText; // German display
  final Future<void> Function(String action) onAction;

  const _OrderCard({
    required this.item,
    required this.authToken,
    required this.statusText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with bike image and details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bike image or placeholder
                if (item.bikeImageUrlResolved != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.bikeImageUrlResolved!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      headers: authToken.isNotEmpty ? {'Authorization': 'Bearer $authToken'} : null,
                      errorBuilder: (_, __, ___) => _fallbackIcon(),
                    ),
                  )
                else
                  _fallbackIcon(),

                const SizedBox(width: 12),

                // Bike and order details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.bikeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bestellung #${item.orderId} • ${statusText}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(item.orderStatus),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        Icons.calendar_today_outlined,
                        '${item.dateFrom} - ${item.dateTo} (${item.rentalDays} ${item.rentalDays == 1 ? 'Tag' : 'Tage'})',
                      ),
                      const SizedBox(height: 2),
                      _buildDetailRow(
                        Icons.person_outline,
                        item.renterName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Genehmigen',
                  color: Colors.green,
                  onPressed: () => onAction('approve'),
                ),
                _buildActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Ablehnen',
                  color: Colors.red,
                  onPressed: () => onAction('reject'),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  color: orange,
                  onPressed: () => onAction('chat'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: orange.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: orange.withOpacity(.15)),
        ),
        child: Icon(Icons.pedal_bike, size: 32, color: orange.withOpacity(0.7)),
      );

  Widget _buildDetailRow(IconData icon, String text, {bool isEmail = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1.5),
          child: Icon(icon, size: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              overflow: TextOverflow.ellipsis,
              fontSize: 13,
              color: isEmail ? Colors.blue.shade700 : Colors.grey.shade700,
              fontWeight: isEmail ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
