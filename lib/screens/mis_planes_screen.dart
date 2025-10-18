import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:quedamos/screens/add_planes_screen.dart';
import '../widgets/plan_list.dart';
import '../app_colors.dart';
import '../text_styles.dart';

//MIS PLANES SCREEN
class MisPlanesScreen extends StatefulWidget {
  final String userID;
  const MisPlanesScreen({super.key, required this.userID});

  @override
  State<MisPlanesScreen> createState() => _MisPlanesScreenState();
}

//MIS PLANES SCREEN STATE
class _MisPlanesScreenState extends State<MisPlanesScreen> {
  String selectedSegment = 'Amigos';
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

  //OBTENER PLANES
  Future<void> _fetchPage(int pageKey) async {
    //CONSULTA A LA BASE DE DATOS
    print("[🐧 planes] Recuperando planes de la base de datos...");
    final snapshot = await db.collection("planes").get();;
    // Convertir los docs en Map<String, dynamic>
    final planes = snapshot.docs.map((doc) {
      final data = doc.data();
      // Si quieres incluir el id:
      data['id'] = doc.id;
      return data;
    }).toList();
    print("[planes] Fetching page starting at index: $pageKey"); 
    try {
      //FILTRO
      final filteredPlanes = planes.where((plan) {
        final visibilidad = (plan['visibilidad'] ?? "").toLowerCase();
        final titulo = (plan['titulo'] ?? "").toLowerCase();
        final anfitrionNombre = (plan['anfitrionNombre'] ?? "").toLowerCase();
        final query = searchQuery.toLowerCase();
        return visibilidad == selectedSegment.toLowerCase() &&
            (titulo.contains(query) || anfitrionNombre.contains(query));
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
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userID = widget.userID;
    print("UID del usuario -> ${widget.userID}");
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
                    hintText: 'Buscar planes...',
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddPlanesScreen(userID: userID,)),
                    );
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
                    itemBuilder: (context, plan, index) => PlanesList(plan: plan, userID: userID,),
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
