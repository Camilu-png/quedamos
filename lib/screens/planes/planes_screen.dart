import "package:flutter/material.dart";
import 'package:geolocator/geolocator.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:quedamos/main.dart";
import "package:quedamos/screens/planes/planes_list.dart";
import "package:quedamos/screens/planes/plan_screen.dart";

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

  static const int _pageSize = 25;

  //INIT STATE
  @override
  void initState() {
    super.initState();
    currentPosition = widget.currentLocation;
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  //PAGING CONTROLLER
  final PagingController<int, Map<String, dynamic>> _pagingController = PagingController(firstPageKey: 0);

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
    _refreshPaging();
  }

  //DISPOSE
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _pagingController.dispose();
    super.dispose();
  }

  //REFRESH PAGING
  void _refreshPaging() {
    print("[🐧 planes] Refrescando paginación...");
    _lastDocument = null;
    _pagingController.refresh();
  }

  //OBTENER PLANES
  DocumentSnapshot? _lastDocument;
  Position? currentPosition;
  Future<void> _fetchPage(int pageKey) async {
    print("[🐧 planes] Recuperando planes de la base de datos, página: $pageKey");
    try {
      // AMIGOS
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
      // PLANES
      List<Map<String, dynamic>> planes = [];
      //PLANES: AMIGOS
      if (visibilidadSelected == "Amigos" && amigosIDs.isNotEmpty) {
        for (var i = 0; i < amigosIDs.length; i += 10) {
          final batch = amigosIDs.sublist(i, (i + 10 > amigosIDs.length) ? amigosIDs.length : i + 10);
          if (batch.isEmpty) continue;
          Query query = db.collection("planes")
            .where("visibilidad", isEqualTo: "Amigos")
            .where("anfitrionID", whereIn: batch)
            .limit(_pageSize);
          if (_lastDocument != null) query = query.startAfterDocument(_lastDocument!);
          final snapshot = await query.get();
          planes.addAll(snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data["id"] = doc.id;
            return data;
          }).toList());
          if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
        }
      }
      //PLANES: PÚBLICO
      if (visibilidadSelected == "Público") {
        Query query = db.collection("planes")
          .where("visibilidad", isEqualTo: "Público")
          .where("anfitrionID", isNotEqualTo: widget.userID)
          .limit(_pageSize);
        if (_lastDocument != null) query = query.startAfterDocument(_lastDocument!);
        final snapshot = await query.get();
        planes.addAll(snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data["id"] = doc.id;
          return data;
        }).toList());
        if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
      }
      //FILTRO
      final now = DateTime.now();
      final planesFiltrados = planes.where((plan) {
        //FECHA
        final fechaEsEncuesta = plan["fechaEsEncuesta"] ?? false;
        if (!fechaEsEncuesta) {
          final fecha = plan["fecha"] is Timestamp
            ? (plan["fecha"] as Timestamp).toDate()
            : DateTime.tryParse(plan["fecha"]?.toString() ?? "") ?? now;
          if (fecha.isBefore(now)) return false;
        }
        //BÚSQUEDA
        final titulo = (plan["titulo"] ?? "").toString().toLowerCase();
        final anfitrionNombre = (plan["anfitrionNombre"] ?? "").toString().toLowerCase();
        final queryText = busqueda.toLowerCase();
        return titulo.contains(queryText) || anfitrionNombre.contains(queryText);
      }).toList();
      //ORDENAR POR DISTANCIA
      if (currentPosition != null) {
        planesFiltrados.sort((a, b) {
          double distanciaA = double.infinity;
          double distanciaB = double.infinity;
          //DISTANCIA A
          final ubicacionA = a["ubicacion"];
          if (a["ubicacionEsEncuesta"] != true &&
              ubicacionA != null &&
              ubicacionA is Map<String, dynamic>) {
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
          if (b["ubicacionEsEncuesta"] != true &&
              ubicacionB != null &&
              ubicacionB is Map<String, dynamic>) {
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
      // PAGINACIÓN
      final isLastPage = planesFiltrados.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(planesFiltrados);
      } else {
        _pagingController.appendPage(planesFiltrados, pageKey + _pageSize);
      }
    } catch (error, stackTrace) {
      print("[🐧 planes] Error: $error");
      print("[🐧 planes] Error: $stackTrace");
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {

    print("[🐧 planes] UID del usuario: ${widget.userID}");

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
                      _refreshPaging();
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
                      _refreshPaging();
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
                child: PagedListView<int, Map<String, dynamic>>(
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                    itemBuilder: (context, plan, index) => PlanesList(
                      plan: plan,
                      userID: widget.userID,
                      currentLocation: widget.currentLocation,
                      onTapOverride: (ctx, planData) async {
                        final result = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlanScreen(plan: planData, userID: widget.userID, currentLocation: widget.currentLocation)));
                        if (result == "deleted") {
                          if (mounted) _refreshPaging();
                        }
                      },
                    ),
                    noItemsFoundIndicatorBuilder: (_) => const Center(
                      child: Text("No se encontraron planes."),
                    ),
                    firstPageProgressIndicatorBuilder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    newPageProgressIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
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
