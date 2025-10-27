import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'app_colors.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // Inicializa intl para español
  await initializeDateFormatting('es', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quedamos?',
      theme: ThemeData(
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontFamily: 'Montserrat'),
          
          bodyLarge: TextStyle(fontFamily: 'Roboto'),
          bodyMedium: TextStyle(fontFamily: 'Roboto'),
          bodySmall: TextStyle(fontFamily: 'Roboto'),
        ),
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF3F51B5),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFC5CAE9),
          onPrimaryContainer: Color(0xFF1A237E),
          secondary: Color(0xFFFF5722),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFFFCCBC),
          onSecondaryContainer: Color(0xFFBF360C),
          tertiary: Color(0xFFC5CAE9),
          onTertiary: Color(0xFF212121),
          tertiaryContainer: Color(0xFFE8EAF6),
          onTertiaryContainer: Color(0xFF1A237E),
          surfaceContainerLowest: Color(0xFFFAFAFA),
          surfaceContainerLow: Color(0xFFF2F2F2),
          surfaceContainer: Color(0xFFECECEC),
          surfaceContainerHigh: Color(0xFFE0E0E0),
          surface: Color(0xFFF5F5F5),
          onSurface: Color(0xFF212121),
          outline: Color(0xFF737373),
          shadow: Colors.black,
          inverseSurface: Color(0xFF121212),
          onInverseSurface: Colors.white,
          error: Color(0xFFB00020),
          onError: Colors.white,
          errorContainer: Color(0xFFFFDAD6),
          onErrorContainer: Color(0xFF410001),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: primaryDark, // tu color
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: primaryDark,
            statusBarIconBrightness: Brightness.light,
          ),
        ),
      ),
      navigatorObservers: [routeObserver],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          // Mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Error
          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Ocurrió un error")),
            );
          }

          // Usuario logueado
          if (snapshot.data != null) {
            final user = snapshot.data!;
            return MainScreen(userID: user.uid);
          }

          // No hay usuario
          return const LoginScreen();
        },
      ),
    );
  }
}
