import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:quedamos/main.dart";
import "package:quedamos/screens/planes/planes_components.dart";
import "package:quedamos/widgets/planes_list.dart";
import "package:quedamos/screens/planes/plan_screen.dart";
import "package:quedamos/screens/planes/plan_add_screen.dart";

final db = FirebaseFirestore.instance;

//PLANES SCREEN
class PlanesScreen extends StatefulWidget {
  final String userID;
  const PlanesScreen({super.key, required this.userID});
  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

//PLANES SCREEN STATE
class _PlanesScreenState extends State<PlanesScreen> with RouteAware {

  String visibilidadSelected = "Amigos";
  String busqueda = "";

  static const int _pageSize = 3;

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
      List<String> amigosIDs = [];
      if (visibilidadSelected == "Amigos") {
        final amigosSnapshot = await db
            .collection("users")
            .doc(widget.userID)
            .collection("friends")
            .get();
        amigosIDs = amigosSnapshot.docs.map((doc) => doc.id).toList();
      }
      Query query = db.collection("planes")
          .where("visibilidad", isEqualTo: visibilidadSelected)
          .orderBy("titulo")
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
      final planesFiltrados = planes.where((plan) {
        final titulo = (plan["titulo"] ?? "").toLowerCase();
        final anfitrionNombre = (plan["anfitrionNombre"] ?? "").toLowerCase();
        final queryText = busqueda.toLowerCase();
        final anfitrionID = plan["anfitrionID"] ?? "";
        final fechaEsEncuesta = plan["fechaEsEncuesta"] ?? false;
        final fecha = !fechaEsEncuesta
          ? plan["fecha"].toDate() ?? DateTime.now()
          : DateTime.now();
        final horaEsEncuesta = plan["horaEsEncuesta"] ?? false;
        final hora = !horaEsEncuesta
          ? stringToTimeOfDay(plan["hora"]) ?? TimeOfDay.fromDateTime(DateTime.now())
          : TimeOfDay.fromDateTime(DateTime.now());
        final fechaHora = !fechaEsEncuesta && !horaEsEncuesta
          ? DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute)
          : DateTime.now();
        if (visibilidadSelected == "Amigos") {
          return plan["visibilidad"] == "Amigos" &&
                amigosIDs.contains(anfitrionID) &&
                anfitrionID != widget.userID &&
                (fechaEsEncuesta || horaEsEncuesta || (!fechaEsEncuesta && !horaEsEncuesta && fechaHora.isAfter(DateTime.now()))) &&
                (titulo.contains(queryText) || anfitrionNombre.contains(queryText));
        } else if (visibilidadSelected == "Público") {
          return plan["visibilidad"] == "Público" &&
                anfitrionID != widget.userID &&
                (fechaEsEncuesta || horaEsEncuesta || (!fechaEsEncuesta && !horaEsEncuesta && fechaHora.isAfter(DateTime.now()))) &&
                (titulo.contains(queryText) || anfitrionNombre.contains(queryText));
        }
        return false;
      }).toList();
      if (planesFiltrados.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }
      final isLastPage = planesFiltrados.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(planesFiltrados);
      } else {
        _pagingController.appendPage(planesFiltrados, pageKey + _pageSize);
      }
    } catch (error) {
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
        //NUEVO PLAN
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final newPlanID = await Navigator.push<String?>(
              context,
              MaterialPageRoute(
                  builder: (context) => AddPlanScreen(userID: widget.userID)),
            );
            if (newPlanID != null) _refreshPaging();
          },
          icon: const Icon(Icons.add),
          label: const Text("Nuevo plan"),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
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
                padding: const EdgeInsets.only(top: 16),
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
                      onTapOverride: (ctx, planData) async {
                        final result = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlanScreen(plan: planData, userID: widget.userID)));
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
