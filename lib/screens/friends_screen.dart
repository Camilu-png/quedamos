import 'package:flutter/material.dart';
import '../widgets/friend_list.dart';
import '../widgets/custom_navbar.dart';
import '../app_colors.dart';


final List<Map<String, String>> friends = [
    {"name": "Alice", "photo": "/assets/logo.png"},
    {"name": "Bob", "photo": "/assets/logo.png"},
    {"name": "Charlie", "photo": "/assets/logo.png"},
  ];

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Amigos",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
          )
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: abrir formulario de nuevo amigo
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Nuevo amigo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          
            Expanded(
              child: FriendList(friends: friends),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3, 
        onTap: (index) {
          // TODO: Implementar la navegación entre pantallas
        },
      ),
    );
  }
}