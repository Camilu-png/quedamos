import 'package:flutter/material.dart';
import 'package:quedamos/screens/add_friend_screen.dart';
import 'friends_screen.dart';
import 'mis_planes_screen.dart';
import 'add_planes_screen.dart';
import 'planes_screen.dart';
import '../widgets/custom_navbar.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    PlanesScreen(),
    MisPlanesScreen(),
    AddPlanesScreen(),
    FriendsScreen(),
    AddFriendsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}