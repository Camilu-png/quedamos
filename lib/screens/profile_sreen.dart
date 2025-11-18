import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quedamos/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userID;

  const ProfileScreen({super.key, required this.userID});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .get()
          .timeout(const Duration(seconds: 10));

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

  // Cambiar foto
  Future<void> _changePhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      final file = File(picked.path);

      // Subir imagen a Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profilePictures')
          .child('${widget.userID}.jpg');

      await ref.putFile(file);

      final url = await ref.getDownloadURL();

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .update({'photoUrl': url});

      // Refrescar vista
      setState(() {});

    } catch (e) {
      print("Error al cambiar foto: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al subir la imagen")),
        );
      }
    }
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
              ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            color:
                              Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sin conexión. Mostrando datos básicos.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),

                // FOTO DE PERFIL + BOTÓN PARA CAMBIAR
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          photoUrl != null ? NetworkImage(photoUrl) : null,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                      child: photoUrl == null
                          ? Icon(Icons.person,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    GestureDetector(
                      onTap: _changePhoto,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 24),

                Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(email,
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),

                const SizedBox(height: 32),
                const Divider(thickness: 1.2),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        print("👾 Cerrando Sesión");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Icons.exit_to_app,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    label: Text(
                      "Cerrar sesión",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
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
