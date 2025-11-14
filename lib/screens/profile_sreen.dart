import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quedamos/app_colors.dart';
import 'package:quedamos/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userID;

  const ProfileScreen({super.key, required this.userID});

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      // Add timeout to prevent infinite loading
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userID)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // Return null on timeout, will use Firebase Auth data as fallback
              throw TimeoutException('Timeout loading user data');
            },
          );

      return doc.data();
    } catch (e) {
      print('Error loading user data: $e');
      return null;
    }
  }

  Map<String, dynamic> _getFallbackUserData() {
    // Get data from Firebase Auth as fallback
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return {
        'name': currentUser.displayName ?? 'Usuario',
        'email': currentUser.email ?? 'Sin correo',
        'photoUrl': currentUser.photoURL,
      };
    }
    return {
      'name': 'Usuario',
      'email': 'Sin correo',
      'photoUrl': null,
    };
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
          // Show loading only briefly
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Use Firestore data if available, otherwise use Firebase Auth data
          final data = snapshot.hasData && snapshot.data != null
              ? snapshot.data!
              : _getFallbackUserData();

          final name = data['name'] ?? 'Usuario sin nombre';
          final email = data['email'] ?? 'Sin correo';
          final photoUrl = data['photoUrl'];
          
          // Show banner if using fallback data
          final isUsingFallback = !snapshot.hasData || snapshot.data == null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Offline banner
                if (isUsingFallback)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 20,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sin conexión. Mostrando datos básicos.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),

                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor.withValues(alpha: 0.2),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Icon(Icons.person, size: 60, color: primaryColor)
                      : null,
                ),

                const SizedBox(height: 24),

                // Nombre y correo
                Text(name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(email, 
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant
                              )
                              ),

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
                SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
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
                        child: Text(
                          "Cerrar Sesión",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
