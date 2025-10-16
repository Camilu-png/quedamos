import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_colors.dart';
import '../text_styles.dart';

final db = FirebaseFirestore.instance;

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
  secondary,
  primaryColor,
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
  DateTime? fecha;
  List<DateTime> fechasEncuesta = [];
  //HORA
  bool horaEsEncuesta = false;
  TimeOfDay? hora;
  List<TimeOfDay> horasEncuesta = [];
  //UBICACIÓN
  bool ubicacionEsEncuesta = false;
  String? ubicacion;
  List<String> ubicacionesEncuesta = [];
  final List<String> ubicacionesDisponibles = [
    "Parque Central",
    "Café de la Esquina",
    "Avenida Principal, Edificio 123, Oficina 45B",
    "Estadio Nacional",
  ];

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
        fechasEncuesta = widget.plan!["fechasEncuesta"] != null
            ? List<DateTime>.from(widget.plan!["fechasEncuesta"])
            : [];
      } else {
        fecha = widget.plan!["fecha"];
      }
      //CARGAR HORA O ENCUESTA
      horaEsEncuesta = widget.plan!["horaEsEncuesta"] ?? false;
      if (horaEsEncuesta) {
        horasEncuesta = widget.plan!["horasEncuesta"] != null
            ? List<TimeOfDay>.from(widget.plan!["horasEncuesta"])
            : [];
      } else {
        hora = widget.plan!["hora"];
      }
      //CARGAR UBICACIÓN O ENCUESTA
      ubicacionEsEncuesta = widget.plan!["ubicacionEsEncuesta"] ?? false;
      if (ubicacionEsEncuesta) {
        ubicacionesEncuesta = widget.plan!["ubicacionesEncuesta"] != null
            ? List<String>.from(widget.plan!["ubicacionesEncuesta"])
            : [];
      } else {
        ubicacion = widget.plan!["ubicacion"];
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String _timeOfDayToString(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
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
      initialDate: fecha ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        fecha = picked;
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
        fechasEncuesta.add(picked);
      });
    }
  }

  // HORA NORMAL
  void _seleccionarHoraNormal(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: hora ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        hora = picked;
      });
    }
  }

  // HORA ENCUESTA
  void _agregarHoraEncuesta(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        horasEncuesta.add(picked);
      });
    }
  }

  Future<void> _openMap(String location, BuildContext context) async {
    if (location.isEmpty) return;
    final query = Uri.encodeComponent(location);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el mapa')),
      );
    }
  }

  void _seleccionarUbicacion(BuildContext context) async {
    final TextEditingController _ubicacionController = TextEditingController(text: ubicacion);
    String? ubicacionSeleccionada = ubicacion;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
            height: 400,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Selecciona ubicación',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _ubicacionController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe una ubicación',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: ubicacionesDisponibles.length,
                    itemBuilder: (context, index) {
                      final loc = ubicacionesDisponibles[index];
                      return ListTile(
                        title: Text(
                          loc,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          setState(() {
                            ubicacionSeleccionada = loc;
                            if (ubicacionEsEncuesta) {
                              ubicacionesEncuesta.add(ubicacionSeleccionada!);
                            } else {
                              ubicacion = ubicacionSeleccionada;
                            }
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          _openMap(_ubicacionController.text, context);
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('Ver en mapa'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          print("✅ cancelado");
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            ubicacionSeleccionada = _ubicacionController.text;
                            if (ubicacionEsEncuesta) {
                              ubicacionesEncuesta.add(ubicacionSeleccionada!);
                            } else {
                              ubicacion = ubicacionSeleccionada;
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('OK'),
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
        backgroundColor: selectedColor,
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

                    //TÍTULO
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

                    //DESCRIPCIÓN
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
                                    : (fecha != null
                                        ? DateFormat('d \'de\' MMMM \'de\' y', 'es_ES').format(fecha!)
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
                    if (fechaEsEncuesta && fechasEncuesta.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < fechasEncuesta.length; i++)
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
                                    'Opción ${i + 1}: ${DateFormat('d \'de\' MMMM \'de\' y', 'es_ES').format(fechasEncuesta[i])}',
                                    style: bodyPrimaryText.copyWith(
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        fechasEncuesta.removeAt(i);
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 24, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    //HORA
                    Text(
                      "Hora",
                      style: labelText,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        //BOTÓN: INPUT HORA
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (horaEsEncuesta) {
                                _agregarHoraEncuesta(context);
                              } else {
                                _seleccionarHoraNormal(context);
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
                                horaEsEncuesta
                                    ? 'Agregar opción de encuesta'
                                    : (hora != null
                                        ? hora!.format(context)
                                        : 'Toca para elegir hora'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON (HORA/ENCUESTA)
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'hora', label: Icon(Icons.calendar_today)),
                              ButtonSegment(value: 'encuesta', label: Icon(Icons.poll)),
                            ],
                            selected: {horaEsEncuesta ? 'encuesta' : 'hora'},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                horaEsEncuesta = newSelection.first == 'encuesta';
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
                    //HORA: OPCIONES DE ENCUESTA
                    if (horaEsEncuesta && horasEncuesta.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < horasEncuesta.length; i++)
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
                                    'Opción ${i + 1}: ${horasEncuesta[i].format(context)}',
                                    style: bodyPrimaryText.copyWith(
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        horasEncuesta.removeAt(i);
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 24, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    //UBICACIÓN
                    Text(
                      "Ubicación",
                      style: labelText,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        //BOTÓN: INPUT UBICACIÓN
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              _seleccionarUbicacion(context);
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
                              child:
                                Text(
                                  ubicacionEsEncuesta
                                      ? 'Agregar opción de encuesta'
                                      : (ubicacion?.isNotEmpty == true
                                          ? ubicacion!
                                          : 'Toca para elegir ubicación'),
                                  softWrap: true,
                                ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON (UBICACIÓN/ENCUESTA)
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'ubicacion', label: Icon(Icons.calendar_today)),
                              ButtonSegment(value: 'encuesta', label: Icon(Icons.poll)),
                            ],
                            selected: {ubicacionEsEncuesta ? 'encuesta' : 'ubicacion'},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                ubicacionEsEncuesta = newSelection.first == 'encuesta';
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
                    //UBICACIÓN: OPCIONES DE ENCUESTA
                    if (ubicacionEsEncuesta && ubicacionesEncuesta.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < ubicacionesEncuesta.length; i++)
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
                                  Flexible(
                                    child: Text(
                                      'Opción ${i + 1}: ${ubicacionesEncuesta[i]}',
                                      style: bodyPrimaryText.copyWith(
                                        fontWeight: FontWeight.w500
                                      ),
                                      softWrap: true,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        ubicacionesEncuesta.removeAt(i);
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 24, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    
                    const SizedBox(height: 12),

                    //BOTÓN: GUARDAR
                    ElevatedButton(
                      onPressed: () {
                          print("✅ botón");
                          db.collection("planes").add({
                            "anfitrion": "yo",
                            "titulo": _tituloController.text,
                            "descripcion": _descripcionController.text,
                            "visibilidad": selectedSegment,
                            "fechaEsEncuesta": fechaEsEncuesta,
                            "fecha": Timestamp.fromDate(fecha!),
                            "fechasEncuesta": fechasEncuesta.map((h) => Timestamp.fromDate(h)).toList(),
                            "horaEsEncuesta": horaEsEncuesta,
                            "hora": _timeOfDayToString(hora!),
                            "horasEncuesta": horasEncuesta.map((h) => _timeOfDayToString(h)).toList(),
                            "ubicacionEsEncuesta": ubicacionEsEncuesta,
                            "ubicacion": ubicacion,
                            "ubicacionesEncuesta": ubicacionesEncuesta,
                          });
                          print("✅ Plan guardado correctamente");
                        // Aquí agregas lo que quieras hacer al guardar
                      },
                      child: Text('Guardar'),
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
