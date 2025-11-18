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

      //ACCIÓN
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

      child: Card(
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

                      //BADGES
                      Row(
                        children: [

                          //BADGE: DISTANCIA
                          if (currentLocation != null && plan["ubicacionEsEncuesta"] != true && plan["ubicacion"] != null && plan["ubicacion"] is Map<String, dynamic>)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.place,
                                    size: 15,
                                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    () {
                                      final ubicacion = plan["ubicacion"] as Map<String, dynamic>;
                                      // Robust parsing: accept int, double or String (with ',' or '.')
                                      final rawLat = ubicacion["latitud"];
                                      final rawLng = ubicacion["longitud"];
                                      double? latDouble;
                                      double? lngDouble;
                                      if (rawLat is double) latDouble = rawLat;
                                      else if (rawLat is int) latDouble = rawLat.toDouble();
                                      else if (rawLat is String) latDouble = double.tryParse(rawLat.replaceAll(',', '.'));

                                      if (rawLng is double) lngDouble = rawLng;
                                      else if (rawLng is int) lngDouble = rawLng.toDouble();
                                      else if (rawLng is String) lngDouble = double.tryParse(rawLng.replaceAll(',', '.'));

                                      if (latDouble != null && lngDouble != null) {
                                        final distanceMeters = Geolocator.distanceBetween(
                                          currentLocation!.latitude,
                                          currentLocation!.longitude,
                                          latDouble,
                                          lngDouble,
                                        );
                                        if (distanceMeters >= 1000) {
                                          return "${(distanceMeters / 1000).toStringAsFixed(1)} km";
                                        } else {
                                          return "${distanceMeters.toInt()} m";
                                        }
                                      }
                                      return "-";
                                    }(),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          //BADGE: CATEGORÍA
                          if (plan["categoria"] != null && (plan["categoria"] as String).isNotEmpty)
                            const SizedBox(width: 4),
                          if (plan["categoria"] != null && (plan["categoria"] as String).isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(categoriasMap[plan["categoria"]]?["icon"] ?? Icons.label, size: 15, color: categoriasMap[plan["categoria"]]?["color"] ?? Theme.of(context).colorScheme.onTertiaryContainer),
                                ],
                              ),
                            ),

                          //BADGE: ENCUESTA
                          if (plan["fechaEsEncuesta"] || plan["horaEsEncuesta"] || plan["ubicacionEsEncuesta"])
                            const SizedBox(width: 4),
                          if (plan["fechaEsEncuesta"] || plan["horaEsEncuesta"] || plan["ubicacionEsEncuesta"])
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.poll,
                                    size: 15,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ],
                              ),
                            ),

                          //BADGE: ACEPTADO/RECHAZADO
                          if (participantesAceptadosUsuario || participantesRechazadosUsuario)
                            const SizedBox(width: 4),
                          if (participantesAceptadosUsuario || participantesRechazadosUsuario)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                                    participantesAceptadosUsuario
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                    size: 15,
                                    color: participantesAceptadosUsuario
                                      ? Theme.of(context).colorScheme.onTertiaryContainer
                                      : Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                ],
                              ),
                            ),
                          
                        ]
                      ),

                      const SizedBox(height: 8),

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
                        if (!plan["fechaEsEncuesta"])
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
                        if (!plan["horaEsEncuesta"])
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
                      if (!plan["ubicacionEsEncuesta"])
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ubicacion["nombre"] ?? '',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant
                                    ),
                                  ),
                                ],
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
    );
  }
}
