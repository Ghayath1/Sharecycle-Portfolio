import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';
import 'package:sharecycleapp/ui/screens/chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  static const _kAuthTokenKey = 'auth_token';
  bool _loading = true;
  String? _error;
  String _token = '';
  List<OrderItem> _orders = [];

  // --- API helpers ---
  String _apiBase() {
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  Uri _myOrdersUri() => Uri.parse('${_apiBase()}/api/orders/my');
  Uri _cancelOrderUri(int orderId) => Uri.parse('${_apiBase()}/api/orders/$orderId');

  static String? _resolveUrl(String? path, String base) {
    if (path == null) return null;
    final p = path.trim();
    if (p.isEmpty) return null;
    if (p.startsWith('http://') || p.startsWith('https://')) return p;
    if (p.startsWith('/')) return '$base$p';
    return '$base/uploads/$p';
  }

  @override
  void initState() {
    super.initState();
    _loadTokenAndOrders();
  }

  Future<void> _loadTokenAndOrders() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString(_kAuthTokenKey) ?? '';
    });
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        _myOrdersUri(),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final base = _apiBase();
        // Debug-Ausgabe der ersten Antwort für Feldnamenkontrolle
        if (data.isNotEmpty) {
          debugPrint('📦 Beispiel Order JSON: ${jsonEncode(data.first)}');
        }

        setState(() {
          _orders = data.map((item) {
            final o = OrderItem.fromJson(item as Map<String, dynamic>);
            // Bild-URL robust auflösen (relativ → absolut)
            return o.copyWith(bikeImageUrl: _resolveUrl(o.bikeImageUrl, base));
          }).toList();
        });
      } else {
        throw Exception('Fehler beim Laden der Bestellungen');
      }
    } catch (e) {
      setState(() {
        _error = 'Bestellungen konnten nicht geladen werden. Bitte erneut versuchen.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<bool> _cancelOrder(int orderId) async {
    try {
      final response = await http.delete(
        _cancelOrderUri(orderId),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bestellung wurde erfolgreich storniert.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        throw Exception('Stornierung fehlgeschlagen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bestellung konnte nicht storniert werden. Bitte erneut versuchen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  // Anzeige-Übersetzung für Status
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Bestellungen'),
        backgroundColor: orange,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        onSelect: (key) {
          Navigator.pop(context);
          switch (key) {
            case AppDrawerKey.myRentals:
              break;
            case AppDrawerKey.ownerOrders:
              GoRouter.of(context).go('/orders');
              break;
            case AppDrawerKey.home:
              GoRouter.of(context).go('/home');
              break;
            case AppDrawerKey.maps:
              GoRouter.of(context).go('/maps');
              break;
            case AppDrawerKey.setting:
              GoRouter.of(context).go('/settings');
              break;
            case AppDrawerKey.privacy:
              GoRouter.of(context).go('/privacy');
              break;
            case AppDrawerKey.police:
              GoRouter.of(context).go('/police');
              break;
            case AppDrawerKey.bikes:
              GoRouter.of(context).go('/bikes');
              break;
            case AppDrawerKey.myBikes:
              GoRouter.of(context).go('/my-bikes');
              break;
            case AppDrawerKey.logout:
              GoRouter.of(context).go('/login');
              break;
          }
        },
      ),
      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: 1,
        onTap: (_) {},
      ),
      body: _buildBody(),
    );
  }

  // Chat öffnen
  void _navigateToChat(OrderItem order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('current_user_id');
      prefs.setString("owner_id", order.owner.id.toString());
      prefs.setString("renter_id", order.renter.id.toString());

      if (currentUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Benutzer nicht angemeldet.')),
          );
        }
        return;
      }

      final isRenter = currentUserId == order.renter.id.toString();
      final otherUser = isRenter ? order.owner : order.renter;

      await prefs.setString('owner_id', order.owner.id.toString());
      await prefs.setString('renter_id', order.renter.id.toString());

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            otherUserName: order.owner.name,
            otherUserImageUrl: otherUser.imageUrl,
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

  Widget _buildBody() {
    if (_loading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: orange));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(backgroundColor: orange),
              child: const Text('Erneut versuchen', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Keine Bestellungen gefunden', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(backgroundColor: orange),
              child: const Text('Aktualisieren', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _OrderCard(
          order: _orders[index],
          statusText: _deStatus(_orders[index].orderStatus),
          apiBase: _apiBase(),
          authToken: _token,
          onCancel: _orders[index].orderStatus.toUpperCase() == 'PENDING'
              ? () async {
                  final success = await _cancelOrder(_orders[index].orderId);
                  if (success && mounted) {
                    await _loadOrders();
                  }
                }
              : null,
          onChat: () => _navigateToChat(_orders[index]),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final String statusText; // Deutsch
  final String apiBase;
  final String authToken;
  final VoidCallback? onCancel;
  final VoidCallback? onChat;

  const _OrderCard({
    required this.order,
    required this.statusText,
    required this.apiBase,
    required this.authToken,
    this.onCancel,
    this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.orderStatus);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Bild (mit eigenem GET inkl. Auth-Header)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: _buildBikeImage(order.bikeImageUrl, apiBase, authToken),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.bikeName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.rentalDays} ${order.rentalDays == 1 ? 'Tag' : 'Tage'} • ${order.totalPrice}€',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order.dateFrom} → ${order.dateTo}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Weitere Infos
            _buildDetailRow(Icons.confirmation_number, 'Bestellung #${order.orderId}'),
            _buildDetailRow(Icons.calendar_today, 'Bestellt am ${order.orderDate}'),
            const SizedBox(height: 12),

            Row(
              children: [
                if (onCancel != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Bestellung stornieren'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: onChat,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      side: BorderSide(color: orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 16),
                        SizedBox(width: 4),
                        Text('Chat'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bild mit http.get laden (inkl. Authorization) und als Memory anzeigen
  Widget _buildBikeImage(String? resolvedUrl, String base, String token) {
    final String? url = _MyOrdersScreenState._resolveUrl(resolvedUrl, base);

    if (url == null || url.isEmpty) {
      debugPrint('🖼️ BikeImage: keine URL vorhanden');
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.pedal_bike, size: 40, color: Colors.grey),
      );
    }

    debugPrint('🖼️ BikeImage: lade $url');

    return FutureBuilder<http.Response>(
      future: http.get(Uri.parse(url), headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Accept': 'image/*',
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[100],
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('🖼️ BikeImage: Fehler beim Laden: ${snapshot.error}');
          return Container(
            color: orange.withOpacity(.08),
            child: Icon(Icons.pedal_bike, size: 40, color: orange.withOpacity(.7)),
          );
        }

        final res = snapshot.data!;
        debugPrint('🖼️ BikeImage: HTTP ${res.statusCode} für $url');

        if (res.statusCode >= 200 && res.statusCode < 300 && res.bodyBytes.isNotEmpty) {
          return Image.memory(res.bodyBytes, fit: BoxFit.cover);
        }

        return Container(
          color: orange.withOpacity(.08),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 28, color: orange.withOpacity(.8)),
              const SizedBox(height: 4),
              Text('Kein Bild', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.grey;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

// --- Modelle ---
class OrderUser {
  final int id;
  final String name;
  final String email;
  final String? birthDate;
  final String? iphoneNumber;
  final String? role;
  final String? city;
  final String? imageUrl;
  final int age;
  final String? idCardNumber;
  final String? idCardImageUrl;

  OrderUser({
    required this.id,
    required this.name,
    required this.email,
    this.birthDate,
    this.iphoneNumber,
    this.role,
    this.city,
    this.imageUrl,
    required this.age,
    this.idCardNumber,
    this.idCardImageUrl,
  });

  factory OrderUser.fromJson(Map<String, dynamic> json) {
    return OrderUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      birthDate: json['birthDate'] as String?,
      iphoneNumber: json['iphoneNumber'] as String?,
      role: json['role'] as String?,
      city: json['city'] as String?,
      imageUrl: json['imageUrl'] as String?,
      age: (json['age'] ?? 0) as int,
      idCardNumber: json['idCardNumber'] as String?,
      idCardImageUrl: json['idCardImageUrl'] as String?,
    );
  }
}

class OrderItem {
  final int orderId;
  final OrderUser renter;
  final OrderUser owner;
  final String dateFrom;
  final String dateTo;
  final int rentalDays;
  final double totalPrice;
  final String bikeName;
  final int bicycleId;
  final String? bikeImageUrl; // KANN verschachtelt kommen
  final String orderStatus;
  final String orderDate;

  OrderItem({
    required this.orderId,
    required this.renter,
    required this.owner,
    required this.dateFrom,
    required this.dateTo,
    required this.rentalDays,
    required this.totalPrice,
    required this.bikeName,
    required this.bicycleId,
    this.bikeImageUrl,
    required this.orderStatus,
    required this.orderDate,
  });

  OrderItem copyWith({String? bikeImageUrl}) => OrderItem(
        orderId: orderId,
        renter: renter,
        owner: owner,
        dateFrom: dateFrom,
        dateTo: dateTo,
        rentalDays: rentalDays,
        totalPrice: totalPrice,
        bikeName: bikeName,
        bicycleId: bicycleId,
        bikeImageUrl: bikeImageUrl ?? this.bikeImageUrl,
        orderStatus: orderStatus,
        orderDate: orderDate,
      );

  /// Robustes JSON-Mapping: viele mögliche Feldnamen + verschachteltes bicycle
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // evtl. verschachteltes Fahrrad-Objekt
    final Map<String, dynamic>? bicycle =
        json['bicycle'] is Map ? Map<String, dynamic>.from(json['bicycle']) : null;

    // Kandidaten für Bild-URL zusammentragen
    final String? img = (json['bikeImageUrl'] ??
            json['imageUrl'] ??
            json['image'] ??
            json['imagePath'] ??
            bicycle?['bikeImageUrl'] ??
            bicycle?['imageUrl'] ??
            bicycle?['image'] ??
            bicycle?['imagePath'])
        ?.toString();

    return OrderItem(
      orderId: (json['orderId'] ?? json['id']) is int
          ? (json['orderId'] ?? json['id']) as int
          : int.tryParse('${json['orderId'] ?? json['id'] ?? 0}') ?? 0,
      renter: OrderUser.fromJson(json['renter'] as Map<String, dynamic>),
      owner: OrderUser.fromJson(json['owner'] as Map<String, dynamic>),
      dateFrom: (json['dateFrom'] ?? '').toString(),
      dateTo: (json['dateTo'] ?? '').toString(),
      rentalDays: (json['rentalDays'] is int)
          ? json['rentalDays'] as int
          : int.tryParse('${json['rentalDays'] ?? 0}') ?? 0,
      totalPrice: (json['totalPrice'] is num)
          ? (json['totalPrice'] as num).toDouble()
          : (num.tryParse('${json['totalPrice'] ?? 0}') ?? 0).toDouble(),
      bikeName: (json['bikeName'] ?? bicycle?['name'] ?? 'Fahrrad').toString(),
      bicycleId: (json['bicycleId'] ?? bicycle?['id']) is int
          ? (json['bicycleId'] ?? bicycle?['id']) as int
          : int.tryParse('${json['bicycleId'] ?? bicycle?['id'] ?? 0}') ?? 0,
      bikeImageUrl: img,
      orderStatus: (json['orderStatus'] ?? 'PENDING').toString(),
      orderDate: (json['orderDate'] ?? json['createdAt'] ?? '').toString(),
    );
  }
}
