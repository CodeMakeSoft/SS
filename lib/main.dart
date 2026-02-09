
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'features/auth/data/firebase_auth_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/layout/main_skeleton.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicialización de Firebase. 
    // Asegúrate de haber agregado google-services.json (Android) 
    // y GoogleService-Info.plist (iOS).
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Error inicializando Firebase (¿Faltan archivos de config?): $e");
  }

  runApp(const SmartSyncApp());
}

class SmartSyncApp extends StatelessWidget {
  const SmartSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    return MaterialApp(
      title: 'SmartSync Run',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Clean Background
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Deep Tech Blue
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF00B0FF), // Cyan Accent
          surface: Colors.white,
          onSurface: const Color(0xFF263238), // Dark Grey Text
        ),
        useMaterial3: true,
        // App Bar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF263238)),
          titleTextStyle: TextStyle(
            color: Color(0xFF263238), 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          // Si el estado es activo (hay usuario), vamos al Home
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user == null) {
              return const LoginScreen();
            }
            return const MainSkeleton();
          }

          // Mientras carga el estado de auth
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
