import 'package:flutter/material.dart';
import 'friends_screen.dart';
import 'planes/planes_propios_screen.dart';
import 'planes/planes_add_screen.dart';
import 'planes/planes_screen.dart';
import 'profile_sreen.dart';
import '../widgets/custom_navbar.dart';

class MainScreen extends StatefulWidget {
  final String userID;
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0, required this.userID});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late Widget _currentScreen;


  late final List<Widget> _mainScreens;

  @override
  void initState() {
    super.initState();
    _mainScreens = [
      PlanesScreen(userID: widget.userID),
      MisPlanesScreen(userID: widget.userID),
      AddPlanesScreen(userID: widget.userID),
      FriendsScreen(userID: widget.userID),
      ProfileScreen(userID: widget.userID),
    ];
    _currentIndex = widget.initialIndex;
    _currentScreen = _mainScreens[_currentIndex];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
      _currentScreen = _mainScreens[_currentIndex];
    });
  }

  void navigateTo(Widget newScreen) {
    setState(() {
      _currentScreen = newScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentScreen,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
