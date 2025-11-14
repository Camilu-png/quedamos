import "dart:convert";
import "package:intl/intl.dart";
import "package:uuid/uuid.dart";
import "package:flutter/material.dart";
import 'package:geolocator/geolocator.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:quedamos/app_colors.dart";
import "package:quedamos/screens/main_screen.dart";
import "package:quedamos/screens/planes/planes_components.dart";
import "package:quedamos/services/plans_service.dart";

final db = FirebaseFirestore.instance;

final uuid = Uuid();

//ADD PLANES SCREEN
class AddPlanScreen extends StatefulWidget {
  final String userID;
  final Map<String, dynamic>? plan;
  final Position? currentLocation;
  const AddPlanScreen({super.key, this.plan, required this.userID, this.currentLocation});
  @override
  State<AddPlanScreen> createState() => _AddPlanScreenState();
}

//ADD PLANES SCREEN STATE
class _AddPlanScreenState extends State<AddPlanScreen> {

  final _formKey = GlobalKey<FormState>();

  //PLAN
  String planID = uuid.v4();
  //VISIBILIDAD
  String visibilidad = "Amigos";
  //ANFITRIÓN
  String anfitrionNombre = "Usuario desconocido";
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
  List<Map<String, dynamic>> fechasEncuesta = [];
  //HORA
  bool horaEsEncuesta = false;
  TimeOfDay? hora;
  List<Map<String, dynamic>> horasEncuesta = [];
  //UBICACIÓN
  bool ubicacionEsEncuesta = false;
  Map<String, dynamic>? ubicacion;
  List<Map<String, dynamic>> ubicacionesEncuesta = [];
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
      final listaFechas = widget.plan!["fechasEncuesta"];
      
      if (listaFechas is List && listaFechas.isNotEmpty) {
        fechasEncuesta = listaFechas.map<Map<String, dynamic>>((item) {
          if (item is! Map) {
            print("[🐧 planes] Advertencia: item de fechasEncuesta no es Map: $item");
            return {"fecha": DateTime.now(), "votos": []};
          }
          
          final fechaRaw = item["fecha"];
          DateTime fechaParsed;

          if (fechaRaw is String) {
            fechaParsed = DateTime.parse(fechaRaw);
          } else if (fechaRaw is int) {
            fechaParsed = DateTime.fromMillisecondsSinceEpoch(fechaRaw);
          } else if (fechaRaw is DateTime) {
            fechaParsed = fechaRaw;
          } else if (fechaRaw is Timestamp) {
            fechaParsed = fechaRaw.toDate();
          } else {
            print("[🐧 planes] Advertencia: tipo de fecha desconocido: ${fechaRaw.runtimeType}");
            fechaParsed = DateTime.now();
          }

          return {
            "fecha": fechaParsed,
            "votos": item["votos"] ?? [],
          };
        }).toList();
      } else {
        fechasEncuesta = [];
      }



      //HORA
      horaEsEncuesta = widget.plan!["horaEsEncuesta"] ?? false;
      if (horaEsEncuesta) {
        final horasRaw = widget.plan!["horasEncuesta"];
        if (horasRaw is List && horasRaw.isNotEmpty) {
          horasEncuesta = horasRaw.map<Map<String, dynamic>>((item) {
            if (item is! Map) {
              print("[🐧 planes] Advertencia: item de horasEncuesta no es Map: $item");
              return {"hora": "", "votos": []};
            }
            return {
              "hora": item["hora"] ?? "",
              "votos": item["votos"] ?? [],
            };
          }).toList();
        } else {
          horasEncuesta = [];
        }
      } else {
        final horaRaw = widget.plan!["hora"];
        if (horaRaw is String) {
          hora = stringToTimeOfDay(horaRaw);
        } else {
          hora = null;
        }
      }
      //UBICACIÓN
      ubicacionEsEncuesta = widget.plan!["ubicacionEsEncuesta"] ?? false;
      if (ubicacionEsEncuesta == true) {
        final ubicacionesRaw = widget.plan!["ubicacionesEncuesta"];
        if (ubicacionesRaw != null && ubicacionesRaw is List) {
          ubicacionesEncuesta = ubicacionesRaw
              .where((u) => u != null && u is Map)
              .map<Map<String, dynamic>>((u) => Map<String, dynamic>.from(u))
              .toList();
        } else {
          ubicacionesEncuesta = [];
        }
      } else {
        if (widget.plan!["ubicacion"] != null && widget.plan!["ubicacion"] is Map) {
          ubicacion = Map<String, dynamic>.from(widget.plan!["ubicacion"]);
        } else {
          ubicacion = {
            "nombre": "Casa Central, UTFSM",
            "latitud": -33.0458,
            "longitud": -71.6197,
          };
        }
        print("[🐧 planes] Ubicación cargada: $ubicacion");
      }

      //PARTICIPANTES
      final participantesAceptadosRaw = widget.plan!["participantesAceptados"];
      if (participantesAceptadosRaw != null && participantesAceptadosRaw is List) {
        participantesAceptados = participantesAceptadosRaw.where((p) => p != null).map((p) => p.toString()).toList();
      } else {
        participantesAceptados = [];
      }
      final participantesRechazadosRaw = widget.plan!["participantesRechazados"];
      if (participantesRechazadosRaw != null && participantesRechazadosRaw is List) {
        participantesRechazados = participantesRechazadosRaw.where((p) => p != null).map((p) => p.toString()).toList();
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

  //ICONO: MODAL
  void _showIconoSelectorModal(BuildContext context) {
    print("[🐧 planes] Abriendo modal selector de icono...");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                //PESTAÑAS
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    labelStyle: Theme.of(context).textTheme.titleSmall,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    unselectedLabelStyle: Theme.of(context).textTheme.titleSmall,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(text: "Icono"),
                      Tab(text: "Color"),
                    ],
                  ),
                ),
                //PESTAÑAS
                Expanded(
                  child: TabBarView(
                    children: [
                      //PESTAÑA: COLORES
                      StatefulBuilder(
                        builder: (context, setStateInner) {
                          return GridView.count(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            padding: const EdgeInsets.all(16),
                            children: iconosMap.entries.map((entry) {
                              final iconoNombreEntry = entry.value;
                              final bool iconoNombreIsSelected = iconoNombre == iconoNombreEntry;
                              return InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {
                                  setState(() {
                                    iconoNombre = iconoNombreEntry;
                                  });
                                  setStateInner(() {}); //Rebuild
                                },
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: iconoNombreIsSelected
                                        ? Theme.of(context).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: iconoNombreIsSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    iconoNombreEntry,
                                    size: 40,
                                    color: iconoNombreIsSelected
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      //PESTAÑA: COLORES
                      StatefulBuilder(
                        builder: (context, setStateInner) {
                          return GridView.count(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            padding: const EdgeInsets.all(16),
                            children: coloresMap.entries.map((entry) {
                              final iconoColorEntry = entry.value;
                              final bool iconoColorIsSelected = iconoColor == iconoColorEntry;
                              return InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {
                                  setState(() {
                                    iconoColor = iconoColorEntry;
                                  });
                                  setStateInner(() {}); //Rebuild
                                },
                                child: Ink(
                                  decoration: BoxDecoration(
                                    color: iconoColorEntry,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: iconoColorIsSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
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

  //FECHA: SELECTOR
  void _fechaSelector(BuildContext context) async {
    print("[🐧 planes] Seleccionando fecha...");
    final fechaSelected = await showDatePicker(
      context: context,
      initialDate: !fechaEsEncuesta ? fecha ?? DateTime.now() : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (fechaSelected != null) {
      setState(() {
        if (!fechaEsEncuesta) {
          fecha = fechaSelected;
        } else {
          fechasEncuesta.add({
            "fecha": fechaSelected,
            "votos": [],
          });
        }
      });
    }
  }

  //HORA: SELECTOR
  void _horaSelector(BuildContext context) async {
    print("[🐧 planes] Seleccionando hora...");
    final horaSelected = await showTimePicker(
      context: context,
      initialTime: !horaEsEncuesta ? hora ?? TimeOfDay.now() : TimeOfDay.now(),
    );
    if (horaSelected != null) {
      setState(() {
        if (!horaEsEncuesta) {
          hora = horaSelected;
        } else {
          horasEncuesta.add({
            "hora": timeOfDayToString(horaSelected),
            "votos": [],
          });
        }
      });
    }
  }

  //UBICACIÓN: SELECTOR
  void _ubicacionSelector(BuildContext context) {
    showUbicacionSelector(
      context,
      (latLng, nombre) {
      setState(() {
        final nuevaUbicacion = {
          "nombre": nombre.split(",")[0],
          "latitud": latLng.latitude,
          "longitud": latLng.longitude
        };
        if (!ubicacionEsEncuesta) {
          ubicacion = nuevaUbicacion;
        } else {
          ubicacionesEncuesta.add(nuevaUbicacion);
        }
        print("[🐧 planes] Ubicación seleccionada: $nuevaUbicacion");
      });
      },
      initialPosition: widget.currentLocation,
    );
  }

  @override
  Widget build(BuildContext context) {

    print("[🐧 planes] UID del usuario: ${widget.userID}");

    return Scaffold(

      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,

      //APP BAR
      appBar: AppBar(
        title: Text(
          widget.plan != null ? "Editar plan" : "Nuevo plan",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: iconoColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //ICONO
            GestureDetector(
              onTap: () => _showIconoSelectorModal(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 120,
                    color: iconoColor,
                    alignment: Alignment.center,
                    child: Icon(iconoNombre, color: Colors.white, size: 60),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          _showIconoSelectorModal(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), //Área tactil
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 16, color: Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: 4),
                              Text(
                                "Cambiar icono",
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    //TÍTULO
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: titulo,
                      maxLength: 250,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.title),
                        labelText: "Título",
                        hintText: "Ingresa un título",
                        floatingLabelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, ingresa un título.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    //DESCRIPCIÓN
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: descripcion,
                      maxLength: 1000,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.description),
                        labelText: "Descripción",
                        hintText: "Ingresa una descripción",
                        floatingLabelStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, ingresa una descripción";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    //FECHA
                    Text(
                      "Fecha",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        //BOTÓN: FECHA
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              _fechaSelector(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fechaEsEncuesta
                                        ? "Elegir opción de encuesta"
                                        : (fecha != null
                                            ? DateFormat("d 'de' MMMM 'de' y", "es_ES").format(fecha!)
                                            : "Elegir fecha"),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON: FECHA
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: "fecha", label: Icon(Icons.assignment)),
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
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                              selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                              selectedForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              side: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    //OPCIONES DE ENCUESTA: FECHA
                    if (fechaEsEncuesta && fechasEncuesta.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < fechasEncuesta.length; i++)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Opción ${i + 1}: ${DateFormat("d 'de' MMMM 'de' y", "es_ES").format(fechasEncuesta[i]['fecha'])}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          fechasEncuesta.removeAt(i);
                                        });
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                      style: IconButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(24, 24),
                                      ),
                                      tooltip: "Eliminar opción",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    //HORA
                    Text(
                      "Hora",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        //BOTÓN: INPUT HORA
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              _horaSelector(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    horaEsEncuesta
                                      ? "Elegir opción de encuesta"
                                      : (hora != null
                                        ? hora!.format(context)
                                        : "Elegir hora"),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ]
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON (HORA/ENCUESTA)
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: "hora", label: Icon(Icons.assignment)),
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
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                              selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                              selectedForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              side: BorderSide.none,
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
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Opción ${i + 1}: ${horasEncuesta[i]['hora']}",
                                        style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          horasEncuesta.removeAt(i);
                                        });
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                      style: IconButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(24, 24),
                                      ),
                                      tooltip: "Eliminar opción",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    //UBICACIÓN
                    Text(
                      "Ubicación",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        //BOTÓN: INPUT UBICACIÓN
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              _ubicacionSelector(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                              foregroundColor: Theme.of(context).colorScheme.onSurface,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ubicacionEsEncuesta
                                      ? "Elegir opción de encuesta"
                                      : (ubicacion?.isNotEmpty == true
                                        ? ubicacion!["nombre"] ?? "Ubicación desconocida"
                                        : "Elegir ubicación"),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON (HORA/ENCUESTA)
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: "ubicación", label: Icon(Icons.assignment)),
                              ButtonSegment(value: "encuesta", label: Icon(Icons.poll)),
                            ],
                            selected: {ubicacionEsEncuesta ? "encuesta" : "ubicación"},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                ubicacionEsEncuesta = newSelection.first == "encuesta";
                              });
                            },
                            style: SegmentedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                              selectedBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                              selectedForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              side: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    //HORA: OPCIONES DE ENCUESTA
                    if (ubicacionEsEncuesta && ubicacionesEncuesta.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < ubicacionesEncuesta.length; i++)
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              color: Theme.of(context).colorScheme.surfaceContainerHigh,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "Opción ${i + 1}: ${ubicacionesEncuesta[i]["nombre"]}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          ubicacionesEncuesta.removeAt(i);
                                        });
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                      style: IconButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.error,
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(24, 24),
                                      ),
                                      tooltip: "Eliminar opción",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    //VISIBILIDAD
                    Text(
                      "Visibilidad",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: "Amigos", label: Text("Amigos", style: Theme.of(context).textTheme.bodyMedium)),
                          ButtonSegment(value: "Público", label: Text("Público", style: Theme.of(context).textTheme.bodyMedium)),
                        ],
                        selected: <String>{visibilidad},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            visibilidad = newSelection.first;
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

                    const SizedBox(height: 12),

                    //BOTÓN: GUARDAR
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (
                              titulo.text.isEmpty ||
                              descripcion.text.isEmpty ||
                              (!fechaEsEncuesta && fecha == null) ||
                              (fechaEsEncuesta && fechasEncuesta.isEmpty) ||
                              (!horaEsEncuesta && hora == null) ||
                              (horaEsEncuesta && horasEncuesta.isEmpty) ||
                              (!ubicacionEsEncuesta && ubicacion == null) ||
                              (ubicacionEsEncuesta && ubicacionesEncuesta.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Por favor, completa todos los campos."),
                                ),
                              );
                              return;
                            }
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
                            DateTime fechaReal = fechaEsEncuesta
                              ? DateTime.now() // valor "dummy" para SQLite
                              : (fecha ?? DateTime.now()); // si hay fecha seleccionada, la usamos, si no también ponemos now
                            final planFinal = {
                              "planID": planID,
                              "fecha_creacion": Timestamp.fromDate(DateTime.now()),
                              "visibilidad": visibilidad,
                              "iconoNombre": getIconName(iconoNombre),
                              "iconoColor": getColorName(iconoColor),
                              "anfitrionID": widget.userID,
                              "anfitrionNombre": anfitrionNombre,
                              "titulo": titulo.text,
                              "descripcion": descripcion.text,
                              "fechaEsEncuesta": fechaEsEncuesta,
                              "fecha": fecha != null ? Timestamp.fromDate(fecha!) : Timestamp.fromDate(fechaReal),
                              "fechasEncuesta": fechasEncuesta.map((opcion) => {
                                "fecha": Timestamp.fromDate(opcion["fecha"]),
                                "votos": opcion["votos"],
                              }).toList(),
                              "horaEsEncuesta": horaEsEncuesta,
                              "hora": hora != null ? timeOfDayToString(hora!) : null,
                              "horasEncuesta": horasEncuesta.map((h) => {
                                "hora": h["hora"],
                                "votos": h["votos"],
                              }).toList(),
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
                                if (mounted) {
                                  print('[🐧 planes] Pop con plan editado, volviendo...');
                                  Navigator.of(context).pop(planID);
                                  return;
                                }
                              } else {
                                // Check connectivity
                                final connectivityResult = await Connectivity().checkConnectivity();
                                final isOnline = !connectivityResult.contains(ConnectivityResult.none);
                                
                                try {
                                  if (isOnline) {
                                    // Try to create online
                                    await db.collection("planes").doc(planID).set(planFinal);
                                    print("[🐧 planes] Plan creado correctamente online");
                                  } else {
                                    // Offline mode - save locally
                                    print("[🐧 planes] Modo offline - guardando plan localmente");
                                    final plansService = PlansService();
                                    await plansService.createPlan(
                                      planData: planFinal,
                                      isOnline: false,
                                    );
                                    
                                    // Show offline message
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.cloud_off, color: Colors.white),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Plan guardado. Se sincronizará cuando tengas conexión.',
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.orange.shade700,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  }
                                  
                                  if (mounted) {
                                    if (Navigator.of(context).canPop()) {
                                      print('[🐧 planes] Pop con plan creado, volviendo...');
                                      Navigator.of(context).pop(planID);
                                      return;
                                    }
                                    print('[🐧 planes] Reemplazando con MainScreen tras crear plan...');
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => MainScreen(userID: widget.userID, initialIndex: 1)),
                                    );
                                    return;
                                  }
                                } catch (e) {
                                  print("[🐧 planes] Error al crear plan: $e");
                                  // Try to save offline as fallback
                                  final plansService = PlansService();
                                  await plansService.createPlan(
                                    planData: planFinal,
                                    isOnline: false,
                                  );
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.cloud_off, color: Colors.white),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Error de conexión. Plan guardado localmente.',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: Colors.orange.shade700,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                    
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop(planID);
                                    }
                                  }
                                }
                              }
                            } catch (e) {
                              print("[🐧 planes] Error: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("No se pudo guardar el plan: $e.")),
                              );
                            }      
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            "Guardar",
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontWeight: FontWeight.w600,
                            )
                          ),
                        ),
                      )
                    )
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
