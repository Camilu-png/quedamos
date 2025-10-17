import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../text_styles.dart';
import '../screens/plan_screen.dart';
import 'package:intl/intl.dart';


class PlanesList extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PlanesList({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final Color iconColor = plan['iconColor'] ?? Colors.grey;
    final int iconCode = plan['iconCode'] ?? Icons.event.codePoint;
    final IconData iconData = IconData(iconCode, fontFamily: 'MaterialIcons');
    //PUEDE QUE ESTÉN ALMACENADAS COMO TIMESTAMP, POR LO QUE HAY QUE HACER CONVERSIÓN TIMESTAMP -> DATETIME
    final DateTime fecha = plan['fecha'];
    final TimeOfDay hora = plan['hora'];
    final String fechaBonita = DateFormat('d \'de\' MMMM \'de\' y', 'es_ES').format(fecha);
    final String horaBonita = hora.format(context);

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
        print("[planes] Plan clickeado: ${plan['titulo']}");
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

              // ÍCONO
              Container(
                width: 80,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(iconData, color: Colors.white, size: 40),
                ),
              ),

              // INFORMACIÓN DEL PLAN
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        plan['anfitrion'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan['titulo'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$fechaBonita - $horaBonita',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            plan['ubicacion'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
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
