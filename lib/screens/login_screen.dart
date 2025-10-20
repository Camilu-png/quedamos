import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'register_screen.dart';
import "package:quedamos/app_colors.dart";
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  //CONTROLADORES
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
      // REVISAR PQ NO SIRVE UPDATE DE TOKEN
      String? token = await messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user?.uid)
            .update({'fcmToken': token});
      }

      print("[🕵️‍♀️ login] Login OK: ${credential.user?.uid}");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userID: credential.user!.uid)),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ocurrió un error. Por favor, intenta nuevamente."),
        ),
      );
      print("[🕵️‍♀️ login] Error: ${e.code}");
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
              Image.asset(
                "assets/logo.png",
                 height: 120,
                 ),
              const SizedBox(height: 16),
              const Text(
                "Quedamos?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),

              //INPUT: CORREO
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Dirección de correo electrónico",
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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

              const SizedBox(height: 16),

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

              const SizedBox(height: 16),

              //BOTÓN: REGISTRASE
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
                    "Registrarse",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    )
                  ),
                ),
              ),

              const SizedBox(height: 16),

              //BOTÓN: INGRESAR CON GOOGLE
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Image.asset(
                    "assets/google_logo.png",
                    height: 24,
                  ),
                  onPressed: () {},
                  label: Text(
                    "Ingresar con Google",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    )
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainerHigh),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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