import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'friends_screen.dart';
import 'planes/planes_propios_screen.dart';
import 'planes/plan_add_screen.dart';
import 'planes/planes_screen.dart';
import 'profile_sreen.dart';
import '../widgets/custom_navbar.dart';
import 'package:geolocator/geolocator.dart';

class MainScreen extends StatefulWidget {
  final String userID;
  final int initialIndex;
  final Position? currentLocation;
  const MainScreen({super.key, this.initialIndex = 0, required this.userID, this.currentLocation});

  @override
  State<MainScreen> createState() => MainScreenState();
}
// REVISAR PQ NO SIRVE UPDATE DE TOKEN
void listenTokenChanges(String uid) {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': newToken});
  });
}

class MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  late Widget _currentScreen;
  Position? _currentLocation;

  late List<Widget> _mainScreens;

  @override
  void initState() {
    super.initState();
    _initLocation();

    listenTokenChanges(widget.userID);
    _mainScreens = _buildMainScreens();
    _currentIndex = widget.initialIndex;
    _currentScreen = _mainScreens[_currentIndex];
  }

  List<Widget> _buildMainScreens() {
    return [
      PlanesScreen(userID: widget.userID, currentLocation: _currentLocation),
      MisPlanesScreen(userID: widget.userID, currentLocation: _currentLocation),
      AddPlanScreen(userID: widget.userID, currentLocation: _currentLocation,),
      FriendsScreen(userID: widget.userID),
      ProfileScreen(userID: widget.userID),
    ];
  }

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('[MainScreen] _initLocation: starting location init...');
      if (!serviceEnabled) {
        print('[MainScreen] location services disabled');
        return; // o pedir al usuario que la habilite
      }

      LocationPermission permission = await Geolocator.checkPermission();
      print('[MainScreen] permission current: $permission');
      if (permission == LocationPermission.denied) {
        print('[MainScreen] permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        print('[MainScreen] permission after request: $permission');
      }
      if (permission == LocationPermission.deniedForever) {
        // mostrar UI que explique que debe activarlo en ajustes
        return;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print('[MainScreen] permission granted, getting position...');
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        print('[MainScreen] got position: $pos');
        if (mounted) setState(() {
          _currentLocation = pos;
          // rebuild child screens so they receive the updated location
          _mainScreens = _buildMainScreens();
          _currentScreen = _mainScreens[_currentIndex];
        });
      }
    } catch (e) {
      // log / fallback
      print('[MainScreen] Error obteniendo ubicación: $e');
    }
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
