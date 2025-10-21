import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:quedamos/main.dart";
import "package:quedamos/screens/planes/planes_components.dart";
import "package:quedamos/widgets/planes_list.dart";
import "package:quedamos/screens/planes/plan_screen.dart";
import "package:quedamos/screens/planes/plan_add_screen.dart";

final db = FirebaseFirestore.instance;

//MIS PLANES SCREEN
class MisPlanesScreen extends StatefulWidget {
  final String userID;
  const MisPlanesScreen({super.key, required this.userID});
  @override
  State<MisPlanesScreen> createState() => _MisPlanesScreenState();
}

//MIS PLANES SCREEN STATE
class _MisPlanesScreenState extends State<MisPlanesScreen> with RouteAware {
  
  String visibilidadSelected = "Amigos";
  String busqueda = "";

  //Quizás acá hay que quitar la paginación...
  static const int _pageSize = 25; //Planes por página

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
        return anfitrionID == 
          widget.userID &&
          (fechaEsEncuesta || horaEsEncuesta || (!fechaEsEncuesta && !horaEsEncuesta && fechaHora.isAfter(DateTime.now()))) &&
          (titulo.contains(queryText) || anfitrionNombre.contains(queryText));
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

              //BUSCADOR
              TextField(
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

              const SizedBox(height: 12),

              //LISTA DE PLANES
              Expanded(
                child: PagedListView<int, Map<String, dynamic>>(
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                      itemBuilder: (context, plan, index) => PlanesList(
                        plan: plan,
                        userID: userID,
                        onTapOverride: (ctx, planData) async {
                          final result = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlanScreen(plan: planData, userID: userID)));
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
