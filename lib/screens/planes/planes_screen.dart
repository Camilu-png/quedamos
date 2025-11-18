import "package:flutter/material.dart";
import "package:geolocator/geolocator.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/main.dart";
import "package:quedamos/screens/planes/planes_list.dart";
import "package:quedamos/screens/planes/planes_components.dart";
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

  String viewMode = "descubrir";
  String busqueda = "";
  Set<String> categoriasSeleccionadas = {};
  String? filtroFecha;
  double? filtroDistancia;
  Set<String> filtroEstadosSeleccionadas = {};
  Set<String> filtroVisibilidades = {};
  Set<String> filtroActividadesSeleccionadas = {"activos"};
  final PlansService _plansService = PlansService();
  final List<String> categorias = categoriasMap.keys.toList();
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

  int _activeFiltersCount() {
    int count = 0;
    if (filtroDistancia != null) count++;
    if (filtroFecha != null) count++;
    if (filtroEstadosSeleccionadas.isNotEmpty) count++;
    if (filtroVisibilidades.isNotEmpty) count++;
    if (filtroActividadesSeleccionadas.isNotEmpty && !(filtroActividadesSeleccionadas.length == 1 && filtroActividadesSeleccionadas.contains("activos"))) count++;
    if (categoriasSeleccionadas.isNotEmpty) count++;
    return count;
  }

  void _showFiltroModal() {
    double? tempDist = filtroDistancia;
    String? tempFecha = filtroFecha;
    final Set<String> tempEstados = Set<String>.from(filtroEstadosSeleccionadas);
    final Set<String> tempVisibilidades = Set<String>.from(filtroVisibilidades);
    final Set<String> tempActividades = Set<String>.from(filtroActividadesSeleccionadas);
    final Set<String> tempCategorias = Set<String>.from(categoriasSeleccionadas);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    "Filtros",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Distancia", style: Theme.of(context).textTheme.titleMedium),
                  RadioListTile<double?>(
                    title: const Text("Menos de 5 km"),
                    value: 5.0,
                    groupValue: tempDist,
                    onChanged: (v) => setStateModal(() {
                      tempDist = (tempDist == v) ? null : v;
                    }),
                  ),
                  RadioListTile<double?>(
                    title: const Text("Menos de 10 km"),
                    value: 10.0,
                    groupValue: tempDist,
                    onChanged: (v) => setStateModal(() {
                      tempDist = (tempDist == v) ? null : v;
                    }),
                  ),
                  RadioListTile<double?>(
                    title: const Text("Menos de 20 km"),
                    value: 20.0,
                    groupValue: tempDist,
                    onChanged: (v) => setStateModal(() {
                      tempDist = (tempDist == v) ? null : v;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text("Fecha", style: Theme.of(context).textTheme.titleMedium),
                  RadioListTile<String?>(
                    title: const Text("Hoy"),
                    value: "hoy",
                    groupValue: tempFecha,
                    onChanged: (v) => setStateModal(() {
                      tempFecha = (tempFecha == v) ? null : v;
                    }),
                  ),
                  RadioListTile<String?>(
                    title: const Text("Esta semana"),
                    value: "semana",
                    groupValue: tempFecha,
                    onChanged: (v) => setStateModal(() {
                      tempFecha = (tempFecha == v) ? null : v;
                    }),
                  ),
                  RadioListTile<String?>(
                    title: const Text("Este mes"),
                    value: "mes",
                    groupValue: tempFecha,
                    onChanged: (v) => setStateModal(() {
                      tempFecha = (tempFecha == v) ? null : v;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text("Visibilidad", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["Amigos", "Público"].map((e) {
                      final selected = tempVisibilidades.contains(e);
                      return FilterChip(
                        label: Text(e),
                        selected: selected,
                        onSelected: (sel) => setStateModal(() {
                          if (sel) tempVisibilidades.add(e);
                          else tempVisibilidades.remove(e);
                        }),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: selected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text("Estado", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["aceptado", "rechazado"].map((e) {
                      final label = e == "aceptado" ? "Aceptados" : "Rechazados";
                      final selected = tempEstados.contains(e);
                      return FilterChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (sel) => setStateModal(() {
                          if (sel) tempEstados.add(e);
                          else tempEstados.remove(e);
                        }),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: selected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text("Actividad", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["activos", "inactivos"].map((e) {
                      final label = e == "activos" ? "Activos" : "Inactivos";
                      final selected = tempActividades.contains(e);
                      return FilterChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (sel) => setStateModal(() {
                          if (sel) tempActividades.add(e);
                          else tempActividades.remove(e);
                        }),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: selected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text("Categorías", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categorias.map((cat) {
                      return FilterChip(
                        label: Text(cat),
                        selected: tempCategorias.contains(cat),
                        onSelected: (selected) => setStateModal(() {
                          if (selected) tempCategorias.add(cat);
                          else tempCategorias.remove(cat);
                        }),
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: tempCategorias.contains(cat)
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          filtroDistancia = null;
                          filtroFecha = null;
                            filtroEstadosSeleccionadas.clear();
                            filtroVisibilidades.clear();
                            filtroActividadesSeleccionadas = {"activos"};
                            categoriasSeleccionadas.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: Text("Limpiar todo", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface))
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: FilledButton(
                      onPressed: () {
                        setState(() {
                            filtroDistancia = tempDist;
                            filtroFecha = tempFecha;
                            filtroEstadosSeleccionadas = Set<String>.from(tempEstados);
                            filtroVisibilidades = Set<String>.from(tempVisibilidades);
                            filtroActividadesSeleccionadas = Set<String>.from(tempActividades);
                            categoriasSeleccionadas = Set<String>.from(tempCategorias);
                          });
                        Navigator.pop(context);
                      },
                      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                      child: Text("Aplicar", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSecondary)),
                    )),
                  ]),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
        },
        );
      },
    );
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
      List<String> amigosIDs = [];
      print("[🐧 planes] Recuperando amigos de la base de datos...");
      final amigosSnapshot = await db
        .collection("users")
        .doc(widget.userID)
        .collection("friends")
        .get();
      amigosIDs = amigosSnapshot.docs.map((doc) => doc.id).toList();

      List<Map<String, dynamic>> planes = [];

      if (viewMode == "descubrir") {
        final amigosPlanes = await _plansService.getPlans(
          userId: widget.userID,
          visibilidad: "Amigos",
          friendIds: amigosIDs,
          forceRefresh: forceRefresh,
        );
        final publicoPlanes = await _plansService.getPlans(
          userId: widget.userID,
          visibilidad: "Público",
          friendIds: [],
          forceRefresh: forceRefresh,
        );

        final Map<String, Map<String, dynamic>> byId = {};
        for (var p in amigosPlanes) {
          final id = p["planID"] ?? p["id"] ?? "";
          if (id != "") byId[id] = p;
        }
        for (var p in publicoPlanes) {
          final id = p["planID"] ?? p["id"] ?? "";
          if (id != "" && !byId.containsKey(id)) byId[id] = p;
        }
        planes = byId.values.toList();
      } else if (viewMode == "aceptados") {
        final amigosPlanes = await _plansService.getPlans(
          userId: widget.userID,
          visibilidad: "Amigos",
          friendIds: amigosIDs,
          forceRefresh: forceRefresh,
        );
        final publicoPlanes = await _plansService.getPlans(
          userId: widget.userID,
          visibilidad: "Público",
          friendIds: [],
          forceRefresh: forceRefresh,
        );

        final Map<String, Map<String, dynamic>> byId = {};
        for (var p in amigosPlanes) {
          final id = p["planID"] ?? p["id"] ?? "";
          if (id != "") byId[id] = p;
        }
        for (var p in publicoPlanes) {
          final id = p["planID"] ?? p["id"] ?? "";
          if (id != "" && !byId.containsKey(id)) byId[id] = p;
        }
        planes = byId.values.toList();
      } else {
        planes = await _plansService.getPlans(
          userId: widget.userID,
          visibilidad: "Público",
          friendIds: amigosIDs,
          forceRefresh: forceRefresh,
        );
      }

      setState(() {
        _allPlans = planes;
        _isLoadingFromCache = false;
        _hasConnectionError = false;
      });

      print("[🐧 planes] Planes cargados: ${planes.length}");
    } catch (error, stackTrace) {
      print("[🐧 planes] Error: $error");
      print("[🐧 planes] Error: $stackTrace");
      
      final isNetworkError = error.toString().contains("network") ||
                            error.toString().contains("connection") ||
                            error.toString().contains("Failed host lookup");
      
      setState(() {
        _isLoadingFromCache = false;
        _hasConnectionError = isNetworkError;
        _errorMessage = isNetworkError 
            ? "Sin conexión. Mostrando datos guardados."
            : "Error al cargar planes.";
      });
      
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
    final Position? pos = widget.currentLocation ?? currentPosition;
    
    final planesFiltrados = _allPlans.where((plan) {
      final fechaEsEncuesta = plan["fechaEsEncuesta"] ?? false;
      DateTime? planFecha;
      if (!fechaEsEncuesta) {
        planFecha = plan["fecha"] is Timestamp ? (plan["fecha"] as Timestamp).toDate() : DateTime.tryParse(plan["fecha"]?.toString() ?? "");
      }

      final bool isActive = (fechaEsEncuesta == true) || (planFecha != null && planFecha.isAfter(now));

      if (filtroActividadesSeleccionadas.isNotEmpty) {
        final containsAct = filtroActividadesSeleccionadas.contains("activos");
        final containsInact = filtroActividadesSeleccionadas.contains("inactivos");
        if (containsAct && !containsInact) {
          if (!isActive) return false;
        } else if (containsInact && !containsAct) {
          if (isActive) return false;
        }
      }
      
      if (filtroFecha != null) {
        if (planFecha == null) return false;

        bool enRango = false;
        if (filtroFecha == "hoy") {
          final startOfDay = DateTime(now.year, now.month, now.day);
          final endOfDay = startOfDay.add(const Duration(days: 1));
          enRango = planFecha.isAfter(startOfDay.subtract(const Duration(milliseconds: 1))) && planFecha.isBefore(endOfDay);
        } else if (filtroFecha == "semana") {
          final proximoLunes = now.add(Duration(days: (8 - now.weekday) % 7));
          enRango = planFecha.isAfter(now) && planFecha.isBefore(proximoLunes.add(const Duration(days: 7)));
        } else if (filtroFecha == "mes") {
          final finMes = DateTime(now.year, now.month + 1, 0);
          enRango = planFecha.isAfter(now) && planFecha.isBefore(finMes);
        } else if (filtroFecha == "proximoMes") {
          final initProx = DateTime(now.year, now.month + 1, 1);
          final finProx = DateTime(now.year, now.month + 2, 0);
          enRango = planFecha.isAfter(initProx) && planFecha.isBefore(finProx);
        }
        if (!enRango) return false;
      }
      
      // SEARCH
      if (busqueda.isNotEmpty) {
        final titulo = (plan["titulo"] ?? "").toString().toLowerCase();
        final anfitrion = (plan["anfitrionNombre"] ?? "").toString().toLowerCase();
        if (!titulo.contains(busqueda.toLowerCase()) && !anfitrion.contains(busqueda.toLowerCase())) return false;
      }
      
      // CATEGORY
      if (categoriasSeleccionadas.isNotEmpty) {
        final cat = plan["categoria"] as String?;
        if (cat == null || !categoriasSeleccionadas.contains(cat)) return false;
      }

      // If user selected "Planes aceptados", only include plans where the user is in participantesAceptados
      if (viewMode == "aceptados") {
        final aceptados = plan["participantesAceptados"];
        bool isAccepted = false;
        if (aceptados is List) {
          try {
            if (aceptados.map((e) => e.toString()).contains(widget.userID)) isAccepted = true;
          } catch (_) {}
        } else if (aceptados is String) {
          final parts = aceptados.split(",").map((s) => s.trim()).where((s) => s.isNotEmpty);
          if (parts.contains(widget.userID)) isAccepted = true;
        }
        if (!isAccepted) return false;
      }

      // Estado filter (multi-select): if any estado selected, require plan to match at least one
      if (filtroEstadosSeleccionadas.isNotEmpty) {
        bool matchesEstado = false;
        if (filtroEstadosSeleccionadas.contains("rechazado")) {
          final rechazados = plan["participantesRechazados"];
          bool isRejected = false;
          if (rechazados is List) {
            try {
              if (rechazados.map((e) => e.toString()).contains(widget.userID)) isRejected = true;
            } catch (_) {}
          } else if (rechazados is String) {
            final parts = rechazados.split(",").map((s) => s.trim()).where((s) => s.isNotEmpty);
            if (parts.contains(widget.userID)) isRejected = true;
          }
          if (isRejected) matchesEstado = true;
        }
        if (filtroEstadosSeleccionadas.contains("aceptado")) {
          final aceptados = plan["participantesAceptados"];
          bool isAccepted = false;
          if (aceptados is List) {
            try {
              if (aceptados.map((e) => e.toString()).contains(widget.userID)) isAccepted = true;
            } catch (_) {}
          } else if (aceptados is String) {
            final parts = aceptados.split(",").map((s) => s.trim()).where((s) => s.isNotEmpty);
            if (parts.contains(widget.userID)) isAccepted = true;
          }
          if (isAccepted) matchesEstado = true;
        }
        if (!matchesEstado) return false;
      }

      // VISIBILIDAD (Amigos / Público) - multi-select
      if (filtroVisibilidades.isNotEmpty) {
        final vis = plan["visibilidad"] as String?;
        if (vis == null) return false;
        if (!filtroVisibilidades.contains(vis)) return false;
      }
      
      // DISTANCE
      if (filtroDistancia != null && pos != null) {
        final ubi = plan["ubicacion"];
        if (plan["ubicacionEsEncuesta"] != true && ubi is Map<String, dynamic>) {
          // robust parsing for lat/lng
          double? lat;
          double? lng;
          final rawLat = ubi["latitud"];
          final rawLng = ubi["longitud"];
          if (rawLat is double) lat = rawLat;
          else if (rawLat is int) lat = rawLat.toDouble();
          else if (rawLat is String) lat = double.tryParse(rawLat.replaceAll(",", "."));

          if (rawLng is double) lng = rawLng;
          else if (rawLng is int) lng = rawLng.toDouble();
          else if (rawLng is String) lng = double.tryParse(rawLng.replaceAll(",", "."));

          if (lat != null && lng != null) {
            final dist = Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
            // debug log to help trace unexpected results (include parsed coords and ref location)
            print("[🐧 planes] filtroDistancia=${filtroDistancia}km plan=${plan["planID"] ?? plan["id"] ?? ""} dist=${(dist/1000).toStringAsFixed(2)}km (planLat=$lat planLng=$lng refLat=${pos.latitude} refLng=${pos.longitude})");
            if (dist > (filtroDistancia! * 1000)) return false;
          } else {
            // If lat/lng cannot be parsed, exclude the plan to be safe
            return false;
          }
        } else {
          return false;
        }
      }
      
      return true;
    }).toList();

    //ORDENAR POR DISTANCIA
    if (pos != null) {
      planesFiltrados.sort((a, b) {
        double distanciaA = double.infinity;
        double distanciaB = double.infinity;
        
        //DISTANCIA A
        final ubicacionA = a["ubicacion"];
        if (a["ubicacionEsEncuesta"] != true && ubicacionA != null && ubicacionA is Map<String, dynamic>) {
          final rawLat = ubicacionA["latitud"];
          final rawLng = ubicacionA["longitud"];
          final latDouble = (rawLat is double)
            ? rawLat
            : (rawLat is int)
              ? rawLat.toDouble()
              : (rawLat != null ? double.tryParse(rawLat.toString().replaceAll(",", ".")) : null);
          final lngDouble = (rawLng is double)
            ? rawLng
            : (rawLng is int)
              ? rawLng.toDouble()
              : (rawLng != null ? double.tryParse(rawLng.toString().replaceAll(",", ".")) : null);
          if (latDouble != null && lngDouble != null) {
            distanciaA = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              latDouble,
              lngDouble,
            );
          }
        }
        
        //DISTANCIA B
        final ubicacionB = b["ubicacion"];
        if (b["ubicacionEsEncuesta"] != true && ubicacionB != null && ubicacionB is Map<String, dynamic>) {
          final rawLat = ubicacionB["latitud"];
          final rawLng = ubicacionB["longitud"];
          final latDouble = (rawLat is double)
            ? rawLat
            : (rawLat is int)
              ? rawLat.toDouble()
              : (rawLat != null ? double.tryParse(rawLat.toString().replaceAll(",", ".")) : null);
          final lngDouble = (rawLng is double)
            ? rawLng
            : (rawLng is int)
              ? rawLng.toDouble()
              : (rawLng != null ? double.tryParse(rawLng.toString().replaceAll(",", ".")) : null);
          if (latDouble != null && lngDouble != null) {
            distanciaB = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
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
                          _errorMessage ?? "Sin conexión",
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
                  segments: const [
                    ButtonSegment(value: "descubrir", label: Text("Descubrir")),
                    ButtonSegment(value: "aceptados", label: Text("Planes aceptados")),
                  ],
                  selected: <String>{viewMode},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) return;
                    setState(() {
                      viewMode = selection.first;
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

              const SizedBox(height: 12),

              //BUSCADOR
              Padding(
                padding: const EdgeInsets.only(top: 0),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              //FILTROS
              Row(
                children: [
                  Builder(builder: (context) {
                    final activeCount = _activeFiltersCount();
                    return FilledButton.icon(
                      onPressed: () => _showFiltroModal(),
                      icon: const Icon(Icons.filter_list),
                      label: Text(activeCount > 0 ? "Filtros ($activeCount)" : "Filtros"),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const SizedBox(width: 2),
                          FilterChip(
                            label: const Text("Amigos"),
                            selected: filtroVisibilidades.contains("Amigos"),
                            onSelected: (sel) {
                              setState(() {
                                if (sel) filtroVisibilidades.add("Amigos");
                                else filtroVisibilidades.remove("Amigos");
                              });
                            },
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: filtroVisibilidades.contains("Amigos")
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                            ),
                            showCheckmark: false,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text("Esta semana"),
                            selected: filtroFecha == "semana",
                            onSelected: (sel) {
                              setState(() {
                                filtroFecha = (sel) ? "semana" : null;
                              });
                            },
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: filtroFecha == "semana"
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                            ),
                            showCheckmark: false,
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            label: const Text("Menos de 5 km"),
                            selected: filtroDistancia == 5.0,
                            onSelected: (sel) {
                              setState(() {
                                filtroDistancia = (sel) ? 5.0 : null;
                              });
                            },
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: filtroDistancia == 5.0
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                            ),
                            showCheckmark: false,
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

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
                                  if (result == "deleted" || result == "participation_changed") {
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
