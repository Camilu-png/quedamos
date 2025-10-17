import "package:intl/intl.dart";
import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:quedamos/app_colors.dart";
import "package:quedamos/planes_components.dart";
import "package:quedamos/screens/plan_screen.dart";

class PlanesList extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PlanesList({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    //ANFITRIÓN
    final String anfitrionNombre = plan["anfitrionNombre"] ?? "";
    //ICONO
    final IconData iconoNombre = iconosMap[plan["iconoNombre"]] ?? Icons.event;
    final Color iconoColor = coloresMap[plan["iconoColor"]] ?? secondary;
    //TÍTULO
    final String titulo = plan["titulo"] ?? "";
    //FECHA
    String fechaBonita;
    if (plan["fechaEsEncuesta"] == true) {
      fechaBonita = "Por determinar";
    } else if (plan["fecha"] is Timestamp) {
      fechaBonita = DateFormat("d 'de' MMMM 'de' y", "es_ES").format((plan["fecha"] as Timestamp).toDate());
    } else {
      fechaBonita = "Desconocida";
    }
    //HORA
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
    String ubicacion = plan["ubicacion"] ?? "";
    if (plan["ubicacionEsEncuesta"] == true) {
      ubicacion = "Por determinar";
    }

    return InkWell(

      borderRadius: BorderRadius.circular(12),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return primaryColor.withAlpha(30); 
        }
        return null;
      }),
      splashFactory: InkRipple.splashFactory,
      highlightColor: Colors.transparent,

      //ACCIÓN
      onTap: () {
        print("[planes] Plan clickeado: ${plan["titulo"]}");
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlanScreen(plan: plan)));
      },

      //CARD
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              //ICONO
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: iconoColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(iconoNombre, color: Colors.white, size: 40),
                ),
              ),

              //INFORMACIÓN DEL PLAN
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //ANFITRIÓN
                      Text(
                        anfitrionNombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      //TÍTULO
                      Text(
                        titulo,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            //FECHA - HORA
                            child: Text(
                              "$fechaBonita - $horaBonita",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            //UBICACIÓN
                            child: Text(
                              ubicacion,
                              style: const TextStyle(color: Colors.grey),
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
                padding: const EdgeInsets.only(right: 12.0),
                child: Center(
                  child: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
                ),
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
