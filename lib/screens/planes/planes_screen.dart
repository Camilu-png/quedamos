import "package:flutter/material.dart";
import 'package:geolocator/geolocator.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/main.dart";
import "package:quedamos/screens/planes/planes_list.dart";
import "package:quedamos/screens/planes/plan_screen.dart";
import "package:quedamos/services/plans_service.dart";

final db = FirebaseFirestore.instance;

//PLANES SCREEN
class PlanesScreen extends StatefulWidget {
  final String userID;
  final Position? currentLocation;
  const PlanesScreen({super.key, required this.userID, this.currentLocation});
  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

//PLANES SCREEN STATE
class _PlanesScreenState extends State<PlanesScreen> with RouteAware {

  String visibilidadSelected = "Amigos";
  String busqueda = "";
  
  final PlansService _plansService = PlansService();
  List<Map<String, dynamic>> _allPlans = [];
  bool _isLoadingFromCache = true;
  bool _hasConnectionError = false;
  String? _errorMessage;

  //INIT STATE
  @override
  void initState() {
    super.initState();
    currentPosition = widget.currentLocation;
    _loadPlans(); // Use cache if available
  }



  //DID CHANGE DEPENDENCIES
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  //DID POP NEXT
  @override
  void didPopNext() {
    super.didPopNext();
    // Only refresh if cache is stale, otherwise just rebuild with existing data
    _loadPlans(forceRefresh: false);
  }

  //DISPOSE
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  //LOAD PLANS (with caching)
  Position? currentPosition;
  Future<void> _loadPlans({bool forceRefresh = false}) async {
    print("[🐧 planes] Cargando planes (forceRefresh: $forceRefresh)...");
    
    setState(() {
      _isLoadingFromCache = true;
      _hasConnectionError = false;
      _errorMessage = null;
    });

    try {
      //AMIGOS IDs
      List<String> amigosIDs = [];
      if (visibilidadSelected == "Amigos") {
        print("[🐧 planes] Recuperando amigos de la base de datos...");
        final amigosSnapshot = await db
          .collection("users")
          .doc(widget.userID)
          .collection("friends")
          .get();
        amigosIDs = amigosSnapshot.docs.map((doc) => doc.id).toList();
      }

      // Get plans from service (with caching)
      final planes = await _plansService.getPlans(
        userId: widget.userID,
        visibilidad: visibilidadSelected,
        friendIds: amigosIDs,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _allPlans = planes;
        _isLoadingFromCache = false;
        _hasConnectionError = false;
      });

      print("[🐧 planes] Planes cargados: ${planes.length}");
    } catch (error, stackTrace) {
      print("[🐧 planes] Error: $error");
      print("[🐧 planes] Error: $stackTrace");
      
      // Check if it's a network error
      final isNetworkError = error.toString().contains('network') ||
                            error.toString().contains('connection') ||
                            error.toString().contains('Failed host lookup');
      
      setState(() {
        _isLoadingFromCache = false;
        _hasConnectionError = isNetworkError;
        _errorMessage = isNetworkError 
            ? 'Sin conexión. Mostrando datos guardados.'
            : 'Error al cargar planes.';
      });
      
      // If we have cached data, don't show error to user
      if (_allPlans.isNotEmpty) {
        print("[🐧 planes] Usando caché a pesar del error");
      }
    }
  }

  //REFRESH PLANS
  void _refreshPlans() {
    print("[🐧 planes] Refrescando planes...");
    _loadPlans(forceRefresh: true);
  }

  //GET FILTERED AND SORTED PLANS
  List<Map<String, dynamic>> _getFilteredPlans() {
    final now = DateTime.now();
    
    // Filter plans
    final planesFiltrados = _allPlans.where((plan) {
      //FECHA - filter out past events
      final fechaEsEncuesta = plan["fechaEsEncuesta"] ?? false;
      if (!fechaEsEncuesta) {
        final fecha = plan["fecha"] is Timestamp
          ? (plan["fecha"] as Timestamp).toDate()
          : DateTime.tryParse(plan["fecha"]?.toString() ?? "") ?? now;
        if (fecha.isBefore(now)) return false;
      }
      
      //BÚSQUEDA
      if (busqueda.isNotEmpty) {
        final titulo = (plan["titulo"] ?? "").toString().toLowerCase();
        final anfitrionNombre = (plan["anfitrionNombre"] ?? "").toString().toLowerCase();
        final queryText = busqueda.toLowerCase();
        if (!titulo.contains(queryText) && !anfitrionNombre.contains(queryText)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    //ORDENAR POR DISTANCIA
    if (currentPosition != null) {
      planesFiltrados.sort((a, b) {
        double distanciaA = double.infinity;
        double distanciaB = double.infinity;
        
        //DISTANCIA A
        final ubicacionA = a["ubicacion"];
        if (a["ubicacionEsEncuesta"] != true && ubicacionA != null && ubicacionA is Map<String, dynamic>) {
          final lat = ubicacionA["latitud"];
          final lng = ubicacionA["longitud"];
          final latDouble = (lat is int)
            ? lat.toDouble()
            : double.tryParse(lat.toString());
          final lngDouble = (lng is int)
            ? lng.toDouble()
            : double.tryParse(lng.toString());
          if (latDouble != null && lngDouble != null) {
            distanciaA = Geolocator.distanceBetween(
              currentPosition!.latitude,
              currentPosition!.longitude,
              latDouble,
              lngDouble,
            );
          }
        }
        
        //DISTANCIA B
        final ubicacionB = b["ubicacion"];
        if (b["ubicacionEsEncuesta"] != true && ubicacionB != null && ubicacionB is Map<String, dynamic>) {
          final lat = ubicacionB["latitud"];
          final lng = ubicacionB["longitud"];
          final latDouble = (lat is int)
            ? lat.toDouble()
            : double.tryParse(lat.toString());
          final lngDouble = (lng is int)
            ? lng.toDouble()
            : double.tryParse(lng.toString());
          if (latDouble != null && lngDouble != null) {
            distanciaB = Geolocator.distanceBetween(
              currentPosition!.latitude,
              currentPosition!.longitude,
              latDouble,
              lngDouble,
            );
          }
        }
        
        return distanciaA.compareTo(distanciaB);
      });
    }

    return planesFiltrados;
  }

  @override
  Widget build(BuildContext context) {

    if (widget.userID.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Cargando...",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            "Planes",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            )
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              //OFFLINE BANNER
              if (_hasConnectionError && _allPlans.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 20,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage ?? 'Sin conexión',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              //SEGMENTED BUTTON
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: "Amigos", label: Text("Amigos", style: Theme.of(context).textTheme.bodyMedium)),
                    ButtonSegment(value: "Público", label: Text("Público", style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                  selected: <String>{visibilidadSelected},
                  onSelectionChanged: (visibilidadSelection) {
                    setState(() {
                      visibilidadSelected = visibilidadSelection.first;
                    });
                    _loadPlans();
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    selectedForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    side: BorderSide.none,
                  ),
                ),
              ),

              //BUSCADOR
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  onChanged: (busquedaValor) {
                    setState(() {
                      busqueda = busquedaValor;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Buscar planes...",
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                    prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              //LISTA DE PLANES
              Expanded(
                child: _isLoadingFromCache
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _loadPlans(forceRefresh: true);
                      },
                      child: Builder(
                        builder: (context) {
                          final filteredPlans = _getFilteredPlans();
                          
                          // No plans and has error (no cache, no connection)
                          if (filteredPlans.isEmpty && _hasConnectionError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_off,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Sin conexión a internet",
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No se pueden cargar los planes",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    onPressed: () => _loadPlans(forceRefresh: true),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Reintentar"),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          if (filteredPlans.isEmpty) {
                            return const Center(
                              child: Text("No se encontraron planes."),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: filteredPlans.length,
                            itemBuilder: (context, index) {
                              final plan = filteredPlans[index];
                              return PlanesList(
                                plan: plan,
                                userID: widget.userID,
                                currentLocation: widget.currentLocation,
                                onTapOverride: (ctx, planData) async {
                                  final result = await Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) => PlanScreen(
                                        plan: planData,
                                        userID: widget.userID,
                                        currentLocation: widget.currentLocation,
                                      ),
                                    ),
                                  );
                                  if (result == "deleted") {
                                    if (mounted) _refreshPlans();
                                  }
                                },
                              );
                            },
                          );
                        },
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
