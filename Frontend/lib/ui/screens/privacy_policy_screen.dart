import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // remove if not using go_router
import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  void _handleDrawerSelect(BuildContext context, AppDrawerKey key) {
    Navigator.of(context).maybePop(); // close drawer
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
        context.go('/privacy'); // current page
        break;
      case AppDrawerKey.police:
        context.go('/police');
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

      // Drawer menu
      drawer: AppDrawer(onSelect: (k) => _handleDrawerSelect(context, k)),

      appBar: AppBar(
        title: const Text("Datenschutzerklärung"),
        centerTitle: true,
        backgroundColor: orange,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              "Datenschutzerklärung",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              "Wir schätzen Ihre Privatsphäre und verpflichten uns, Ihre persönlichen Daten zu schützen. "
              "Diese Richtlinie erklärt, wie wir Ihre Daten in der ShareCycle-App erfassen, verwenden und schützen.\n\n"
              "1. Datenerhebung: Wir erfassen grundlegende Kontodaten wie Name, E-Mail-Adresse und Telefonnummer.\n"
              "2. Datennutzung: Ihre Informationen werden ausschließlich zur Bereitstellung und Verbesserung unserer Dienste verwendet.\n"
              "3. Dritte: Wir verkaufen Ihre Daten nicht an Dritte.\n"
              "4. Sicherheit: Wir verwenden Verschlüsselung und sichere Server, um Ihre Daten zu schützen.\n"
              "5. Änderungen: Diese Richtlinie kann regelmäßig aktualisiert werden.",

              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: 3, // e.g., Profile tab selected; change if you prefer
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/home');
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
