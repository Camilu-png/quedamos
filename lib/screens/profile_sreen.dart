import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quedamos/screens/login_screen.dart';

// Opciones de avatar (puedes editar/añadir las que quieras)
const List<String> kAvatarOptions = [
  "https://cataas.com/cat/calico?width=200&height=200",
  "https://cataas.com/cat/black?width=200&height=200",
  "https://cataas.com/cat/orange?width=200&height=200",
  "https://cataas.com/cat/gray?width=200&height=200",
  "https://cataas.com/cat/tabby?width=200&height=200",
  "https://cataas.com/cat?width=200&height=200",
];

class ProfileScreen extends StatefulWidget {
  final String userID;

  const ProfileScreen({super.key, required this.userID});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _getUserData();
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      // Add timeout to prevent infinite loading
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
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

  Future<void> _updateUserPhoto(String url) async {
    try {
      // Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .update({'photoUrl': url});

      // Opcional: actualizar también Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.updatePhotoURL(url);
      }

      // Volver a cargar datos para refrescar la UI
      setState(() {
        _userFuture = _getUserData();
      });
    } catch (e) {
      print("Error actualizando foto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No se pudo actualizar la foto de perfil")),
        );
      }
    }
  }

  Future<void> _showAvatarSelector() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Elige tu avatar",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              // Opciones en "filas" usando Wrap (se adaptan al ancho)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kAvatarOptions.map((url) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context, url); // devolvemos la url elegida
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      await _updateUserPhoto(selected);
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
        future: _userFuture,
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

                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),

                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: _showAvatarSelector,
                  icon: Icon(Icons.edit_outlined, size: 16, color: Theme.of(context).colorScheme.onSurface),
                  label: Text("Cambiar foto de perfil", style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.underline,
                  )),
                ),

                const SizedBox(height: 24),

                // Nombre y correo
                Text(
                  name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),

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
