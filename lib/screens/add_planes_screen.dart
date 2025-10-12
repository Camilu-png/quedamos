import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../widgets/plan_list.dart';
import '../app_colors.dart';
import '../text_styles.dart';

class AddPlanesScreen extends StatefulWidget {
  const AddPlanesScreen({super.key});

  @override
  State<AddPlanesScreen> createState() => _AddPlanesScreenState();
}

class _AddPlanesScreenState extends State<AddPlanesScreen> {
  String selectedSegment = 'Amigos';
  String searchQuery = "";

  static const int _pageSize = 3; //Planes por página

  //PAGING CONTROLLER
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);

  //MOCK
  final List<Map<String, dynamic>> planes = List.generate(30, (index) {
    final colores = [
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.red,
      Colors.indigo,
      Colors.brown,
    ];

    final iconos = [
      Icons.self_improvement,
      Icons.set_meal,
      Icons.brush,
      Icons.movie,
      Icons.directions_bike,
      Icons.music_note,
      Icons.sports_soccer,
      Icons.park,
    ];

    final titulos = [
      "Caminata en el cerro",
      "Tarde de picnic",
      "Clase de yoga al aire libre",
      "Cine bajo las estrellas",
      "Tour gastronómico",
      "Taller de pintura para niños",
      "Paseo en bicicleta",
      "Concierto acústico",
    ];

    final anfitriones = [
      "Carlos López",
      "María Pérez",
      "José Martínez",
      "Ana Gómez",
      "Luis Fernández",
      "Camila Rojas",
      "Ricardo Torres",
      "Valentina Rodríguez",
    ];

    final ubicaciones = [
      "Parque Metropolitano",
      "Parque Bicentenario",
      "Parque Forestal",
      "Plaza Ñuñoa",
      "Barrio Lastarria",
      "Museo de Bellas Artes",
      "Ciclovías Santiago Centro",
      "Café Literario",
    ];

    final visibilidades = ["Amigos", "Público"];

    return {
      "anfitrion": anfitriones[index % anfitriones.length],
      "titulo": titulos[index % titulos.length] + " #${index + 1}",
      "fecha": "${10 + (index % 20)} de octubre",
      "hora": "${8 + (index % 12)}:00 ${index % 2 == 0 ? 'AM' : 'PM'}",
      "ubicacion": ubicaciones[index % ubicaciones.length],
      "iconColor": colores[index % colores.length],
      "iconCode": iconos[index % iconos.length].codePoint,
      "visibilidad": visibilidades[index % visibilidades.length],
      "descripcion": "Únete a este plan para disfrutar de una experiencia única en ${ubicaciones[index % ubicaciones.length]}. ¡No te lo pierdas!",
      "esPropio": true,
      "encuesta": true,
    };
  });


  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  //OBTENER PLANES
  Future<void> _fetchPage(int pageKey) async {
    print("[planes] Fetching page starting at index: $pageKey"); 
    try {
      //FILTRO
      final filteredPlanes = planes.where((plan) {
        final visibilidad = (plan['visibilidad'] ?? "").toLowerCase();
        final titulo = (plan['titulo'] ?? "").toLowerCase();
        final anfitrion = (plan['anfitrion'] ?? "").toLowerCase();
        final query = searchQuery.toLowerCase();
        return visibilidad == selectedSegment.toLowerCase() &&
            (titulo.contains(query) || anfitrion.contains(query));
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
                    //ACCIÓN
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
                    itemBuilder: (context, plan, index) => PlanesList(plan: plan),
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
