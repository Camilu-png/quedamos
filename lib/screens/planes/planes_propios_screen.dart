import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/main.dart";
import "package:geolocator/geolocator.dart";
import "package:quedamos/screens/planes/planes_list.dart";
import "package:quedamos/screens/planes/plan_screen.dart";
import "package:quedamos/services/plans_service.dart";

final db = FirebaseFirestore.instance;

//MIS PLANES SCREEN
class MisPlanesScreen extends StatefulWidget {
  final String userID;
  final Position? currentLocation;
  const MisPlanesScreen({super.key, required this.userID, this.currentLocation});
  @override
  State<MisPlanesScreen> createState() => _MisPlanesScreenState();
}

//MIS PLANES SCREEN STATE
class _MisPlanesScreenState extends State<MisPlanesScreen> with RouteAware {
  
  String actividadSelected = "Activos";
  String busqueda = "";

  final PlansService _plansService = PlansService();
  List<Map<String, dynamic>> _allPlans = [];
  bool _isLoading = true;
  bool _hasConnectionError = false;
  String? _errorMessage;

  //INIT STATE
  @override
  void initState() {
    super.initState();
    _loadPlans();
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
    _loadPlans();
  }

  //DISPOSE
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  //LOAD PLANS
  Future<void> _loadPlans({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _hasConnectionError = false;
      _errorMessage = null;
    });

    try {
      final planes = await _plansService.getMyPlans(
        userId: widget.userID,
        forceRefresh: forceRefresh,
      );

      setState(() {
        _allPlans = planes;
        _isLoading = false;
        _hasConnectionError = false;
      });
    } catch (error) {
      print("[🐧 planes] Error: $error");
      
      // Check if it's a network error
      final isNetworkError = error.toString().contains('network') ||
                            error.toString().contains('connection') ||
                            error.toString().contains('Failed host lookup');
      
      setState(() {
        _isLoading = false;
        _hasConnectionError = isNetworkError;
        _errorMessage = isNetworkError 
            ? 'Sin conexión. Mostrando datos guardados.'
            : 'Error al cargar planes.';
      });
      
      // If we have cached data, don't clear it
      if (_allPlans.isNotEmpty) {
        print("[🐧 planes] Usando caché a pesar del error");
      }
    }
  }

  //GET FILTERED PLANS
  List<Map<String, dynamic>> _getFilteredPlans() {
    final now = DateTime.now();
    
    final planesFiltrados = _allPlans.where((plan) {
      //FECHA - filter by active/inactive
      final fechaEsEncuesta = plan["fechaEsEncuesta"] ?? false;
      if (!fechaEsEncuesta) {
        final fecha = plan["fecha"] is Timestamp
          ? (plan["fecha"] as Timestamp).toDate()
          : DateTime.tryParse(plan["fecha"]?.toString() ?? "") ?? now;
        if (actividadSelected == "Activos") {
          if (fecha.isBefore(now)) return false;
        } else {
          if (fecha.isAfter(now)) return false;
        }
      }
      
      //BÚSQUEDA
      if (busqueda.isNotEmpty) {
        final titulo = (plan["titulo"] ?? "").toString().toLowerCase();
        final queryText = busqueda.toLowerCase();
        if (!titulo.contains(queryText)) {
          return false;
        }
      }
      
      return true;
    }).toList();

    //ORDEN: FECHA
    planesFiltrados.sort((a, b) {
      final fechaA = a["fecha"] as Timestamp?;
      final fechaB = b["fecha"] as Timestamp?;
      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaA.compareTo(fechaB);
    });

    return planesFiltrados;
  }

  @override
  Widget build(BuildContext context) {

    final userID = widget.userID;
    
    if (widget.userID.isEmpty || widget.currentLocation == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                "Obteniendo ubicación...",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    else {
      print("[🐧 planes] UID del usuario: ${widget.userID}");
    }
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        //APP BAR
        appBar: AppBar(
          title: Text(
            "Mis planes",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
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
                    ButtonSegment(value: "Activos", label: Text("Activos", style: Theme.of(context).textTheme.bodyMedium)),
                    ButtonSegment(value: "Inactivos", label: Text("Inactivos", style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                  selected: <String>{actividadSelected},
                  onSelectionChanged: (actividadSelection) {
                    setState(() {
                      actividadSelected = actividadSelection.first;
                    });
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
                child: _isLoading
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
                                userID: userID,
                                currentLocation: widget.currentLocation,
                                onTapOverride: (ctx, planData) async {
                                  final result = await Navigator.push(
                                    ctx,
                                    MaterialPageRoute(
                                      builder: (_) => PlanScreen(
                                        plan: planData,
                                        userID: userID,
                                        currentLocation: widget.currentLocation,
                                      ),
                                    ),
                                  );
                                  if (result == "deleted") {
                                    if (mounted) _loadPlans(forceRefresh: true);
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
