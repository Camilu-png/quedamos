import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:infinite_scroll_pagination/infinite_scroll_pagination.dart";
import "package:quedamos/main.dart";
import "package:quedamos/app_colors.dart";
import "package:quedamos/text_styles.dart";
import "package:quedamos/widgets/planes_list.dart";
import "package:quedamos/screens/planes/plan_screen.dart";

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

  String selectedSegment = "Amigos";
  String searchQuery = "";

  static const int _pageSize = 3; //Planes por página

  //PAGING CONTROLLER
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

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

  //INIT STATE
  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  //REFRESH PAGING
  void _refreshPaging() {
    print("[🐧 planes] Refrescando paginación..."); 
    _pagingController.refresh();
  }

  //OBTENER PLANES
  Future<void> _fetchPage(int pageKey) async {
    print("[🐧 planes] Recuperando planes de la base de datos...");
    final snapshot = await db.collection("planes").get();;
    final planes = snapshot.docs.map((doc) {
      final data = doc.data();
      data["id"] = doc.id;
      return data;
    }).toList();
    print("[🐧 planes] Fetching page starting at index: $pageKey"); 
    try {
      //FILTRO
      final filteredPlanes = planes.where((plan) {
        final visibilidad = (plan["visibilidad"] ?? "").toLowerCase();
        final anfitrionID = plan["anfitrionID"] ?? "";
        final anfitrionNombre = (plan["anfitrionNombre"] ?? "").toLowerCase();
        final titulo = (plan["titulo"] ?? "").toLowerCase();
        final query = searchQuery.toLowerCase();
        return
          visibilidad == selectedSegment.toLowerCase() &&
          (titulo.contains(query) || anfitrionNombre.contains(query)) &&
          anfitrionID != widget.userID; //Planes ajenos al usuario
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

  @override
  Widget build(BuildContext context) {
    print("[🐧 planes] UID del usuario: ${widget.userID}");
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Planes", style: titleText),
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
              //SEGMENTED BUTTON
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: "Amigos", label: Text("Amigos", style: helpText)),
                    ButtonSegment(value: "Público", label: Text("Público", style: helpText)),
                  ],
                  selected: <String>{selectedSegment},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      selectedSegment = newSelection.first;
                      _refreshPaging();
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white,
                    selectedBackgroundColor: primaryLight,
                    foregroundColor: primaryDark,
                    selectedForegroundColor: primaryDark,
                    side: const BorderSide(color: primaryDark, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

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
