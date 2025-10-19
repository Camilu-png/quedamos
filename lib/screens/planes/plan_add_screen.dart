import "package:intl/intl.dart";
import "package:uuid/uuid.dart";
import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/app_colors.dart";
import "package:quedamos/text_styles.dart";
import "package:quedamos/planes_components.dart";
import "package:quedamos/screens/main_screen.dart";

final db = FirebaseFirestore.instance;

final uuid = Uuid();

//ADD PLANES SCREEN
class AddPlanScreen extends StatefulWidget {
  final String userID;
  final Map<String, dynamic>? plan;
  const AddPlanScreen({super.key, this.plan, required this.userID});
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
  List<DateTime> fechasEncuesta = [];
  //HORA
  bool horaEsEncuesta = false;
  TimeOfDay? hora;
  List<TimeOfDay> horasEncuesta = [];
  //UBICACIÓN
  bool ubicacionEsEncuesta = false;
  String? ubicacion;
  List<String> ubicacionesEncuesta = [];
  final List<String> ubicacionesRecomendadas = [
    "Parque Bicentenario, Vitacura",
    "Parque Forestal, Santiago Centro",
    "Cerro San Cristóbal, Providencia",
    "Plaza Ñuñoa, Ñuñoa",
    "Estadio Nacional, Ñuñoa",
    "Costanera Center, Providencia",
    "Mall Plaza Egaña, La Reina",
    "Centro Gabriela Mistral (GAM), Santiago Centro",
    "Barrio Italia, Providencia",
    "Parque Araucano, Las Condes",
    "Café Literario Balmaceda, Providencia",
    "Museo Nacional de Bellas Artes, Santiago Centro",
    "Terraza del Cerro Santa Lucía, Santiago Centro",
    "Café del Patio, Lastarria",
    "Biblioteca Nacional, Alameda 651, Santiago Centro",
    "Campus San Joaquín, PUC, Macul",
    "Mall Sport, Las Condes",
    "Sky Costanera, Providencia",
    "Museo Interactivo Mirador (MIM), La Granja",
    "Parque O'Higgins, Santiago Centro",
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
        final fechasRaw = widget.plan!["fechasEncuesta"];
        if (fechasRaw != null && fechasRaw is List) {
          fechasEncuesta = fechasRaw
              .where((f) => f != null)
              .map<DateTime>((f) {
                if (f is Timestamp) return f.toDate();
                if (f is DateTime) return f;
                try {
                  return DateTime.parse(f.toString());
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
        final horasRaw = widget.plan!["horasEncuesta"];
        if (horasRaw != null && horasRaw is List) {
          horasEncuesta = horasRaw
              .where((h) => h != null)
              .map<TimeOfDay>((h) {
                if (h is TimeOfDay) return h;
                if (h is String) {
                  final hParsed = stringToTimeOfDay(h);
                  return hParsed ?? TimeOfDay.now();
                }
                final hParsed = stringToTimeOfDay(h.toString());
                return hParsed ?? TimeOfDay.now();
              })
              .toList();
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
      if (ubicacionEsEncuesta) {
        final ubicacionRaw = widget.plan!["ubicacionesEncuesta"];
        if (ubicacionRaw != null && ubicacionRaw is List) {
          ubicacionesEncuesta = ubicacionRaw.where((u) => u != null).map((u) => u.toString()).toList();
        } else {
          ubicacionesEncuesta = [];
        }
      } else {
        ubicacion = widget.plan!["ubicacion"];
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 2, //Cantidad de pestañas
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Selecciona icono",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: "Cerrar",
                        ),
                      ],
                    ),
                  ),
                ),
                //PESTAÑAS
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    labelStyle: Theme.of(context).textTheme.titleMedium,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(text: "Icono"),
                      Tab(text: "Color"),
                    ],
                  ),
                ),
                const Divider(height: 1),
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
          fechasEncuesta.add(fechaSelected);
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
          horasEncuesta.add(horaSelected);
        }
      });
    }
  }

  //UBICACIÓN: SELECTOR
  void _ubicacionSelector(BuildContext context) async {
    print("[🐧 planes] Abriendo modal selector de ubicación...");
    final TextEditingController ubicacionController = TextEditingController(text: ubicacion);
    String? ubicacionSelected = ubicacion;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Selecciona ubicación",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        tooltip: "Cerrar",
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                //BUSCADOR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: ubicacionController,
                    decoration: InputDecoration(
                      hintText: "Buscar ubicación...",
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                //UBICACIONES RECOMENDADAS
                Expanded(
                  child: ListView.builder(
                    itemCount: ubicacionesRecomendadas.length,
                    itemBuilder: (context, index) {
                      final ubicacionEntry = ubicacionesRecomendadas[index];
                      return ListTile(
                        leading: Icon(
                          Icons.place_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          ubicacionEntry,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        onTap: () {
                          setState(() {
                            ubicacionSelected = ubicacionEntry;
                            if (ubicacionEsEncuesta) {
                              ubicacionesEncuesta.add(ubicacionSelected!);
                            } else {
                              ubicacion = ubicacionSelected;
                            }
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                //ACCIONES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => showMap(context, mounted, ubicacionController.text),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text("Ver en mapa"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar"),
                      ),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            ubicacionSelected = ubicacionController.text;
                            if (ubicacionEsEncuesta) {
                              ubicacionesEncuesta.add(ubicacionSelected!);
                            } else {
                              ubicacion = ubicacionSelected;
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: iconoColor,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //ICONO
            GestureDetector(
              onTap: () => _showIconoSelectorModal(context),
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
                      style: Theme.of(context).textTheme.labelLarge,
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

                    //TÍTULO
                    Text(
                      "Título",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: titulo,
                      maxLength: 250,
                      decoration: InputDecoration(
                        hintText: "Ingresa un título",
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
                          return "Por favor, ingresa un título";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    //DESCRIPCIÓN
                    Text(
                      "Descripción",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: descripcion,
                      maxLength: 1000,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: "Ingresa una descripción",
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
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        //BOTÓN: INPUT FECHA
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
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                fechaEsEncuesta
                                    ? "Agregar opción de encuesta"
                                    : (fecha != null
                                        ? DateFormat("d 'de' MMMM 'de' y", "es_ES").format(fecha!)
                                        : "Toca para elegir fecha"),
                                style: Theme.of(context).textTheme.bodyMedium,
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
                    //FECHA: OPCIONES DE ENCUESTA
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
                                        "Opción ${i + 1}: ${DateFormat("d 'de' MMMM 'de' y", "es_ES").format(fechasEncuesta[i])}",
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
                      style: Theme.of(context).textTheme.labelLarge,
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
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                horaEsEncuesta
                                    ? "Agregar opción de encuesta"
                                    : (hora != null
                                        ? hora!.format(context)
                                        : "Toca para elegir hora"),
                                style: Theme.of(context).textTheme.bodyMedium,
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
                                        "Opción ${i + 1}: ${horasEncuesta[i].format(context)}",
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
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        //BOTÓN: INPUT HORA
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
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                ubicacionEsEncuesta
                                    ? "Agregar opción de encuesta"
                                    : (ubicacion?.isNotEmpty == true
                                      ? ubicacion!
                                      : "Toca para elegir ubicación"),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        //SEGMENTED BUTTON (HORA/ENCUESTA)
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: "ubicación", label: Icon(Icons.calendar_today)),
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
                                        "Opción ${i + 1}: ${ubicacionesEncuesta[i]}",
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
                                if (mounted) {
                                  print('[🐧 planes] Pop con plan editado, volviendo...');
                                  Navigator.of(context).pop(planID);
                                  return;
                                }
                              } else {
                                await db.collection("planes").doc(planID).set(planFinal);
                                print("[🐧 planes] Plan creado correctamente...");
                                if (mounted) {
                                  if (Navigator.of(context).canPop()) {
                                    print('[🐧 planes] Pop con plan creado, volviendo...');
                                    Navigator.of(context).pop(planID);
                                    return;
                                  }
                                  print('[🐧 planes] Reemplazando con MainScreen) tras crear plan...');
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
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("Guardar", style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          )),
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
