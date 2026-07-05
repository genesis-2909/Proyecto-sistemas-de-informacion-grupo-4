import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🛠️ NUEVO IMPORT
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'views/landing_view.dart';
import 'views/dashboard_navigation_view.dart'; // 🛠️ NUEVO IMPORT
import 'theme/eco_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBPzdVG1GdWl7tj0r98AP1CC-4bOP6qj-4",
      authDomain: "ecorutas-8eb7a.firebaseapp.com",
      projectId: "ecorutas-8eb7a",
      storageBucket: "ecorutas-8eb7a.firebasestorage.app",
      messagingSenderId: "670067212234",
      appId: "1:670067212234:web:eb1688ce083a1b3808d933",
    ),
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthController())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoRutas Venezuela',
      debugShowCheckedModeBanner: false,
      theme: EcoTheme.luxuryTheme,

      // 🛠️ CONTROL DE TRÁFICO INTELIGENTE EN TIEMPO REAL:
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras Firebase verifica la sesión, muestra una pantalla de carga estéticamente limpia
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              ),
            );
          }

          // ¿Hay una sesión activa (Usuario logueado o recién registrado)?
          if (snapshot.hasData) {
            return const DashboardNavigationView(); // Entra directo al sistema
          }

          // Si no hay nadie logueado, se queda en la portada animada
          return const LandingView();
        },
      ),
    );
  }
}
