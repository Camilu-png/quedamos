import 'package:flutter/material.dart';
import 'friends_screen.dart';
import 'mis_planes_screen.dart';
import 'add_planes_screen.dart';
import 'planes_screen.dart';
import '../widgets/custom_navbar.dart';
import '../app_colors.dart';

class MainScreen extends StatefulWidget {
  final String userID;
  const MainScreen({super.key, required this.userID});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  //PANTALLAS
  final List<Widget> _screens = const [
    PlanesScreen(),
    MisPlanesScreen(),
    AddPlanesScreen(),
    FriendsScreen(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("UID del usuario -> ${widget.userID}");
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
