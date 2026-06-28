import 'package:flutter/material.dart';
import 'package:sharecycleapp/theme/color.dart';

class BottomNavigationComponent extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationComponent({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) {
          final scaffold = Scaffold.maybeOf(context);
          if (scaffold?.hasDrawer ?? false) {
            scaffold!.openDrawer(); // open Drawer from the component itself
          }
          return;
        }
        onTap(index);
      },
      selectedItemColor: orange,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Startseite'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Karte'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Einstellungen'),
      ],
    );
  }
}
