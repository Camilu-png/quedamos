import "package:flutter/material.dart";
import "package:url_launcher/url_launcher.dart";
import "package:quedamos/app_colors.dart";

final Map<String, IconData> iconosMap = {
  "event": Icons.event,
  "star": Icons.star,
  "home": Icons.home,
  "work": Icons.work,
  "favorite": Icons.favorite,
  "school": Icons.school,
  "shopping": Icons.shopping_cart,
  "restaurant": Icons.restaurant,
  "fitness": Icons.fitness_center,
  "travel": Icons.flight,
  "music": Icons.music_note,
  "movie": Icons.movie,
  "pets": Icons.pets,
  "beach": Icons.beach_access,
  "birthday": Icons.cake,
  "meeting": Icons.meeting_room,
  "coffee": Icons.coffee,
  "book": Icons.book,
  "camera": Icons.camera_alt,
};

final Map<String, Color> coloresMap = {
  "red": Colors.red,
  "pink": Colors.pink,
  "purple": Colors.purple,
  "deepPurple": Colors.deepPurple,
  "indigo": Colors.indigo,
  "blue": Colors.blue,
  "lightBlue": Colors.lightBlue,
  "cyan": Colors.cyan,
  "teal": Colors.teal,
  "green": Colors.green,
  "lightGreen": Colors.lightGreen,
  "lime": Colors.lime,
  "yellow": Colors.yellow,
  "amber": Colors.amber,
  "orange": Colors.orange,
  "deepOrange": Colors.deepOrange,
  "brown": Colors.brown,
  "grey": Colors.grey,
  "blueGrey": Colors.blueGrey,
  "secondary": secondary,
};

Future<void> showMap(BuildContext context, bool mounted, String ubicacion) async {
  print("[🐧 Planes: componentes] Abriendo mapa...");
  if (ubicacion.isEmpty) return;
  final query = Uri.encodeComponent(ubicacion);
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

//STRING -> TIME OF DAY
TimeOfDay? stringToTimeOfDay(String? s) {
  if (s == null || s.isEmpty) return null;
  final parts = s.split(":");
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

//TIME OF DAY -> STRING
  String timeOfDayToString(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, "0");
    final minute = t.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }

  //ICON DATA -> STRING
  String getIconName(IconData icon) {
    return iconosMap.entries
      .firstWhere((entry) => entry.value == icon,
          orElse: () => const MapEntry("event", Icons.event))
      .key;
  }

  //COLOR -> STRING
  String getColorName(Color color) {
    return coloresMap.entries
      .firstWhere((entry) => entry.value == color,
          orElse: () => const MapEntry("secondary", secondary))
      .key;
  }
  