import 'package:intl/intl.dart';
import "package:flutter/material.dart";
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:quedamos/app_colors.dart";
import 'package:quedamos/text_styles.dart';
import 'package:quedamos/planes_components.dart';
import 'package:quedamos/screens/add_planes_screen.dart';

final db = FirebaseFirestore.instance;

class PlanScreen extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PlanScreen({super.key, required this.plan});

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

  @override
  Widget build(BuildContext context) {

    //ES PROPIO
    final bool esPropio = plan["esPropio"] ?? true;
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
                  builder: (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text("Editar plan"),
                          onTap: () {
                            Navigator.pop(context); //Cerrar modal
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddPlanesScreen(plan: plan),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text("Eliminar plan"),
                          onTap: () async {
                            Navigator.pop(context);
                            final bool? confirmar = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Eliminar plan"),
                                  content: const Text("¿Estás seguro de que deseas eliminar este plan? Esta acción no se puede deshacer."),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Cancelar"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text("Eliminar"),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirmar == true) {
                              try {
                                await db.collection("planes").doc(plan["planID"]).delete();

                                Navigator.pop(context); // Volver a la pantalla anterior después de eliminar
                              } catch (e) {
                                print(e);

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

                  //FECHA Y HORA
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 24, color: primaryText),
                      const SizedBox(width: 4),
                      Text(
                        '$fechaBonita - $horaBonita',
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
                        onPressed: () => _openMap(ubicacion, context),
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
                        //ACCIÓN
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
                        //BOTÓN RECHAZAR
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Plan rechazado")),
                              );
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
                        //BOTÓN ACEPTAR
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Plan aceptado")),
                              );
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
