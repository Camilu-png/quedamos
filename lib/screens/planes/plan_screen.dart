import "package:intl/intl.dart";
import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/app_colors.dart";
import "package:geolocator/geolocator.dart";
import "package:quedamos/screens/planes/plan_add_screen.dart";
import "package:quedamos/screens/planes/planes_components.dart";

final db = FirebaseFirestore.instance;

class PlanScreen extends StatefulWidget {
  final String userID;
  final Map<String, dynamic> plan;
  final Position? currentLocation;
  const PlanScreen({super.key, required this.plan, required this.userID, this.currentLocation});
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {

  late Map<String, dynamic> plan;
  late List<dynamic> participantesAceptados;
  late List<dynamic> participantesRechazados;

  @override
  void initState() {
    super.initState();
    plan = Map<String, dynamic>.from(widget.plan);
    participantesAceptados = List<dynamic>.from(plan["participantesAceptados"] ?? []);
    participantesRechazados = List<dynamic>.from(plan["participantesRechazados"] ?? []);
  }

  String? _getPlanID() {
    final dynamic pid = plan["planID"] ?? plan["id"] ?? plan["planId"];
    if (pid == null) return null;
    return pid.toString();
  }

  Future<List<String>> _getUsersNames(List<dynamic> userIDs) async {
    print("[🐧 planes] Obteniendo nombres de los participantes...");
    if (userIDs.isEmpty) return [];
    List<String> nombres = [];
    for (var id in userIDs) {
      final doc = await db.collection("users").doc(id.toString()).get();
      if (doc.exists && doc.data() != null) {
        nombres.add(doc.data()!["name"] ?? id.toString());
      } else {
        nombres.add(id.toString());
      }
    }
    return nombres;
  }

  void _showParticipantesModal(BuildContext context, List<dynamic> participantesAceptados, List<dynamic> participantesRechazados) {
    print("[🐧 planes] Abriendo modal de participantes...");
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
                    labelStyle: Theme.of(context).textTheme.titleMedium,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      //ACEPTADOS
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Aceptados"),
                          ],
                        ),
                      ),
                      //RECHAZADOS
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel, color: Theme.of(context).colorScheme.error),
                             SizedBox(width: 8),
                            Text("Rechazados"),
                          ],
                        ),
                      ),
                    ],
                  )
                ),
                //PESTAÑAS
                Expanded(
                  child: TabBarView(
                    children: [
                      //ACEPTADOS
                      FutureBuilder<List<String>>(
                        future: _getUsersNames(participantesAceptados),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text("Error al cargar participantes"));
                          } else {
                            final nombres = snapshot.data ?? [];
                            if (nombres.isEmpty) {
                              return Center(
                                child: Text(
                                  "No se encontraron participantes.",
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: nombres.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(nombres[index]),
                                );
                              },
                            );
                          }
                        },
                      ),
                      //RECHAZADOS
                      FutureBuilder<List<String>>(
                        future: _getUsersNames(participantesRechazados),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text("Error al cargar participantes"));
                          } else {
                            final nombres = snapshot.data ?? [];
                            if (nombres.isEmpty) {
                              return Center(
                                child: Text(
                                  "No se encontraron participantes.",
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: nombres.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(nombres[index]),
                                );
                              },
                            );
                          }
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

  void _showEncuesta(String tipo) {
    String tituloModal = "";
    String fieldName = "";
    switch (tipo) {
      case "fecha":
        fieldName = "fechasEncuesta";
        tituloModal = "Vota por tu fecha favorita";
        break;
      case "hora":
        fieldName = "horasEncuesta";
        tituloModal = "Vota por tu hora favorita";
        break;
      case "ubicacion":
        fieldName = "ubicacionesEncuesta";
        tituloModal = "Vota por tu ubicación favorita";
        break;
      default:
        return;
    }
    final String? planID = _getPlanID();
    if (planID == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo identificar el plan.")),
      );
      return;
    }
    final String userID = widget.userID;
    final String anfitrionID = plan["anfitrionID"]?.toString() ?? "";
    final bool esAnfitrion = userID == anfitrionID;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //TÍTULO
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.poll),
                      const SizedBox(width: 8),
                      Text(
                        tituloModal,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                //CONTENIDO
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: db.collection("planes").doc(planID).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Center(
                          child: Text(
                            "No se encontró la encuesta.",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      final List<dynamic> items = List.from(data[fieldName] ?? []);
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            "No hay opciones disponibles aún.",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      //VOTOS
                      final int totalVotos = items.fold<int>(
                        0,
                        (sum, opt) {
                          final List<dynamic> votosOpt = (opt["votos"] as List?) ?? [];
                          return sum + votosOpt.length;
                        },
                      );
                      int maxVotos = 0;
                      for (final it in items) {
                        final List<dynamic> votos = (it["votos"] as List?) ?? [];
                        if (votos.length > maxVotos) {
                          maxVotos = votos.length;
                        }
                      }
                      return ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          //FECHA
                          DateTime fechaVotada = DateTime.now();
                          if (item["fecha"] is Timestamp) {
                            fechaVotada = (item["fecha"] as Timestamp).toDate();
                          } else if (item["fecha"] is DateTime) {
                            fechaVotada = item["fecha"];
                          }
                          //HORA
                          TimeOfDay horaVotada;
                          if (item["hora"] is String) {
                            final partes = item["hora"].toString().trim().split(":");
                            final hora = int.tryParse(partes[0]) ?? 0;
                            final minuto = partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0;
                            horaVotada = TimeOfDay(hour: hora, minute: minuto);
                          } else if (item["hora"] is int && item["minuto"] is int) {
                            horaVotada = TimeOfDay(
                              hour: item["hora"] as int,
                              minute: item["minuto"] as int,
                            );
                          } else {
                            horaVotada = const TimeOfDay(hour: 0, minute: 0);
                          }
                          //UBICACIÓN
                          Map<String, dynamic>? ubicacionMap;
                          if (tipo == "ubicacion" && item["ubicacion"] is Map) {
                            ubicacionMap = Map<String, dynamic>.from(item["ubicacion"] as Map);
                          }
                          //VOTOS
                          final List<dynamic> votos = (item["votos"] as List?) ?? [];
                          final bool yaVoto = votos.contains(userID);
                          final int cantidadVotos = votos.length;
                          final bool esMasVotada = maxVotos > 0 && cantidadVotos == maxVotos;
                          //PORCENTAJE
                          double porcentaje = 0;
                          if (totalVotos > 0) {
                            porcentaje = (cantidadVotos / totalVotos) * 100;
                          }
                          final String porcentajeTexto =
                              totalVotos > 0 ? " • ${porcentaje.toStringAsFixed(0)}%" : "";
                          //TEXTO PRINCIPAL
                          String tituloOpcion;
                          switch (tipo) {
                            case "fecha":
                              tituloOpcion =
                                DateFormat("d 'de' MMMM 'de' y", "es_ES").format(fechaVotada);
                              break;
                            case "hora":
                              tituloOpcion = horaVotada.format(context);
                              break;
                            case "ubicacion":
                              tituloOpcion =
                                ubicacionMap?["nombre"]?.toString() ?? "Ubicación";
                              break;
                            default:
                              tituloOpcion = "Opción";
                          }
                          final Widget tituloWidget = tipo == "ubicacion"
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ubicacionMap?["nombre"]?.toString() ?? "Ubicación",
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  if ((ubicacionMap?["direccion"]?.toString() ?? "").isNotEmpty)
                                    Text(
                                      ubicacionMap!["direccion"].toString(),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(tituloOpcion);
                          //TRAILING
                          Widget? trailingWidget;
                          if (tipo == "ubicacion") {
                            trailingWidget = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (ubicacionMap != null)
                                  IconButton(
                                    icon: const Icon(Icons.map_outlined),
                                    tooltip: "Ver en mapa",
                                    onPressed: () {
                                      showMap(context, mounted, ubicacionMap!);
                                    },
                                  ),
                                if (esAnfitrion)
                                  IconButton(
                                    icon: const Icon(Icons.push_pin_outlined),
                                    tooltip: "Fijar esta opción",
                                    onPressed: () async {
                                      final updates = <String, dynamic>{};
                                      updates["ubicacionEsEncuesta"] = false;
                                      updates["ubicacion"] = item["ubicacion"];
                                      await db.collection("planes").doc(planID).update(updates);
                                      setState(() {
                                        plan.addAll(updates);
                                      });
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Se fijó la opción seleccionada."),),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            );
                          } else if (esAnfitrion) {
                            trailingWidget = IconButton(
                              icon: const Icon(Icons.push_pin_outlined),
                              tooltip: "Fijar esta opción",
                              onPressed: () async {
                                final updates = <String, dynamic>{};
                                if (tipo == "fecha") {
                                  updates["fechaEsEncuesta"] = false;
                                  updates["fecha"] = item["fecha"];
                                } else if (tipo == "hora") {
                                  updates["horaEsEncuesta"] = false;
                                  updates["hora"] = item["hora"];
                                }
                                await db.collection("planes").doc(planID).update(updates);
                                setState(() {
                                  plan.addAll(updates);
                                });
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Se fijó la opción seleccionada."),
                                    ),
                                  );
                                }
                              },
                            );
                          }
                          return ListTile(
                            leading: Checkbox(
                              value: yaVoto,
                              onChanged: (value) async {
                                List<dynamic> votosActuales =
                                    List.from(item["votos"] ?? []);
                                if (votosActuales.contains(userID)) {
                                  votosActuales.remove(userID);
                                } else {
                                  votosActuales.add(userID);
                                }
                                items[index]["votos"] = votosActuales;
                                await db.collection("planes").doc(planID).update({
                                  fieldName: items,
                                });
                              },
                            ),
                            title: tituloWidget,
                            subtitle: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                GestureDetector(
                                  onTap: votos.isNotEmpty
                                      ? () async {
                                          final nombres = await _getUsersNames(votos);
                                          if (!mounted) return;
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            useSafeArea: true,
                                            showDragHandle: true,
                                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                            ),
                                            builder: (_) {
                                              return SizedBox(
                                                height: MediaQuery.of(context).size.height * 0.5,
                                                child: Column(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: Text(
                                                        "Personas que votaron",
                                                        style: Theme.of(context).textTheme.titleMedium,
                                                      ),
                                                    ),
                                                    const Divider(),
                                                    Expanded(
                                                      child: ListView.builder(
                                                        itemCount: nombres.length,
                                                        itemBuilder: (context, index) {
                                                          return ListTile(
                                                            title: Text(nombres[index]),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      : null,
                                  child: Text(
                                    "$cantidadVotos voto${cantidadVotos == 1 ? "" : "s"}$porcentajeTexto",
                                    style: TextStyle(
                                      decoration: votos.isNotEmpty ? TextDecoration.underline : null,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (esMasVotada && maxVotos > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Más votada",
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: trailingWidget,
                            onTap: () async {
                              List<dynamic> votosActuales =
                                  List.from(item["votos"] ?? []);
                              if (votosActuales.contains(userID)) {
                                votosActuales.remove(userID);
                              } else {
                                votosActuales.add(userID);
                              }
                              items[index]["votos"] = votosActuales;
                              await db.collection("planes").doc(planID).update({
                                fieldName: items,
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                // BOTÓN: FIJAR OPCIÓN MÁS VOTADA
                if (esAnfitrion)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.push_pin_outlined),
                        label: const Text("Fijar opción más votada"),
                        onPressed: () async {
                          final doc =
                              await db.collection("planes").doc(planID).get();
                          if (!doc.exists) return;
                          final data = doc.data() ?? {};
                          final List<dynamic> items =
                              List.from(data[fieldName] ?? []);
                          if (items.isEmpty) return;
                          int maxVotosLocal = -1;
                          int indexGanador = 0;
                          for (int i = 0; i < items.length; i++) {
                            final List<dynamic> votos =
                                (items[i]["votos"] as List?) ?? [];
                            if (votos.length > maxVotosLocal) {
                              maxVotosLocal = votos.length;
                              indexGanador = i;
                            }
                          }
                          final ganador = items[indexGanador];
                          final updates = <String, dynamic>{};
                          if (tipo == "fecha") {
                            updates["fechaEsEncuesta"] = false;
                            updates["fecha"] = ganador["fecha"];
                          } else if (tipo == "hora") {
                            updates["horaEsEncuesta"] = false;
                            updates["hora"] = ganador["hora"];
                          } else if (tipo == "ubicacion") {
                            updates["ubicacionEsEncuesta"] = false;
                            updates["ubicacion"] = ganador["ubicacion"];
                          }

                          await db.collection("planes").doc(planID).update(updates);
                          setState(() {
                            plan.addAll(updates);
                          });
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Se fijó la opción más votada."),
                              ),
                            );
                          }
                        },
                      ),
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

    //ES PROPIO
    final bool esPropio = (plan["anfitrionID"] ?? "") == widget.userID;
    //VISIBILIDAD
    final String visibilidad = plan["visibilidad"] ?? "Amigos";
    //ANFITRIÓN
    final String anfitrionNombre = plan["anfitrionNombre"] ?? "";
    //ICONO
    final IconData iconoNombre = iconosMap[plan["iconoNombre"]] ?? Icons.event;
    final Color iconoColor = coloresMap[plan["iconoColor"]] ?? secondary;
    //TÍTULO
    final String titulo = plan["titulo"] ?? "";
    //DESCRIPCIÓN
    final String descripcion = plan["descripcion"] ?? "";
    //FECHA
    bool fechaEsEncuesta = plan["fechaEsEncuesta"] ?? false;
    String fechaBonita;
    if (plan["fechaEsEncuesta"] == true) {
      fechaBonita = "Por determinar";
    } else if (plan["fecha"] is Timestamp) {
      fechaBonita = DateFormat("d 'de' MMMM 'de' y", "es_ES").format((plan["fecha"] as Timestamp).toDate());
    } else {
      fechaBonita = "Desconocida";
    }
    //HORA
    bool horaEsEncuesta = plan["horaEsEncuesta"] ?? false;
    String horaBonita;
    if (plan["horaEsEncuesta"] == true) {
      horaBonita = "Por determinar";
    } else if (plan["hora"] is String) {
      final partes = (plan["hora"] as String).split(":");
      final horaObj = TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
      horaBonita = horaObj.format(context);
    } else if (plan["hora"] is TimeOfDay) {
      horaBonita = (plan["hora"] as TimeOfDay).format(context);
    } else {
      horaBonita = "Desconocida";
    }
    //UBICACIÓN
    bool ubicacionEsEncuesta = plan["ubicacionEsEncuesta"] ?? false;
    Map<String, dynamic> ubicacion = {
      "nombre": "Casa Central, UTFSM",
      "latitud": -33.0458,
      "longitud": -71.6197,
    };
    if (plan["ubicacion"] is Map<String, dynamic>) {
      ubicacion = plan["ubicacion"];
    }
    if (plan["ubicacionEsEncuesta"] == true) {
      ubicacion = {
        "nombre": "Por determinar",
      };
    }
    //PARTICIPANTE
    final bool participantesAceptadosUsuario = participantesAceptados.contains(widget.userID);
    final bool participantesRechazadosUsuario = participantesRechazados.contains(widget.userID);

    return Scaffold(

      //APP BAR
      appBar: AppBar(
        title: Text(
          "Detalle del plan",
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
        actions: [
          if (esPropio) 
            IconButton(
              icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onPrimary),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (sheetContext) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //EDITAR
                        ListTile(
                          leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          title: Text("Editar plan", style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () async {
                            print("[🐧 planes] Editando plan: ${plan["planID"]}");
                            Navigator.pop(context);
                            final updatedPlanID = await Navigator.push<String?>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPlanScreen(plan: plan, userID: widget.userID, currentLocation: widget.currentLocation),
                              ),
                            );
                            if (updatedPlanID != null) {
                              try {
                                final doc = await db.collection("planes").doc(updatedPlanID).get();
                                if (doc.exists && doc.data() != null) {
                                  final updated = doc.data()!;
                                  setState(() {
                                    plan = Map<String, dynamic>.from(updated);
                                    participantesAceptados = List<dynamic>.from(updated["participantesAceptados"] ?? []);
                                    participantesRechazados = List<dynamic>.from(updated["participantesRechazados"] ?? []);
                                  });
                                }
                              } catch (e) {
                                print("[🐧 planes] Error al refetchear plan: $e");
                              }
                            }
                          },
                        ),
                        //ELIMINAR
                        ListTile(
                          leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          title: Text("Eliminar plan", style: Theme.of(context).textTheme.bodyLarge),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            final bool? confirmar = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text("Eliminar plan"),
                                  content: const Text("¿Estás seguro de que deseas eliminar este plan? Esta acción no se puede deshacer."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: Text("Cancelar", style: Theme.of(context).textTheme.bodyMedium),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                      child: Text("Eliminar", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onError)),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmar == true) {
                              final String? docId = _getPlanID();
                              if (docId == null || docId.isEmpty) {
                                print("[🐧 planes] Error al eliminar plan: no se encontró ID");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Error al eliminar plan.")),
                                  );
                                }
                                return;
                              }
                              print("[🐧 planes] Eliminando plan: $docId");
                              try {
                                await db.collection("planes").doc(docId).delete();
                                if (mounted) {
                                  Navigator.pop(context, "deleted"); //Volver y notificar eliminación
                                }
                              } catch (e) {
                                print("[🐧 planes] Error: $e");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error al eliminar plan.")),
                                  );
                                }
                              }
                            }
                          },
                        ),

                      ],
                    );
                  },
                );
              },
            ),
        ],
      ),

      //CUERPO
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            //ICONO
            Container(
              width: double.infinity,
              height: 120,
              color: iconoColor,
              alignment: Alignment.center,
              child: Icon(iconoNombre, color: Theme.of(context).colorScheme.onPrimary, size: 60),
            ),

            //CONTENIDO
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 4),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [

                        //VISIBILIDAD
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                visibilidad == "Amigos" ? Icons.group : Icons.public,
                                size: 24,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                visibilidad,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                              ),
                            ],
                          ),
                        ),

                        if (plan["categoria"] != null && (plan["categoria"] as String).isNotEmpty)
                          const SizedBox(width: 8),
                        
                        //CATEGORÍA
                        if (plan["categoria"] != null && (plan["categoria"] as String).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  categoriasMap[plan["categoria"]]?["icon"] as IconData? ?? Icons.label,
                                  size: 24,
                                  color: categoriasMap[plan["categoria"]]?["color"] as Color? ?? Theme.of(context).colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  plan["categoria"] as String,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (participantesAceptadosUsuario || participantesRechazadosUsuario)
                          const SizedBox(width: 8),

                      //ACEPTADO/RECHAZADO
                      if (participantesAceptadosUsuario || participantesRechazadosUsuario)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: participantesAceptadosUsuario 
                              ? Theme.of(context).colorScheme.tertiaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                participantesAceptadosUsuario ? Icons.check_circle : Icons.cancel,
                                size: 24,
                                color: participantesAceptadosUsuario 
                                  ? Theme.of(context).colorScheme.onTertiaryContainer
                                  : Theme.of(context).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                participantesAceptadosUsuario ? "Aceptado" : "Rechazado",
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: participantesAceptadosUsuario 
                                    ? Theme.of(context).colorScheme.onTertiaryContainer
                                    : Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  //ANFITRIÓN
                  Row(
                    children: [
                      Icon(Icons.star, size: 24, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        (esPropio)
                          ? "Creado por ti"
                          : "Creado por $anfitrionNombre",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  //TÍTULO
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  //DESCRIPCIÓN
                  Text(
                    descripcion,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                  ),

                  const SizedBox(height: 12),

                  //FECHA
                  SizedBox(
                    width: double.infinity,
                    child: IgnorePointer( 
                      ignoring: !fechaEsEncuesta,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: fechaEsEncuesta
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : Theme.of(context).colorScheme.surfaceContainer,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: fechaEsEncuesta
                          ? () {
                            _showEncuesta("fecha");
                          }
                          : () {},
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                fechaEsEncuesta ? Icons.poll : Icons.calendar_today,
                                size: 24,
                                color: fechaEsEncuesta
                                  ? Theme.of(context).colorScheme.onSecondaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: fechaEsEncuesta
                                  ? Text(
                                    "Vota por tu fecha favorita",
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : Text(
                                    fechaBonita,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                              ),
                              if (fechaEsEncuesta)
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  size: 15,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  //HORA
                  SizedBox(
                    width: double.infinity,
                    child: IgnorePointer(
                      ignoring: !horaEsEncuesta, // si no es encuesta, no se puede presionar
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: horaEsEncuesta
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.surfaceContainer,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: horaEsEncuesta
                            ? () {
                                _showEncuesta("hora");
                              }
                            : () {}, // vacío, no se ejecuta gracias a IgnorePointer
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                horaEsEncuesta ? Icons.poll : Icons.access_time,
                                size: 24,
                                color: horaEsEncuesta
                                    ? Theme.of(context).colorScheme.onSecondaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: horaEsEncuesta
                                    ? Text(
                                        "Vota por tu hora favorita",
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: Theme.of(context).colorScheme.onSecondaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      )
                                    : Text(
                                        horaBonita,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                      ),
                              ),
                              if (horaEsEncuesta)
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  size: 15,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  //UBICACIÓN
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: ubicacionEsEncuesta
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.surfaceContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        if (ubicacionEsEncuesta) {
                          _showEncuesta("ubicacion");
                        } else {
                          showMap(context, mounted, ubicacion);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              ubicacionEsEncuesta ? Icons.poll : Icons.location_on,
                              size: 24,
                              color: ubicacionEsEncuesta
                                ? Theme.of(context).colorScheme.onSecondaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ubicacionEsEncuesta
                                  ? Text(
                                    "Vota por tu ubicación favorita",
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (ubicacion["nombre"] ?? "") as String,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        (ubicacion["direccion"] ?? "") as String,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: ubicacionEsEncuesta
                                ? Theme.of(context).colorScheme.onSecondaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  
                  //VER PARTICIPANTES
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        _showParticipantesModal(context, participantesAceptados, participantesRechazados);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.group, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "Ver participantes",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Center(
                                child: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  //UNIRSE/ABANDONAR PLAN
                  if (!esPropio)
                    SizedBox(
                      width: double.infinity,
                      child: participantesAceptadosUsuario
                        ? OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            onPressed: () async {
                              setState(() {
                                participantesAceptados.remove(widget.userID);
                                if (!participantesRechazados.contains(widget.userID)) {
                                  participantesRechazados.add(widget.userID);
                                }
                              });
                              try {
                                await db.collection("planes").doc(plan["planID"]).update({
                                  "participantesAceptados": FieldValue.arrayRemove([widget.userID]),
                                  "participantesRechazados": FieldValue.arrayUnion([widget.userID]),
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Has abandonado el plan.")),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  participantesAceptados.add(widget.userID);
                                  participantesRechazados.remove(widget.userID);
                                });
                                print("[🐧 planes] Error al abandonar plan: $e");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Error al abandonar el plan.")),
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              Icons.exit_to_app,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            label: Text(
                              "Abandonar plan",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.secondary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: () async {
                              setState(() {
                                participantesRechazados.remove(widget.userID);
                                if (!participantesAceptados.contains(widget.userID)) {
                                  participantesAceptados.add(widget.userID);
                                }
                              });
                              try {
                                await db.collection("planes").doc(plan["planID"]).update({
                                  "participantesAceptados": FieldValue.arrayUnion([widget.userID]),
                                  "participantesRechazados": FieldValue.arrayRemove([widget.userID]),
                                });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Te has unido al plan.")),
                                  );
                                }
                              } catch (e) {
                                setState(() {
                                  participantesAceptados.remove(widget.userID);
                                });
                                print("[🐧 planes] Error al unirse al plan: $e");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Error al unirse al plan.")),
                                  );
                                }
                              }
                            },
                            icon: Icon(
                              Icons.check_circle,
                              size: 24,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ),
                            label: Text(
                              "Unirse al plan",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                    ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
