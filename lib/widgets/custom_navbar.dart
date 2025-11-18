import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: colorScheme.primary,
      indicatorColor: colorScheme.primaryContainer,
      height: 70,
      destinations: [
        NavigationDestination(
          icon: Icon(
            Icons.location_on_outlined,
            color: colorScheme.onPrimary,
          ),
          selectedIcon: Icon(
            Icons.location_on,
            color: colorScheme.onPrimaryContainer,
          ),
          label: 'Planes',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.calendar_today_outlined,
            color: colorScheme.onPrimary,
          ),
          selectedIcon: Icon(
            Icons.calendar_today,
            color: colorScheme.onPrimaryContainer,
          ),
          label: 'Mis planes',
        ),
        NavigationDestination(
          icon: Container(
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.add,
              color: colorScheme.onSecondary,
              size: 32,
            ),
          ),
          selectedIcon: Container(
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.add,
              color: colorScheme.onSecondary,
              size: 32,
            ),
          ),
          label: 'Crear plan',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.group_outlined,
            color: colorScheme.onPrimary,
          ),
          selectedIcon: Icon(
            Icons.group,
            color: colorScheme.onPrimaryContainer,
          ),
          label: 'Amigos',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.person_outline,
            color: colorScheme.onPrimary,
          ),
          selectedIcon: Icon(
            Icons.person,
            color: colorScheme.onPrimaryContainer,
          ),
          label: 'Perfil',
        ),
      ],
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      elevation: 0,
      surfaceTintColor: colorScheme.surfaceTint,
    );
  }
}