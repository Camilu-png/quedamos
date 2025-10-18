import "package:intl/intl.dart";
import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/app_colors.dart";
import "package:quedamos/text_styles.dart";
import "package:quedamos/planes_components.dart";
import "package:quedamos/screens/planes/planes_add_screen.dart";

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

  Future<void> _showMap(String location, BuildContext context) async {
    print("[🐧 planes] Abriendo mapa...");
    if (location.isEmpty) return;
    final query = Uri.encodeComponent(location);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    try {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo abrir el mapa")),
        );
      }
    }
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

  void _showModalParticipantes(BuildContext context, List<dynamic> participantesAceptados, List<dynamic> participantesRechazados) {
    print("[🐧 planes] Abriendo modal de participantes...");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 2, //Pestañas
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const TabBar(
                  tabs: [
                    //ACEPTADOS
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 24, color: Colors.green),
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
                          Icon(Icons.cancel, size: 24, color: Colors.red),
                          SizedBox(width: 8),
                          Text("Rechazados"),
                        ],
                      ),
                    ),
                  ],
                  labelColor: Colors.black,
                  indicatorColor: primaryColor,
                ),
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
    //PARTICIPANTES (usar estado local)
    final bool participantesAceptadosUsuario = participantesAceptados.contains(widget.userID);
    final bool participantesRechazadosUsuario = participantesRechazados.contains(widget.userID);

    //SCAFFOLD
    return Scaffold(

      //APP BAR
      appBar: AppBar(
        title: Text(
          "Detalle del plan",
          style: subtitleText.copyWith(
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: iconoColor,
        elevation: 0,
        actions: [
          if (esPropio) 
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (sheetContext) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        //EDITAR
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text("Editar plan"),
                          onTap: () async {
                            print("[🐧 planes] Editando plan: ${plan["planID"]}");
                            Navigator.pop(context); //Cerrar modal
                            final updatedPlanID = await Navigator.push<String?>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPlanesScreen(plan: plan, userID: widget.userID),
                              ),
                            );
                            if (updatedPlanID != null) {
                              try {
                                final doc = await db.collection('planes').doc(updatedPlanID).get();
                                if (doc.exists && doc.data() != null) {
                                  final updated = doc.data()!;
                                  setState(() {
                                    plan = Map<String, dynamic>.from(updated);
                                    participantesAceptados = List<dynamic>.from(updated["participantesAceptados"] ?? []);
                                    participantesRechazados = List<dynamic>.from(updated["participantesRechazados"] ?? []);
                                  });
                                }
                              } catch (e) {
                                print('[🐧 planes] Error al refetchear plan: $e');
                              }
                            }
                          },
                        ),

                        //ELIMINAR
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text("Eliminar plan"),
                          onTap: () async {
                            // cerrar el bottom sheet usando su propio contexto
                            Navigator.pop(sheetContext);
                            // luego abrir el diálogo usando el contexto exterior (build context)
                            final bool? confirmar = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text("Eliminar plan"),
                                  content: const Text("¿Estás seguro de que deseas eliminar este plan? Esta acción no se puede deshacer."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: const Text("Cancelar"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text("Eliminar"),
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
                                  Navigator.pop(context, 'deleted'); //Volver y notificar eliminación
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
              child: Icon(iconoNombre, color: Colors.white, size: 60),
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
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              visibilidad == "Amigos" ? Icons.group : Icons.public,
                              size: 24,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              visibilidad,
                              style: bodyPrimaryText.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
                            color: participantesAceptadosUsuario ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                participantesAceptadosUsuario ? Icons.check_circle : Icons.cancel,
                                size: 24,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                participantesAceptadosUsuario ? "Aceptado" : "Rechazado",
                                style: bodyPrimaryText.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
                      const Icon(Icons.star, size: 24, color: primaryText),
                      const SizedBox(width: 8),
                      Text(
                        (esPropio)
                          ? "Creado por ti"
                          : "Creado por $anfitrionNombre",
                        style: bodyPrimaryText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  //TÍTULO
                  Text(
                    titulo,
                    style: titleText,
                  ),

                  const SizedBox(height: 12),

                  //DESCRIPCIÓN
                  Text(
                    descripcion,
                    style: bodyPrimaryText,
                  ),

                  const SizedBox(height: 12),

                  //FECHA
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 24, color: primaryText),
                      const SizedBox(width: 4),
                      Text(
                        fechaBonita,
                        style: bodyPrimaryText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  //HORA
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 24, color: primaryText),
                      const SizedBox(width: 4),
                      Text(
                        horaBonita,
                        style: bodyPrimaryText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  //UBICACIÓN
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 24, color: primaryText),
                      const SizedBox(width: 4),
                      Text(
                        ubicacion,
                        style: bodyPrimaryText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (fechaEsEncuesta || horaEsEncuesta || ubicacionEsEncuesta)
                    //ENCUESTA
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                              const Icon(Icons.poll, color: Colors.white, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "Ver y participar en encuesta",
                                style: bodyPrimaryText.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Center(
                                  child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryLight,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showMap(ubicacion, context),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: primaryText, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                "Ver ubicación en mapa",
                                style: bodyPrimaryText.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Center(
                                  child: Icon(Icons.arrow_forward_ios, color: primaryText, size: 18),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _showModalParticipantes(context, participantesAceptados, participantesRechazados);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.group, color: primaryText, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "Ver participantes",
                              style: bodyPrimaryText.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Center(
                                child: Icon(Icons.arrow_forward_ios, color: primaryText, size: 18),
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
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              // Optimistic UI: update local state first
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
                                // rollback on error
                                setState(() {
                                  participantesRechazados.remove(widget.userID);
                                });
                                print('[🐧 planes] Error al actualizar rechazo: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Error al rechazar plan")),
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel, size: 24, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "Rechazar",
                                  style: bodyPrimaryText.copyWith(
                                    color: Colors.white,
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              // Optimistic UI: update local state first
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
                                // rollback on error
                                setState(() {
                                  participantesAceptados.remove(widget.userID);
                                });
                                print('[🐧 planes] Error al actualizar aceptación: $e');
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
                                  style: bodyPrimaryText.copyWith(
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
