import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sharecycleapp/theme/color.dart';
import 'package:sharecycleapp/ui/components/bottom_navigation.dart';
import 'package:sharecycleapp/ui/components/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Möchten Sie Ihr Konto wirklich löschen?'),
        content: const Text(
          'Achtung: Ihre Daten werden dauerhaft gelöscht. Möchten Sie fortfahren?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('löschen'),
          ),
        ],
      ),
    );

    if (ok == true) {
      // TODO: call your delete-account API, clear auth, etc.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konto gelöscht')),
        );
        context.go('/login');
      }
    }
  }

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
        context.go('/settings'); // current page
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
      case AppDrawerKey.myBikes: context.go('/my-bikes');  break;
       case AppDrawerKey.ownerOrders: context.go('/orders');  break;
      case AppDrawerKey.myRentals: context.go("/my-orders"); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Drawer
      drawer: AppDrawer(onSelect: (k) => _handleDrawerSelect(context, k)),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Einstellungen', style: TextStyle(fontWeight: FontWeight.w700)),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 24),

              Icon(Icons.settings_outlined, color: orange, size: 56),
              const SizedBox(height: 8),
              const Text('Setting',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),

              const SizedBox(height: 28),

              // Profile
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.person_outline, color: Colors.white),
                  label: const Text('Profil', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 14),

              // Delete
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  label: const Text('Konto löschen',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: BottomNavigationComponent(
        currentIndex: 3, // Profile tab highlighted; adjust if needed
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
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}
