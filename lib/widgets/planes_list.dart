import "package:intl/intl.dart";
import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/app_colors.dart";
import 'package:geolocator/geolocator.dart';
import "package:quedamos/screens/planes/planes_components.dart";
import "package:quedamos/screens/planes/plan_screen.dart";

class PlanesList extends StatelessWidget {
  final String userID;
  final Map<String, dynamic> plan;
  final Future<void> Function(BuildContext, Map<String, dynamic>)? onTapOverride;
  final Position? currentLocation;

  const PlanesList({
    super.key,
    required this.plan,
    required this.userID,
    this.onTapOverride,
    this.currentLocation,
  });

  @override
  Widget build(BuildContext context) {
    // ES PROPIO
    final bool esPropio = (plan["anfitrionID"] ?? "") == userID;
    // ANFITRIÓN
    final String anfitrionNombre = plan["anfitrionNombre"] ?? "";
    // ICONO
    final IconData iconoNombre =
        iconosMap[plan["iconoNombre"]] ?? Icons.event;
    final Color iconoColor =
        coloresMap[plan["iconoColor"]] ?? secondary;
    // TÍTULO
    final String titulo = plan["titulo"] ?? "";
    // FECHA
    String fechaBonita;
    if (plan["fechaEsEncuesta"] == true) {
      fechaBonita = "Por determinar";
    } else if (plan["fecha"] is Timestamp) {
      fechaBonita = DateFormat("d 'de' MMMM 'de' y", "es_ES")
          .format((plan["fecha"] as Timestamp).toDate());
    } else {
      fechaBonita = "Desconocida";
    }
    // HORA
    String horaBonita;
    if (plan["horaEsEncuesta"] == true) {
      horaBonita = "Por determinar";
    } else if (plan["hora"] is String) {
      final partes = (plan["hora"] as String).split(":");
      final horaObj =
          TimeOfDay(hour: int.parse(partes[0]), minute: int.parse(partes[1]));
      horaBonita = horaObj.format(context);
    } else if (plan["hora"] is TimeOfDay) {
      horaBonita = (plan["hora"] as TimeOfDay).format(context);
    } else {
      horaBonita = "Desconocida";
    }
    //UBICACIÓN
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
    //PARTICIPANTES (usar estado local)
    late List<dynamic> participantesAceptados = List<dynamic>.from(plan["participantesAceptados"] ?? []);
    late List<dynamic> participantesRechazados = List<dynamic>.from(plan["participantesRechazados"] ?? []);
    final bool participantesAceptadosUsuario = participantesAceptados.contains(userID);
    final bool participantesRechazadosUsuario = participantesRechazados.contains(userID);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      splashFactory: InkSparkle.splashFactory,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Theme.of(context).colorScheme.tertiary;
        }
        return null;
      }),
      highlightColor: Colors.transparent,

      // ACCIÓN
      onTap: () async {
        print("[🐧 planes] Plan clickeado: ${plan["planID"]}");
        if (onTapOverride != null) {
          await onTapOverride!(context, plan);
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlanScreen(plan: plan, userID: userID, currentLocation: currentLocation),
          ),
        );
      },

      child: Stack(
        children: [

          //CARD
          Card(
            color: Theme.of(context).colorScheme.surface,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 2,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //ICONO
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: iconoColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        iconoNombre,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 40
                      ),
                    ),
                  ),

                  //INFORMACIÓN
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //ANFITRIÓN
                          if (!esPropio)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "$anfitrionNombre te invita a:",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500
                                    ),
                                  ),
                                )
                              ],
                            ),
                          if (!esPropio) const SizedBox(height: 4),

                          //TÍTULO
                          Text(
                            titulo,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900
                            ),
                          ),
                          const SizedBox(height: 4),

                          Column(children: [
                            //FECHA
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    fechaBonita,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant
                                    ),
                                  ),
                                )
                              ],
                            ),
                            //HORA
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    horaBonita,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ]),
                          //UBICACIÓN
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ubicacion["nombre"].split(",")[0],
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant
                                  ),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  //FLECHA
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 15
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          //BADGE
          if (participantesAceptadosUsuario || participantesRechazadosUsuario)
            Positioned(
              top: 4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: participantesAceptadosUsuario
                      ? Color(0xFFC8E6C9)
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      participantesAceptadosUsuario
                        ? Icons.check_circle
                        : Icons.cancel,
                      size: 15,
                      color: participantesAceptadosUsuario
                        ? Color(0xFF0D2610)
                        : Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
