import 'package:flutter/material.dart';
import 'package:sharecycleapp/theme/color.dart';

enum AppDrawerKey { logout, home, maps, setting, privacy, police, bikes, myBikes, ownerOrders, myRentals }

class AppDrawer extends StatelessWidget {
  final void Function(AppDrawerKey key) onSelect;
  final String version;

  const AppDrawer({
    super.key,
    required this.onSelect,
    this.version = 'v 1.0',
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      child: SafeArea(
        child: Container(
          color: orange,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text('Abmelden', style: TextStyle(color: Colors.white)),
                onTap: () async => {
                  onSelect(AppDrawerKey.logout)
                },
              ),
              const Divider(color: Colors.white24, height: 1),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 64,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.pedal_bike, color: Colors.white, size: 48),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _item(Icons.home_outlined,       'Startseite',    () => onSelect(AppDrawerKey.home)),
                    _item(Icons.map_outlined,        'Karte',    () => onSelect(AppDrawerKey.maps)),
                    _item(Icons.settings_outlined,   'Einstellungen', () => onSelect(AppDrawerKey.setting)),
                    _item(Icons.privacy_tip_outlined,'Datenschutz', () => onSelect(AppDrawerKey.privacy)),
                    _item(Icons.shield_outlined,     'Sicherheit & Hilfe',  () => onSelect(AppDrawerKey.police)),
                    _item(Icons.pedal_bike,          'Fahrräder',   () => onSelect(AppDrawerKey.bikes)),
                    _item(Icons.person_pin_circle,    'Meine Fahrräder',  () => onSelect(AppDrawerKey.myBikes)),
                    _item(Icons.receipt_long,        'Meine Bestellungen',   () => onSelect(AppDrawerKey.myRentals)),
                    _item(Icons.list_alt,            'Vermieter-Bestellungen',   () => onSelect(AppDrawerKey.ownerOrders)),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(version, style: const TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _item(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 8,
      minLeadingWidth: 24,
    );
  }
}
