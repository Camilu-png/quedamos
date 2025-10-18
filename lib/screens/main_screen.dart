import 'package:flutter/material.dart';
import 'friends_screen.dart';
import 'mis_planes_screen.dart';
import 'add_planes_screen.dart';
import 'planes_screen.dart';
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

  final List<Widget> _mainScreens = const [
    PlanesScreen(),
    MisPlanesScreen(),
    AddPlanesScreen(),
    FriendsScreen(),
  ];

  @override
  void initState() {
    super.initState();
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
    print("UID del usuario -> ${widget.userID}");
    return Scaffold(
      body: _currentScreen,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
