// lib/ui/components/header.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sharecycleapp/theme/color.dart';

class HeaderComponent extends StatefulWidget {
  /// اسم المستخدم إن توفر. إذا كان null سيُقرأ من SharedPreferences.
  final String? name;

  /// رابط الصورة (يمكن أن يكون مطلقًا أو Asset). إذا كان null سيُقرأ من SharedPreferences.
  final String? imageUrl;

  /// تُمَرَّر هنا الـ Headers (مثلاً Authorization) عند تحميل الصورة من الـ API.
  final Map<String, String>? networkHeaders;

  final VoidCallback? onNotificationTap;

  const HeaderComponent({
    super.key,
    this.name,
    this.imageUrl,
    this.networkHeaders,
    this.onNotificationTap,
  });

  @override
  State<HeaderComponent> createState() => _HeaderComponentState();
}

class _HeaderComponentState extends State<HeaderComponent> {
  static const _kUserJsonKey = 'auth_user_json';

  String? _name;
  String? _imageUrl; // http(s) أو asset path

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _imageUrl = widget.imageUrl;
    if (_name == null || _imageUrl == null) {
      _loadFromStorage();
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUserJsonKey);
      if (raw == null) return;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final apiName = (map['name'] as String?)?.trim();
      final email   = (map['email'] as String?)?.trim();
      // حقول الصورة المتوقعة من الـ API
      final storedAvatar = (map['avatar'] ?? map['imageUrl'])?.toString();

      if (!mounted) return;
      setState(() {
        _name ??= (apiName?.isNotEmpty == true) ? apiName : (email ?? 'User');
        _imageUrl ??= storedAvatar;
      });
    } catch (_) {
      // تجاهل أخطاء JSON
    }
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _initialsCircle(String displayName) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white.withOpacity(0.18),
      child: Text(
        _initials(displayName),
        style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14,
        ),
      ),
    );
  }

  Widget _avatar(String displayName) {
    final url = _imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _initialsCircle(displayName);
    }

    // صورة من الإنترنت (محميّة أو عامة)
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return SizedBox(
        width: 44, height: 44,
        child: ClipOval(
          child: Image.network(
            url,
            headers: widget.networkHeaders, // <— مهم للصور المحمية
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsCircle(displayName),
          ),
        ),
      );
    }

    // صورة من الأصول (assets)
    return SizedBox(
      width: 44, height: 44,
      child: ClipOval(
        child: Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsCircle(displayName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (_name ?? '').trim().isEmpty ? 'User' : _name!.trim();

    return Container(
      color: orange,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _avatar(displayName),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hello\n$displayName',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white, fontSize: 16, height: 1.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: widget.onNotificationTap,
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}
