import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_messaging/firebase_messaging.dart";
import "main_screen.dart";

class VerifyEmailScreen extends StatefulWidget {
  final String name;

  const VerifyEmailScreen({super.key, required this.name});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {

  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (user != null && user.emailVerified) {
      final String userID = user.uid;
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await FirebaseFirestore.instance.collection("users").doc(userID).set({
          "name": widget.name,
          "email": user.email,
          "fcmToken": token,
        });
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(userID: userID),
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tu correo aún no está verificado.")),
      );
    }
  }

  Future<void> _resendVerification() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Se envió un nuevo correo de verificación.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.primary,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        surfaceTintColor: colors.primaryContainer,
        iconTheme: IconThemeData(color: colors.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              "Verifica tu correo",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [

                  Text(
                    "Te enviamos un correo de verificación.\nPor favor revisa tu bandeja y confirma tu cuenta.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // BOTÓN "YA VERIFIQUÉ"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _checkEmailVerified,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        "Ya verifiqué",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // REENVIAR CORREO
                  TextButton(
                    onPressed: _resendVerification,
                    child: Text(
                      "Reenviar correo",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
