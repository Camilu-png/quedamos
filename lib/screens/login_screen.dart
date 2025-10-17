import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'register_screen.dart';
import '../app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Función para hacer login
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      print("✅ Login OK: ${credential.user?.uid}");

      if (!mounted) return;

      // Navegar a la pantalla principal
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(userID: credential.user!.uid)),
      );
    } on FirebaseAuthException catch (e) {
      print("Error login");
      print(e.code);
    }
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Logo calendario
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

              // Input correo
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Dirección de correo electrónico",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Input contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Contraseña",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón ingresar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _login,
                  child: const Text(
                    "Ingresar",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Botón registrarse
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    "Registrarse",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Image.asset(
                    "assets/google_logo.png",
                    height: 24,
                  ),
                  onPressed: () {},
                  label: const Text(
                    "Ingresar con Google",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.grey),
                    backgroundColor: Colors.white,
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