import "package:flutter/material.dart";
import "package:geolocator/geolocator.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "profile_sreen.dart";
import "friends_screen.dart";
import "planes/planes_screen.dart";
import "planes/plan_add_screen.dart";
import "planes/planes_propios_screen.dart";
import "package:quedamos/widgets/custom_navbar.dart";

class MainScreen extends StatefulWidget {
  final String userID;
  final int initialIndex;
  final Position? currentLocation;
  const MainScreen({super.key, this.initialIndex = 0, required this.userID, this.currentLocation});
  @override
  State<MainScreen> createState() => MainScreenState();
}

//PENDIENTE: REVISAR PQ NO SIRVE UPDATE DE TOKEN
void listenTokenChanges(String uid) {
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .update({"fcmToken": newToken});
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

  //VISTAS DEL NAV BAR
  List<Widget> _buildMainScreens() {
    return [
      PlanesScreen(userID: widget.userID, currentLocation: _currentLocation),
      MisPlanesScreen(userID: widget.userID, currentLocation: _currentLocation),
      AddPlanScreen(userID: widget.userID, currentLocation: _currentLocation,),
      FriendsScreen(userID: widget.userID),
      ProfileScreen(userID: widget.userID),
    ];
  }

  //INICIALIZAR LOCACIÓN
  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print("[🐼 main screen] inicializando locación...");
      if (!serviceEnabled) {
        print("[🐼 main screen] servicios de locación deshabilitados...");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      print("[🐼 main screen] permiso actual: $permission");
      if (permission == LocationPermission.denied) {
        print("[🐼 main screen] permiso denegado, solicitando...");
        permission = await Geolocator.requestPermission();
        print("[🐼 main screen] permiso después de la solicitud: $permission");
      }
      if (permission == LocationPermission.deniedForever) {
        //Debe activarlo en ajustes
        return;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        print("[🐼 main screen] permiso obtenido, obteniendo posición...");
        final posicion = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        print("[🐼 main screen] posición: $posicion");
        if (mounted) {
          setState(() {
            _currentLocation = posicion;
            _mainScreens = _buildMainScreens(); //Reconstruir vistas para que reciban la locación actualizada
            _currentScreen = _mainScreens[_currentIndex];
          });
        }
      }
    } catch (e) {
      print("[🐼 main screen] Error: $e");
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
