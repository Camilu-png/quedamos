import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "main_screen.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  //CONTROLADORES
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true; //Mostrar/ocultar contraseña

  //FUNCIÓN: MOSTRAR ERRORES
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  //FUNCIÓN: REGISTRO
  Future<void> _register() async {
    
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("Por favor, completa todos los campos.");
      return;
    }
    if (password != confirmPassword) {
      _showError("Las contraseñas no coinciden.");
      return;
    }
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final userID = credential.user?.uid;
      String? token = await messaging.getToken();
        if (token != null) {
        // Crear el documento del usuario en Firestore
          await FirebaseFirestore.instance.collection("users").doc(userID).set({
            "name": name,
            "email": email,
            "fcmToken": token,
          });
        }
      await credential.user?.sendEmailVerification();

      if (userID != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(userID: userID),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "weak-password") {
        print("The password provided is too weak.");
      } else if (e.code == "email-already-in-use") {
        print("The account already exists for that email.");
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        surfaceTintColor: Theme.of(context).colorScheme.primaryContainer,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
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
                "Registro",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

                    //INPUT: NOMBRE
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person),
                        labelText: "Nombre completo",
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
                          return "Por favor, ingresa un nombre.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    //INPUT: CORREO
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
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
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        labelText: "Contraseña",
                        floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, ingresa una contraseña.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    //CONFIRMAR CONTRASEÑA
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline),
                        labelText: "Repetir contraseña",
                        floatingLabelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor, ingresa una contraseña.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    //BOTÓN: REGISTRO
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)
                          ),
                        ),
                        child: Text(
                          "Registrarse",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                      ),
                    ),

                  ]
                )
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
