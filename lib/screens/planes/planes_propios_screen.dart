import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:quedamos/main.dart";
import 'package:geolocator/geolocator.dart';
import "package:quedamos/screens/planes/planes_list.dart";
import "package:quedamos/screens/planes/plan_screen.dart";

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

  static const int _pageSize = 25;

  //INIT STATE
  @override
  void initState() {
    super.initState();
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
  Future<void> _fetchPage(int pageKey) async {
    print("[🐧 planes] Recuperando planes de la base de datos, página: $pageKey");
    try {
      Query query = db.collection("planes")
        .where("anfitrionID", isEqualTo: widget.userID)
        .limit(_pageSize);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      final snapshot = await query.get();
      final planes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data["id"] = doc.id;
        return data;
      }).toList();
      //FILTRO
      final now = DateTime.now();
      final planesFiltrados = planes.where((plan) {
        //FECHA
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
        final titulo = (plan["titulo"] ?? "").toString().toLowerCase();
        final anfitrionNombre = (plan["anfitrionNombre"] ?? "").toString().toLowerCase();
        final queryText = busqueda.toLowerCase();
        return titulo.contains(queryText) || anfitrionNombre.contains(queryText);
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
      //PAGINACIÓN
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

    final userID = widget.userID;
    print("[🐧 planes] UID del usuario: ${userID}");
    
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
                        userID: userID,
                        currentLocation: widget.currentLocation,
                        onTapOverride: (ctx, planData) async {
                          final result = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlanScreen(plan: planData, userID: userID, currentLocation: widget.currentLocation)));
                          if (result == 'deleted') {
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
