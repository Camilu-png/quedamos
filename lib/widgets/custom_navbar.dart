import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  static const primaryColor = Color(0xFF3f51b5);
  static const Color primaryDark = Color(0xFF303F9F);

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.location_on,
              color: currentIndex == 0 ? Colors.black : Colors.white,
            ),
            onPressed: () => onTap(0),
          ),
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: currentIndex == 1 ? Colors.black : Colors.white,
            ),
            onPressed: () => onTap(1),
          ),

          // 🔹 Botón Add destacado
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(6),
                backgroundColor: primaryDark,
                foregroundColor:  currentIndex == 2 ? Colors.black : Colors.white,
                elevation: 4,
              ),
              onPressed: () => onTap(2),
              child: const Icon(Icons.add, size: 32),
            ),
          ),

          IconButton(
            icon: Icon(
              Icons.group,
              color: currentIndex == 3 ? Colors.black : Colors.white,
            ),
            onPressed: () => onTap(3),
          ),
          IconButton(
            icon: Icon(
              Icons.person,
              color: currentIndex == 4 ? Colors.black : Colors.white,
            ),
            onPressed: () => onTap(4),
          ),
        ],
      ),
    );
  }
}
