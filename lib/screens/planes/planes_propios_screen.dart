import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:quedamos/main.dart";
import "package:quedamos/screens/planes/plan_add_screen.dart";
import "package:quedamos/screens/planes/plan_screen.dart";
import "../../widgets/planes_list.dart";
import "../../app_colors.dart";
import "../../text_styles.dart";

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
  String selectedSegment = "Amigos";
  String searchQuery = "";

  static const int _pageSize = 3; //Planes por página

  //PAGING CONTROLLER
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    _refreshPaging();
  }

  //OBTENER PLANES
  Future<void> _fetchPage(int pageKey) async {
    print("[🐧 planes] Recuperando planes de la base de datos...");
    final snapshot = await db.collection("planes").get();
    final planes = snapshot.docs.map((doc) {
      final data = doc.data();
      data["id"] = doc.id;
      return data;
    }).toList();
    print("[🐧 planes] Fetching page starting at index: $pageKey"); 
    try {
      //FILTRO: mostrar todos los planes cuyo anfitrión es el usuario (independiente de visibilidad)
      final filteredPlanes = planes.where((plan) {
        final anfitrionID = plan["anfitrionID"] ?? "";
        final anfitrionNombre = (plan["anfitrionNombre"] ?? "").toLowerCase();
        final titulo = (plan["titulo"] ?? "").toLowerCase();
        final query = searchQuery.toLowerCase();
        return (titulo.contains(query) || anfitrionNombre.contains(query)) && anfitrionID == widget.userID;
      }).toList();
      final isLastPage = pageKey + _pageSize >= filteredPlanes.length;
      final newItems = filteredPlanes.skip(pageKey).take(_pageSize).toList();
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + _pageSize);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _refreshPaging() {
    _pagingController.refresh();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final userID = widget.userID;
    print("[🐧 planes] UID del usuario: ${userID}");
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Mis planes", style: titleText),
          centerTitle: true,
          backgroundColor: backgroundColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [

              //BUSCADOR
              SizedBox(
                height: 45,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _refreshPaging();
                    });
                  },
                  style: helpText,
                  decoration: InputDecoration(
                    hintText: "Buscar planes...",
                    hintStyle: helpText,
                    prefixIcon: const Icon(Icons.search, color: primaryDark),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryDark, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryDark, width: 1),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              //NUEVO PLAN
              SizedBox(
                height: 45,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final newPlanID = await Navigator.push<String?>(
                      context,
                      MaterialPageRoute(builder: (context) => AddPlanScreen(userID: userID,)),
                    );
                    if (newPlanID != null) {
                      // Si se creó un plan, refrescar la lista
                      _refreshPaging();
                    }
                  },
                  icon: const Icon(Icons.add, size: 24, color: Colors.white),
                  label: Text(
                    "Nuevo plan",
                    style: bodyPrimaryText.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    backgroundColor: secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                        onTapOverride: (ctx, planData) async {
                          final result = await Navigator.push(ctx, MaterialPageRoute(builder: (_) => PlanScreen(plan: planData, userID: userID)));
                          if (result == 'deleted') {
                            if (mounted) _refreshPaging();
                          }
                        },
                      ),
                    noItemsFoundIndicatorBuilder: (_) => const Center(
                      child: Text("No se encontraron planes"),
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
