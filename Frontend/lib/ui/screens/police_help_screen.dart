import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // falls du go_router nutzt
import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';

class PoliceHelpScreen extends StatelessWidget {
  const PoliceHelpScreen({super.key});

  void _handleDrawerSelect(BuildContext context, AppDrawerKey key) {
    Navigator.of(context).maybePop(); // Drawer schließen
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
        context.go('/police'); // aktuelle Seite
        break;
      case AppDrawerKey.bikes:
        context.go('/bikes');
        break;
        case AppDrawerKey.myBikes: context.go('/my-bikes');  break;
        case AppDrawerKey.ownerOrders: context.go('/orders');  break;
      case AppDrawerKey.myRentals: context.go('/my-orders'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 🔶 Drawer hinzufügen
      drawer: AppDrawer(onSelect: (key) => _handleDrawerSelect(context, key)),

      appBar: AppBar(
        title: const Text("Sicherheit & Hilfe"),
        centerTitle: true,
        backgroundColor: orange,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Notfallkontakte",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_police, color: orange),
                title: const Text("Polizei-Notruf"),
                subtitle: const Text("Notruf 110 (Deutschland)"),
                onTap: () {
                  // TODO: Add phone dialer integration
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.medical_services, color: orange),
                title: const Text("Rettungsdienst Notfall 112"),
                subtitle: const Text("Notruf 112 (Deutschland)"),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sicherheitstipps",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "• Schließen Sie Ihr Fahrrad immer ab, wenn es nicht benutzt wird.\n"
              "• Meiden Sie nachts schlecht beleuchtete oder abgelegene Gegenden.\n"
              "• Melden Sie verdächtige Aktivitäten sofort.\n"
              "• Speichern Sie Ihre Notfallkontakte im Handy.",
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),

      // 🔶 Bottom Navigation hinzufügen
      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: 2, // z. B. Tab für „Police“ oder ändern
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/home');
              break;
            case 2:
              context.go('/maps'); // aktuelle Seite
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
