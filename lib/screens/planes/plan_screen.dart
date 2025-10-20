import "package:intl/intl.dart";
import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/app_colors.dart";
import "package:quedamos/screens/planes/planes_components.dart";
import "package:quedamos/screens/planes/plan_add_screen.dart";

final db = FirebaseFirestore.instance;

class PlanScreen extends StatefulWidget {
  final String userID;
  final Map<String, dynamic> plan;
  const PlanScreen({super.key, required this.plan, required this.userID});
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
    String ubicacion = plan["ubicacion"] ?? "";
    if (plan["ubicacionEsEncuesta"] == true) {
      ubicacion = "Por determinar";
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
                                builder: (context) => AddPlanScreen(plan: plan, userID: widget.userID),
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
                                print("[🐧 planes] ID del plan ausente, no se puede eliminar");
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("No se encontró el ID del plan para eliminar")),
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
                                    SnackBar(content: Text("Error al eliminar plan: $e")),
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

                  Row(
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

                      if (participantesAceptadosUsuario || participantesRechazadosUsuario)
                        const SizedBox(width: 8),

                      //ACEPTADO/RECHAZADO
                      if (participantesAceptadosUsuario || participantesRechazadosUsuario)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: participantesAceptadosUsuario ? Color(0xFFC8E6C9) : Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                participantesAceptadosUsuario ? Icons.check_circle : Icons.cancel,
                                size: 24,
                                color: participantesAceptadosUsuario 
                                  ? Color(0xFF0D2610)
                                  : Theme.of(context).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                participantesAceptadosUsuario ? "Aceptado" : "Rechazado",
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: participantesAceptadosUsuario 
                                    ? Color(0xFF0D2610)
                                    : Theme.of(context).colorScheme.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        ),

                    ],
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
                      fontWeight: FontWeight.w500,
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
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 24, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 4),
                      Text(
                        fechaBonita,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  //HORA
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 24, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 4),
                      Text(
                        horaBonita,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  //UBICACIÓN
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 24, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ubicacion,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (fechaEsEncuesta || horaEsEncuesta || ubicacionEsEncuesta)
                    //ENCUESTA
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          //ACCIÓN
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.poll, color: Theme.of(context).colorScheme.onSecondary, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "Ver y participar en encuesta",
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Center(
                                  child: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSecondary, size: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  //VER UBICACIÓN EN MAPA
                  if (!ubicacionEsEncuesta)
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
                        onPressed: () => showMap(context, mounted, ubicacion),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "Ver ubicación en mapa",
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
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
                  
                  if (!ubicacionEsEncuesta)
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
                                fontWeight: FontWeight.bold,
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

                  //ACEPTAR/RECHAZAR PLAN
                  if (!esPropio)
                    Row(
                      children: [

                        //BOTÓN: RECHAZAR
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Plan rechazado")),
                                );
                              } catch (e) {
                                setState(() {
                                  participantesRechazados.remove(widget.userID);
                                });
                                print("[🐧 planes] Error al actualizar rechazo: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Error al rechazar plan")),
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel, size: 24, color: Theme.of(context).colorScheme.onError),
                                SizedBox(width: 8),
                                Text(
                                  "Rechazar",
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onError,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),

                        //BOTÓN: ACEPTAR
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Plan aceptado")),
                                );
                              } catch (e) {
                                setState(() {
                                  participantesAceptados.remove(widget.userID);
                                });
                                print("[🐧 planes] Error al actualizar aceptación: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Error al aceptar plan")),
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 24, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "Aceptar",
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
  }
}
