import 'package:flutter/material.dart';
import '../app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: primaryColor,
        indicatorColor: primaryDark.withOpacity(0.5),
        height: 70,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.location_on_outlined, color: Colors.white),
            selectedIcon: const Icon(Icons.location_on, color: Colors.white),
            label: 'Planes',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
            selectedIcon: const Icon(Icons.calendar_today, color: Colors.white),
            label: 'Mis planes',
          ),
          NavigationDestination(
            icon: Container(
              decoration: BoxDecoration(
                color: primaryDark,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
            selectedIcon: Container(
              decoration: BoxDecoration(
                color: primaryDark,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.add, color: Colors.white, size: 32),
            ),
            label: 'Crear plan',
          ),
          NavigationDestination(
            icon: const Icon(Icons.group_outlined, color: Colors.white),
            selectedIcon: const Icon(Icons.group, color: Colors.white),
            label: 'Amigos',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Perfil',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        elevation: 3,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}