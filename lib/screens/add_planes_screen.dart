import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../text_styles.dart';

final List<IconData> iconosDisponibles = [
  Icons.event,
  Icons.star,
  Icons.home,
  Icons.work,
  Icons.favorite,
  Icons.sports_soccer,
  Icons.coffee,
  Icons.restaurant,
  Icons.flight,
  Icons.music_note,
  Icons.movie,
  Icons.book,
  Icons.pets,
  Icons.shopping_cart,
  Icons.local_cafe,
  Icons.beach_access,
];

final List<Color> coloresDisponibles = [
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.indigo,
  Colors.pink,
  Colors.amber,
  Colors.cyan,
  Colors.lime,
  Colors.deepOrange,
  Colors.deepPurple,
  Colors.lightBlue,
  Colors.lightGreen,
  secondary, // tu color secundario
  primaryColor, // tu color principal
];

class AddPlanesScreen extends StatefulWidget {
  final Map<String, dynamic>? plan;

  const AddPlanesScreen({super.key, this.plan});

  @override
  State<AddPlanesScreen> createState() => _AddPlanesScreenState();
}

class _AddPlanesScreenState extends State<AddPlanesScreen> {
  final _formKey = GlobalKey<FormState>();

  //ICONO
  IconData selectedIcon = Icons.event;
  Color selectedColor = secondary;
  //VISIBILIDAD
  String selectedSegment = 'Amigos';
  //TÍTULO
  final TextEditingController _tituloController = TextEditingController();
  //DESCRIPCIÓN
  final TextEditingController _descripcionController = TextEditingController();
  //FECHA
  bool fechaEsEncuesta = false;
  DateTime? fechaSeleccionada;
  List<DateTime> encuestaFechas = [];

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _tituloController.text = widget.plan!["titulo"] ?? '';
      _descripcionController.text = widget.plan!["descripcion"] ?? '';
      selectedSegment = widget.plan!["visibilidad"] ?? 'Amigos';
      //CARGAR FECHA O ENCUESTA
      fechaEsEncuesta = widget.plan!["fechaEsEncuesta"] ?? false;
      if (fechaEsEncuesta) {
        encuestaFechas = widget.plan!["encuestaFechas"] != null
            ? List<DateTime>.from(widget.plan!["encuestaFechas"])
            : [];
      } else {
        fechaSeleccionada = widget.plan!["fechaSeleccionada"];
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  //ICONO: MODAL
  void _abrirSelectorIconoColor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: SizedBox(
            height: 500,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: "Icono"),
                    Tab(text: "Color"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      //PESTAÑA: ICONO
                      GridView.count(
                        crossAxisCount: 4,
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (var icon in iconosDisponibles)
                            GestureDetector(
                              onTap: () {
                                setState(() => selectedIcon = icon);
                                Navigator.pop(context);
                              },
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selectedIcon == icon ? primaryColor : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, size: 40),
                              ),
                            ),
                        ],
                      ),
                      //PESTAÑA: COLOR
                      GridView.count(
                        crossAxisCount: 4,
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (var color in coloresDisponibles)
                            GestureDetector(
                              onTap: () {
                                setState(() => selectedColor = color);
                                Navigator.pop(context);
                              },
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(
                                    color: selectedColor == color ? primaryColor : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //FECHA: NORMAL
  void _seleccionarFechaNormal(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
      });
    }
  }

  //FECHA: ENCUESTA
  void _agregarFechaEncuesta(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        encuestaFechas.add(picked);
      });
    }
  }

  //FORMATO: FECHA
  String formatoFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      //APP BAR
      appBar: AppBar(
        title: Text(
          widget.plan != null ? "Editar plan" : "Nuevo plan",
          style: subtitleText.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //ICONO
            GestureDetector(
              onTap: () => _abrirSelectorIconoColor(context),
              child: Container(
                width: double.infinity,
                height: 120,
                color: selectedColor,
                alignment: Alignment.center,
                child: Icon(selectedIcon, color: Colors.white, size: 60),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    //VISIBILIDAD
                    Text(
                      "Visibilidad",
                      style: labelText,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                              value: 'Amigos', label: Text('Amigos', style: helpText)),
                          ButtonSegment(
                              value: 'Público', label: Text('Público', style: helpText)),
                        ],
                        selected: <String>{selectedSegment},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            selectedSegment = newSelection.first;
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

                    // TÍTULO
                    Text(
                      "Título",
                      style: labelText,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _tituloController,
                      maxLength: 250,
                      decoration: InputDecoration(
                        hintText: "Ingresa un título",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, ingresa un título";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // DESCRIPCIÓN
                    Text(
                      "Descripción",
                      style: labelText,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _descripcionController,
                      maxLength: 1000,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: "Ingresa una descripción",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    //FECHA
                    Text(
                      "Fecha",
                      style: labelText,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        //BOTÓN: INPUT FECHA
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (fechaEsEncuesta) {
                                _agregarFechaEncuesta(context);
                              } else {
                                _seleccionarFechaNormal(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryText,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: secondaryText,
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                fechaEsEncuesta
                                    ? 'Agregar opción de encuesta'
                                    : (fechaSeleccionada != null
                                        ? formatoFecha(fechaSeleccionada!)
                                        : 'Toca para elegir fecha'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON (FECHA/ENCUESTA)
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'fecha', label: Icon(Icons.calendar_today)),
                              ButtonSegment(value: 'encuesta', label: Icon(Icons.poll)),
                            ],
                            selected: {fechaEsEncuesta ? 'encuesta' : 'fecha'},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                fechaEsEncuesta = newSelection.first == 'encuesta';
                              });
                            },
                            style: SegmentedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    //FECHA: OPCIONES DE ENCUESTA
                    if (fechaEsEncuesta && encuestaFechas.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < encuestaFechas.length; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Opción ${i + 1}: ${formatoFecha(encuestaFechas[i])}',
                                    style: bodyPrimaryText.copyWith(
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        encuestaFechas.removeAt(i);
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 24, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),


                    //BOTÓN: GUARDAR
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final nuevoPlan = {
                              "titulo": _tituloController.text,
                              "descripcion": _descripcionController.text,
                              "visibilidad": selectedSegment,
                              "fechaEsEncuesta": fechaEsEncuesta,
                              "fechaSeleccionada": fechaSeleccionada,
                              "encuestaFechas": encuestaFechas,
                            };
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  widget.plan != null ? "Plan editado" : "Plan guardado",
                                ),
                              ),
                            );
                            Navigator.pop(context, nuevoPlan);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Guardar",
                          style: bodyPrimaryText.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
