import "package:intl/intl.dart";
import "package:uuid/uuid.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/app_colors.dart";
import "package:quedamos/text_styles.dart";
import "package:quedamos/planes_components.dart";
import "package:quedamos/screens/main_screen.dart";

final db = FirebaseFirestore.instance;

final uuid = Uuid();

//ADD PLANES SCREEN
class AddPlanesScreen extends StatefulWidget {
  final String userID;
  final Map<String, dynamic>? plan;

  const AddPlanesScreen({super.key, this.plan, required this.userID});

  @override
  State<AddPlanesScreen> createState() => _AddPlanesScreenState();
}

//ADD PLANES SCREEN STATE
class _AddPlanesScreenState extends State<AddPlanesScreen> {

  final _formKey = GlobalKey<FormState>();

  //PLAN
  String planID = uuid.v4();
  //VISIBILIDAD
  String visibilidad = "Amigos";
  //ANFITRIÓN
  String anfitrionNombre = "Yo";
  //ICONO
  IconData iconoNombre = Icons.event;
  Color iconoColor = secondary;
  //TÍTULO
  final TextEditingController titulo = TextEditingController();
  //DESCRIPCIÓN
  final TextEditingController descripcion = TextEditingController();
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
  //PARTICIPANTES
  List<String> participantesAceptados = [];
  List<String> participantesRechazados = [];

  //INIT STATE
  @override
  void initState() {
    super.initState();
    //MODO EDITAR
    if (widget.plan != null) {
      //PLAN
      planID = widget.plan!["planID"] ?? uuid.v4();
      //VISIBILIDAD
      visibilidad = widget.plan!["visibilidad"] ?? "Amigos";
      //ANFITRIÓN
      anfitrionNombre = widget.plan!["anfitrionNombre"] ?? "";
      //ICONO
      iconoNombre = iconosMap[widget.plan!["iconoNombre"]] ?? Icons.event;
      iconoColor = coloresMap[widget.plan!["iconoColor"]] ?? secondary;
      //TÍTULO
      titulo.text = widget.plan!["titulo"] ?? "";
      //DESCRIPCIÓN
      descripcion.text = widget.plan!["descripcion"] ?? "";
      //FECHA
      fechaEsEncuesta = widget.plan!["fechaEsEncuesta"] ?? false;
      if (fechaEsEncuesta) {
        final rawFechas = widget.plan!["fechasEncuesta"];
        if (rawFechas != null && rawFechas is List) {
          fechasEncuesta = rawFechas
              .where((e) => e != null)
              .map<DateTime>((e) {
                if (e is Timestamp) return e.toDate();
                if (e is DateTime) return e;
                // Fallback: try parsing string
                try {
                  return DateTime.parse(e.toString());
                } catch (_) {
                  return DateTime.now();
                }
              })
              .toList();
        } else {
          fechasEncuesta = [];
        }
      } else {
        if (widget.plan!["fecha"] is Timestamp) {
          fecha = (widget.plan!["fecha"] as Timestamp).toDate();
        } else {
          fecha = widget.plan!["fecha"];
        }
      }
      //HORA
      horaEsEncuesta = widget.plan!["horaEsEncuesta"] ?? false;
      if (horaEsEncuesta) {
        final rawHoras = widget.plan!["horasEncuesta"];
        if (rawHoras != null && rawHoras is List) {
          horasEncuesta = rawHoras
              .where((h) => h != null)
              .map<TimeOfDay>((h) {
                if (h is TimeOfDay) return h;
                if (h is String) {
                  final parsed = stringToTimeOfDay(h);
                  return parsed ?? TimeOfDay.now();
                }
                // fallback: try toString
                final parsed = stringToTimeOfDay(h.toString());
                return parsed ?? TimeOfDay.now();
              })
              .toList();
        } else {
          horasEncuesta = [];
        }
      } else {
        final rawHora = widget.plan!["hora"];
        if (rawHora is String) {
          hora = stringToTimeOfDay(rawHora);
        } else {
          hora = null;
        }
      }
      //UBICACIÓN
      ubicacionEsEncuesta = widget.plan!["ubicacionEsEncuesta"] ?? false;
      if (ubicacionEsEncuesta) {
        final rawUbic = widget.plan!["ubicacionesEncuesta"];
        if (rawUbic != null && rawUbic is List) {
          ubicacionesEncuesta = rawUbic.where((u) => u != null).map((u) => u.toString()).toList();
        } else {
          ubicacionesEncuesta = [];
        }
      } else {
        ubicacion = widget.plan!["ubicacion"];
      }
      //PARTICIPANTES
      final rawAceptados = widget.plan!["participantesAceptados"];
      if (rawAceptados != null && rawAceptados is List) {
        participantesAceptados = rawAceptados.where((p) => p != null).map((p) => p.toString()).toList();
      } else {
        participantesAceptados = [];
      }
      final rawRechazados = widget.plan!["participantesRechazados"];
      if (rawRechazados != null && rawRechazados is List) {
        participantesRechazados = rawRechazados.where((p) => p != null).map((p) => p.toString()).toList();
      } else {
        participantesRechazados = [];
      }
    }
  }

  @override
  void dispose() {
    titulo.dispose();
    descripcion.dispose();
    super.dispose();
  }

  //STRING -> TIME OF DAY
  TimeOfDay? stringToTimeOfDay(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(":");
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  //TIME OF DAY -> STRING
  String timeOfDayToString(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, "0");
    final minute = t.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }

  //ICON DATA -> STRING
  String getIconName(IconData icon) {
    return iconosMap.entries
      .firstWhere((entry) => entry.value == icon,
          orElse: () => const MapEntry("event", Icons.event))
      .key;
  }

  //COLOR -> STRING
  String getColorName(Color color) {
    return coloresMap.entries
      .firstWhere((entry) => entry.value == color,
          orElse: () => const MapEntry("secondary", secondary))
      .key;
  }
  
  //ICONO: MODAL
  void abrirSelectorIconoColor(BuildContext context) {
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
                      //PESTAÑA: ICONOS
                      GridView.count(
                        crossAxisCount: 4,
                        padding: const EdgeInsets.all(16),
                        children: iconosMap.entries.map((entry) {
                          final iconData = entry.value;
                          return GestureDetector(
                            onTap: () {
                              setState(() => iconoNombre = iconData);
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: iconoNombre == iconData
                                      ? primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(iconData, size: 40),
                            ),
                          );
                        }).toList(),
                      ),
                      //PESTAÑA: COLORES
                      GridView.count(
                        crossAxisCount: 4,
                        padding: const EdgeInsets.all(16),
                        children: coloresMap.entries.map((entry) {
                          final colorValue = entry.value;
                          return GestureDetector(
                            onTap: () {
                              setState(() => iconoColor = colorValue);
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorValue,
                                border: Border.all(
                                  color: iconoColor == colorValue
                                      ? primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }).toList(),
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
  void seleccionarFechaNormal(BuildContext context) async {
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
  void agregarFechaEncuesta(BuildContext context) async {
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
  void seleccionarHoraNormal(BuildContext context) async {
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
  void agregarHoraEncuesta(BuildContext context) async {
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

  Future<void> openMap(String location, BuildContext context) async {
    if (location.isEmpty) return;
    final query = Uri.encodeComponent(location);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir el mapa")),
      );
    }
  }

  void seleccionarUbicacion(BuildContext context) async {
    final TextEditingController ubicacionController = TextEditingController(text: ubicacion);
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
                  "Selecciona ubicación",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: ubicacionController,
                    decoration: const InputDecoration(
                      hintText: "Escribe una ubicación",
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
                          openMap(ubicacionController.text, context);
                        },
                        icon: const Icon(Icons.map),
                        label: const Text("Ver en mapa"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancelar"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            ubicacionSeleccionada = ubicacionController.text;
                            if (ubicacionEsEncuesta) {
                              ubicacionesEncuesta.add(ubicacionSeleccionada!);
                            } else {
                              ubicacion = ubicacionSeleccionada;
                            }
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("OK"),
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
    print("[🐧 planes] UID del usuario: ${widget.userID}");
    return Scaffold(

      //APP BAR
      appBar: AppBar(
        title: Text(
          widget.plan != null ? "Editar plan" : "Nuevo plan",
          style: subtitleText.copyWith(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: iconoColor,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //ICONO
            GestureDetector(
              onTap: () => abrirSelectorIconoColor(context),
              child: Container(
                width: double.infinity,
                height: 120,
                color: iconoColor,
                alignment: Alignment.center,
                child: Icon(iconoNombre, color: Colors.white, size: 60),
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
                          ButtonSegment(value: "Amigos", label: Text("Amigos", style: helpText)),
                          ButtonSegment(value: "Público", label: Text("Público", style: helpText)),
                        ],
                        selected: <String>{visibilidad},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            visibilidad = newSelection.first;
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
                      controller: titulo,
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
                      controller: descripcion,
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
                                agregarFechaEncuesta(context);
                              } else {
                                seleccionarFechaNormal(context);
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
                                    ? "Agregar opción de encuesta"
                                    : (fecha != null
                                        ? DateFormat("d 'de' MMMM 'de' y", "es_ES").format(fecha!)
                                        : "Toca para elegir fecha"),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON (FECHA/ENCUESTA)
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: "fecha", label: Icon(Icons.calendar_today)),
                              ButtonSegment(value: "encuesta", label: Icon(Icons.poll)),
                            ],
                            selected: {fechaEsEncuesta ? "encuesta" : "fecha"},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                fechaEsEncuesta = newSelection.first == "encuesta";
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
                                    "Opción ${i + 1}: ${DateFormat("d 'de' MMMM 'de' y", "es_ES").format(fechasEncuesta[i])}",
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
                                agregarHoraEncuesta(context);
                              } else {
                                seleccionarHoraNormal(context);
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
                                    ? "Agregar opción de encuesta"
                                    : (hora != null
                                        ? hora!.format(context)
                                        : "Toca para elegir hora"),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON (HORA/ENCUESTA)
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: "hora", label: Icon(Icons.calendar_today)),
                              ButtonSegment(value: "encuesta", label: Icon(Icons.poll)),
                            ],
                            selected: {horaEsEncuesta ? "encuesta" : "hora"},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                horaEsEncuesta = newSelection.first == "encuesta";
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
                                    "Opción ${i + 1}: ${horasEncuesta[i].format(context)}",
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
                              seleccionarUbicacion(context);
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
                                      ? "Agregar opción de encuesta"
                                      : (ubicacion?.isNotEmpty == true
                                          ? ubicacion!
                                          : "Toca para elegir ubicación"),
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
                              ButtonSegment(value: "ubicacion", label: Icon(Icons.calendar_today)),
                              ButtonSegment(value: "encuesta", label: Icon(Icons.poll)),
                            ],
                            selected: {ubicacionEsEncuesta ? "encuesta" : "ubicacion"},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                ubicacionEsEncuesta = newSelection.first == "encuesta";
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
                                      "Opción ${i + 1}: ${ubicacionesEncuesta[i]}",
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
                      onPressed: () async {
                        //OBTENER NOMBRE DEL USUARIO
                        print("[🐧 planes] Obteniendo nombre del usuario...");
                          anfitrionNombre = "";
                          try {
                            final userDoc = await db.collection("users").doc(widget.userID).get();
                            if (userDoc.exists) {
                              anfitrionNombre = userDoc.data()?["name"] ?? '';
                            } else {
                              print("[🐧 planes] Usuario no encontrado...");
                            }
                          } catch (e) {
                            print("[🐧 planes] Error: $e");
                          }
                          //GUARDAR PLAN
                          print("[🐧 planes] Guardando plan...");
                          final planFinal = {
                            "planID": planID,
                            "visibilidad": visibilidad,
                            "iconoNombre": getIconName(iconoNombre),
                            "iconoColor": getColorName(iconoColor),
                            "anfitrionID": widget.userID,
                            "anfitrionNombre": anfitrionNombre,
                            "titulo": titulo.text,
                            "descripcion": descripcion.text,
                            "fechaEsEncuesta": fechaEsEncuesta,
                            "fecha": fecha != null ? Timestamp.fromDate(fecha!) : null,
                            "fechasEncuesta": fechasEncuesta.map((h) => Timestamp.fromDate(h)).toList(),
                            "horaEsEncuesta": horaEsEncuesta,
                            "hora": hora != null ? timeOfDayToString(hora!) : null,
                            "horasEncuesta": horasEncuesta.map((h) => timeOfDayToString(h)).toList(),
                            "ubicacionEsEncuesta": ubicacionEsEncuesta,
                            "ubicacion": ubicacion,
                            "ubicacionesEncuesta": ubicacionesEncuesta,
                            "participantesAceptados": participantesAceptados,
                            "participantesRechazados": participantesRechazados,
                          };
                          try {
                            if (widget.plan != null) {
                              await db.collection("planes").doc(planID).update(planFinal);
                              print("[🐧 planes] Plan editado correctamente...");
                              // Devolver el planID y volver a la vista anterior
                              if (mounted) {
                                print('[🐧 planes] Pop con plan editado, volviendo...');
                                Navigator.of(context).pop(planID);
                                return;
                              }
                            } else {
                              await db.collection("planes").doc(planID).set(planFinal);
                              print("[🐧 planes] Plan creado correctamente...");
                              // Al crear un plan, llevar al usuario a 'MisPlanesScreen'
                              if (mounted) {
                                // Si la pantalla fue pusheada (canPop == true), devolvemos el planID
                                if (Navigator.of(context).canPop()) {
                                  print('[🐧 planes] Pop con plan creado, volviendo...');
                                  Navigator.of(context).pop(planID);
                                  return;
                                }
                                // Si no se puede pop (estamos embebidos en MainScreen como pestaña),
                                // reemplazamos la pantalla con MainScreen que muestra "Mis planes" (index 1)
                                print('[🐧 planes] Reemplazando con MainScreen(initialIndex:1) tras crear plan...');
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => MainScreen(userID: widget.userID, initialIndex: 1)),
                                );
                                return;
                              }
                            }
                          } catch (e) {
                            print("[🐧 planes] Error: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("No se pudo guardar el plan: $e")),
                            );
                          }      
                      },
                      child: Text("Guardar"),
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
