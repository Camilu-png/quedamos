import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quedamos/app_colors.dart';
import 'package:quedamos/text_styles.dart';
import 'package:quedamos/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userID;

  const ProfileScreen({super.key, required this.userID});

  Future<Map<String, dynamic>?> _getUserData() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userID).get();

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: Text(
            "Mi perfil",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            )
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
          elevation: 0,
        ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('No se encontraron datos del usuario.'),
            );
          }

          final data = snapshot.data!;
          final name = data['name'] ?? 'Usuario sin nombre';
          final email = data['email'] ?? 'Sin correo';
          final photoUrl = data['photoUrl'];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor.withOpacity(0.2),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Icon(Icons.person, size: 60, color: primaryColor)
                      : null,
                ),

                const SizedBox(height: 24),

                // Nombre y correo
                Text(name, style: subtitleText),
                const SizedBox(height: 8),
                Text(email, style: bodyPrimaryText.copyWith(color: Colors.grey[700])),

                const SizedBox(height: 32),
                const Divider(thickness: 1.2),

                // // Opciones de perfil
                // ListTile(
                //   leading: const Icon(Icons.person_outline, color: primaryColor),
                //   title: const Text('Editar perfil'),
                //   onTap: () {},
                // ),
                // ListTile(
                //   leading: const Icon(Icons.lock_outline, color: primaryColor),
                //   title: const Text('Cambiar contraseña'),
                //   onTap: () {},
                // ),
                // ListTile(
                //   leading: const Icon(Icons.help_outline, color: primaryColor),
                //   title: const Text('Ayuda'),
                //   onTap: () {},
                // ),

                const Spacer(),

                // Botón para cerrar sesión
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        print("👾 Cerrando Sesión");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
