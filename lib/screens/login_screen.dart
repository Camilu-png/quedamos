import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "main_screen.dart";
import "register_screen.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  //CONTROLADORES
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  //FUNCIÓN: LOGIN
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    if (
      email.isEmpty ||
      password.isEmpty
    ) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Por favor, completa todos los campos."),
        ),
      );
      return;
    }
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      // Comprobamos si el correo está verificado
      if (user != null && !user.emailVerified) {
        // Permitimos usuarios antiguos
        final creation = user.metadata.creationTime;
        final isOldUser = creation != null && creation.isBefore(DateTime(2025, 10, 22));
        if (!isOldUser) {
          await user.sendEmailVerification();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Tu correo aún no está verificado. Se envió un nuevo enlace a ${user.email}.",
              ),
            ),
          );
          await FirebaseAuth.instance.signOut();
          return;
        }
      }
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(credential.user?.uid)
            .update({"fcmToken": token});
      }
      print("[🐶 login] Login OK: ${credential.user?.uid}");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userID: credential.user!.uid)),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case "user-not-found":
          message = "No existe una cuenta con ese correo.";
          break;
        case "wrong-password":
          message = "La contraseña es incorrecta.";
          break;
        case "invalid-email":
          message = "El formato del correo no es válido.";
          break;
        case "too-many-requests":
          message = "Demasiados intentos fallidos. Intenta más tarde.";
          break;
        default:
          message = "Ocurrió un error. Por favor, intenta nuevamente.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      print("[🐶 login] Error: ${e.code}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              //LOGO
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  "assets/logo.png",
                  height: 120,
                ),
              ),

              const SizedBox(height: 16),

              //TÍTULO
              Text(
                "Quedamos?",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [

                    //INPUT: CORREO
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        labelText: "Correo electrónico",
                        floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, ingresa un correo electrónico.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    //INPUT: CONTRASEÑA
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        labelText: "Contraseña",
                        floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, ingresa un título.";
                        }
                        return null;
                      },
                    ),

                    //¿OLVIDASTE TU CONTRASEÑA?
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final TextEditingController resetController = TextEditingController();
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              title: Text(
                                "Restablecer contraseña",
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: TextFormField(
                                controller: resetController,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.email_outlined),
                                  labelText: "Correo electrónico",
                                  floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Por favor, ingresa un correo electrónico.";
                                  }
                                  return null;
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("Cancelar", style: Theme.of(context).textTheme.bodyMedium),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
                                  onPressed: () async {
                                    final email = resetController.text.trim();
                                    if (email.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Por favor, ingresa tu correo."),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      await FirebaseAuth.instance
                                          .sendPasswordResetEmail(email: email);
                                      if (!mounted) return;
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Se envió un enlace de recuperación a $email.",
                                          ),
                                        ),
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      String message = "Error al enviar el correo.";
                                      if (e.code == "user-not-found") {
                                        message = "No existe una cuenta con ese correo.";
                                      }
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(message)));
                                    }
                                  },
                                  child: Text("Enviar", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSecondary)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          "¿Olvidaste tu contraseña?",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),

                    //BOTÓN: INGRESAR
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
                        onPressed: _login,
                        child: Text(
                          "Ingresar",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                      ),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "¿No tienes una cuenta?",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                )
              ),

              const SizedBox(height: 16),

              //BOTÓN: REGISTRARME
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: Text(
                    "Registrarme",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    )
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}