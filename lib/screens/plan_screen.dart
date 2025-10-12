import "package:flutter/material.dart";
import "../app_colors.dart";
import '../text_styles.dart';

class PlanScreen extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PlanScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {

    final Color iconColor = plan["iconColor"] ?? primaryColor;
    final int iconCode = plan["iconCode"] ?? Icons.event.codePoint;
    final IconData iconData = IconData(iconCode, fontFamily: "MaterialIcons");
    final bool esPropio = plan["esPropio"] ?? false;

    //SCAFFOLD
    return Scaffold(

      //APP BAR
      appBar: AppBar(
        title: const Text(
          "Detalle del plan",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: primaryColor,
        elevation: 0,
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
              color: iconColor,
              alignment: Alignment.center,
              child: Icon(iconData, color: Colors.white, size: 60),
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
                          plan["visibilidad"] == "Amigos" ? Icons.group : Icons.public,
                          size: 24,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plan["visibilidad"] ?? "",
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
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: primaryColor,
                        child: Text(
                          (plan["anfitrion"] ?? "A")[0],
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (plan["esPropio"] ?? false)
                          ? "Creado por ti"
                          : "Creado por ${plan["anfitrion"] ?? ""}",
                        style: bodyPrimaryText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  //TÍTULO
                  Text(
                    plan["titulo"] ?? "",
                    style: titleText,
                  ),

                  const SizedBox(height: 12),

                  //DESCRIPCIÓN
                  Text(
                    plan["descripcion"] ?? "",
                    style: bodyPrimaryText,
                  ),

                  const SizedBox(height: 12),

                  //FECHA Y HORA
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 24, color: primaryText),
                      const SizedBox(width: 4),
                      Text(
                        "${plan["fecha"] ?? ""} - ${plan["hora"] ?? ""}",
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
                        plan["ubicacion"] ?? "",
                        style: bodyPrimaryText,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

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
                            const Icon(Icons.location_on, color: primaryText, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "Ver ubicación en mapa",
                              style: bodyPrimaryText.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
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
                        const SizedBox(width: 12),
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
