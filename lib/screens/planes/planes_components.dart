import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:quedamos/app_colors.dart";
import "dart:async";
import "dart:convert";
import "package:http/http.dart" as http;
import "package:geolocator/geolocator.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:google_maps_flutter/google_maps_flutter.dart" as gmaps;
import "package:flutter_google_places_sdk/flutter_google_places_sdk.dart";

//ICONOS MAP
final Map<String, IconData> iconosMap = {
  "event": Icons.event,
  "star": Icons.star,
  "home": Icons.home,
  "work": Icons.work,
  "favorite": Icons.favorite,
  "school": Icons.school,
  "shopping": Icons.shopping_cart,
  "restaurant": Icons.restaurant,
  "fitness": Icons.fitness_center,
  "travel": Icons.flight,
  "music": Icons.music_note,
  "movie": Icons.movie,
  "pets": Icons.pets,
  "beach": Icons.beach_access,
  "birthday": Icons.cake,
  "meeting": Icons.meeting_room,
  "coffee": Icons.coffee,
  "book": Icons.book,
  "camera": Icons.camera_alt,
  "game": Icons.videogame_asset,
  "hiking": Icons.terrain,
  "swimming": Icons.pool,
  "cycling": Icons.directions_bike,
  "car": Icons.directions_car,
  "train": Icons.train,
  "bus": Icons.directions_bus,
  "park": Icons.park,
  "theater": Icons.theater_comedy,
  "picnic": Icons.emoji_food_beverage,
  "shopping_bag": Icons.shopping_bag,
  "party": Icons.celebration,
  "study": Icons.menu_book,
  "yoga": Icons.self_improvement,
  "concert": Icons.mic,
  "photo": Icons.photo_camera,
  "hobby": Icons.brush,
  "gym": Icons.sports_gymnastics,
  "run": Icons.directions_run,
  "beach_volleyball": Icons.sports_volleyball,
  "ski": Icons.downhill_skiing,
};

//COLORES MAP
final Map<String, Color> coloresMap = {
  "red": Colors.red,
  "pink": Colors.pink,
  "purple": Colors.purple,
  "deepPurple": Colors.deepPurple,
  "indigo": Colors.indigo,
  "blue": Colors.blue,
  "lightBlue": Colors.lightBlue,
  "cyan": Colors.cyan,
  "teal": Colors.teal,
  "green": Colors.green,
  "lightGreen": Colors.lightGreen,
  "lime": Colors.lime,
  "yellow": Colors.yellow,
  "amber": Colors.amber,
  "orange": Colors.orange,
  "deepOrange": Colors.deepOrange,
  "brown": Colors.brown,
  "grey": Colors.grey,
  "blueGrey": Colors.blueGrey,
  "secondary": secondary,
};

//STRING -> TIME OF DAY
TimeOfDay? stringToTimeOfDay(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split(":");
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

//TIME OF DAY -> STRING
String timeOfDayToString(TimeOfDay t) {
  final hour = t.hour.toString().padLeft(2, "0");
  final minute = t.minute.toString().padLeft(2, "0");
  return "$hour:$minute";
}

//ICON DATA -> STRING
String getIconName(IconData icon) {
  return iconosMap.entries
    .firstWhere((entry) => entry.value == icon,
      orElse: () => const MapEntry("event", Icons.event))
    .key;
}

//COLOR -> STRING
String getColorName(Color color) {
  return coloresMap.entries
    .firstWhere((entry) => entry.value == color,
      orElse: () => const MapEntry("secondary", secondary))
    .key;
}

// SHOW MAP
Future<void> showMap(
  BuildContext context,
  bool mounted,
  Map<String, dynamic> ubicacion,
) async {
  print("[🐧 planes] Abriendo mapa...");
  if (!ubicacion.containsKey("latitud") || !ubicacion.containsKey("longitud")) {
    print("[🐧 planes] Ubicación sin latitud/longitud.");
    return;
  }
  final lat = ubicacion["latitud"];
  final lng = ubicacion["longitud"];
  final direccion = (ubicacion["direccion"] as String?)?.trim();
  // Si hay dirección, la incluimos en el query, si no, solo lat,lng
  final String queryTexto = direccion != null && direccion.isNotEmpty
      ? "$lat,$lng ($direccion)"
      : "$lat,$lng";
  // Construir URI de forma segura
  final uri = Uri.https(
    "www.google.com",
    "/maps/search/",
    {
      "api": "1",
      "query": queryTexto,
    },
  );
  print("[🐧 planes] URL mapa: $uri");
  try {
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el mapa.")),
      );
    }
  } catch (e) {
    print("[🐧 planes] Error al abrir mapa: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el mapa.")),
      );
    }
  }
}
//GET PLACE NAME FROM LATITUD & LONGITUDE
Future<String?> getPlaceNameFromLatLng(double lat, double lng) async {
  final apiKey = dotenv.env["API_KEY"] ?? ""; //API KEY
  final url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey");
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data["results"] != null && data["results"].isNotEmpty) {
      return data["results"][0]["formatted_address"];
    }
  }
  return null;
}

//SELECTOR DE UBICACIÓN
Future<void> showUbicacionSelector(
  BuildContext context,
  // onLocationSelected: (latLng, shortName, fullAddress)
  Function(gmaps.LatLng, String, String) onLocationSelected, {
  Position? initialPosition,
}) {
  //MODAL
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Seleccionar ubicación",
    pageBuilder: (_, __, ___) => UbicacionSelectorMapa(onLocationSelected: onLocationSelected, initialPosition: initialPosition),
    transitionDuration: const Duration(milliseconds: 300),
    transitionBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(anim),
        child: child,
      );
    },
  );
  return Future.value();
}

//UBICACIÓN SELECTOR: MAPA
class UbicacionSelectorMapa extends StatefulWidget {
  // onLocationSelected: (latLng, shortName, fullAddress)
  final Function(gmaps.LatLng, String, String) onLocationSelected;
  final Position? initialPosition;
  const UbicacionSelectorMapa({super.key, required this.onLocationSelected, this.initialPosition});
  @override
  State<UbicacionSelectorMapa> createState() => _UbicacionSelectorMapaState();
}
class _UbicacionSelectorMapaState extends State<UbicacionSelectorMapa> {
  gmaps.LatLng selectedLocation = const gmaps.LatLng(-33.0458, -71.6197); //Casa Central, UTFSM
  gmaps.GoogleMapController? mapController;
  late FlutterGooglePlacesSdk places;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<AutocompletePrediction> _predictions = [];
  Timer? _debounce;
  bool _hasSetInitialLocation = false; 
  bool _isLoadingLocation = true;
  bool _nameEdited = false;
  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env["API_KEY"] ?? "";
    places = FlutterGooglePlacesSdk(apiKey); //API KEY
    //Si existe locación inicial... 
    print("[🐧 planes] $widget.initialPosition");
    if (widget.initialPosition != null) {
      print("[🐧 planes] SIIIIIIIIIIIIIIII");
      selectedLocation = gmaps.LatLng(widget.initialPosition!.latitude, widget.initialPosition!.longitude);
      _hasSetInitialLocation = true;
      _isLoadingLocation = false;
    } else {
      print("[🐧 planes] NOOOOOOOOOOOOO");
      _setCurrentLocation();
    }
  }
  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
  //CENTRAR MAPA EN UBICACIÓN ACTUAL
  Future<void> _setCurrentLocation() async {
    if (_hasSetInitialLocation) return; 
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final current = gmaps.LatLng(position.latitude, position.longitude);
      setState(() {
        selectedLocation = current;
        _hasSetInitialLocation = true; 
        _isLoadingLocation = false;
      });
      mapController?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(current, 15));
    } else {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }
  Future<void> _buscarLugares(String query) async {
    if (query.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await places.findAutocompletePredictions(query);
      setState(() {
        _predictions = result.predictions;
      });
    });
  }
  Future<void> _moverAlLugar(String placeId) async {
    final details = await places.fetchPlace(
      placeId,
      fields: [PlaceField.Location, PlaceField.Name],
    );
    final location = details.place?.latLng;
    if (location != null) {
      final target = gmaps.LatLng(location.lat, location.lng);
      mapController?.animateCamera(gmaps.CameraUpdate.newLatLngZoom(target, 16));
      setState(() {
        selectedLocation = target;
        _searchController.text = details.place?.name ?? "";
        //Set short name default and reset edited flag
        final short = (_searchController.text.split(',').first).trim();
        _nameController.text = short;
        _nameEdited = false;
        _predictions = [];
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  //TÍTULO
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 16),
                    child: Text(
                      "Seleccionar ubicación",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  //BOTÓN: CERRAR
                  Padding(
                    padding: const EdgeInsets.only(right: 16, top: 16),
                    child: SizedBox(
                      height: 48,
                      width: 48,
                      child: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 24
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  )  
                ]
              ),
              //BÚSQUEDA
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        //DIRECCIÓN
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Buscar lugar...",
                            hintStyle: Theme.of(context).textTheme.bodyMedium,
                            prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) {
                            _buscarLugares(v);
                            if (!_nameEdited) {
                              final short = v.split(',').first.trim();
                              _nameController.text = short;
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        //NOMBRE
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: "Nombre del lugar",
                            hintStyle: Theme.of(context).textTheme.bodyMedium,
                            prefixIcon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) {
                            _nameEdited = true;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //CUERPO
              if (_isLoadingLocation)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                )
              //BÚSQUEDA: PREDICCIONES
              else if (_predictions.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final p = _predictions[index];
                      return ListTile(
                        title: Text(p.primaryText),
                        subtitle: Text(p.secondaryText),
                        onTap: () => _moverAlLugar(p.placeId),
                      );
                    },
                  ),
                )
              //MAPA
              else
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: gmaps.GoogleMap(
                          initialCameraPosition: gmaps.CameraPosition(
                          target: selectedLocation,
                          zoom: 16,
                        ),
                        onMapCreated: (controller) {
                          mapController = controller;
                          _setCurrentLocation();
                        },
                        onCameraMove: (pos) {
                          selectedLocation = pos.target;
                        },
                        onCameraIdle: () async {
                          final placeName = await getPlaceNameFromLatLng(
                              selectedLocation.latitude, selectedLocation.longitude);
                          if (placeName != null) {
                            setState(() {
                              _searchController.text = placeName;
                              if (!_nameEdited) {
                                final short = placeName.split(',').first.trim();
                                _nameController.text = short;
                              }
                            });
                          }
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
                      ),
                      Center(
                        child: Icon(
                          Icons.location_pin,
                          size: 50,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: () {
                        // return (latLng, shortName, fullAddress)
                        widget.onLocationSelected(selectedLocation, _nameController.text, _searchController.text);
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text("Confirmar ubicación"),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
