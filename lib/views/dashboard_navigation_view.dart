import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importaciones oficiales de tu proyecto
import 'buscar_rutas_view.dart';
import 'reservas_view.dart';
import 'profile_view.dart';
import 'operador_panel_view.dart';
import 'admin_panel_view.dart';
import 'landing_view.dart'; // 🚀 IMPORTANTE: Asegúrate de tener importada tu vista de inicio/login aquí

class DashboardNavigationView extends StatefulWidget {
  const DashboardNavigationView({super.key});

  @override
  State<DashboardNavigationView> createState() =>
      _DashboardNavigationViewState();
}

class _DashboardNavigationViewState extends State<DashboardNavigationView> {
  int _selectedIndex = 0;
  String _userRole = 'Viajero';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosDeFirestore();
  }

  Future<void> _cargarDatosDeFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;

          // 🔴 CONTROL DE SUSPENSIÓN EN TIEMPO REAL
          final bool isSuspendido = data['suspendido'] ?? false;
          if (isSuspendido) {
            final String motivo =
                data['motivo_suspension'] ??
                'Violación de las políticas generales de uso de la plataforma.';

            // 1. Cerramos la sesión en Firebase inmediatamente en segundo plano
            await FirebaseAuth.instance.signOut();

            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              // 2. Mostramos el cuadro restrictivo con redirección limpia al Home
              showDialog(
                context: context,
                barrierDismissible:
                    false, // No puede cerrarlo tocando la pantalla afuera
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Row(
                    children: [
                      Icon(
                        Icons.report_problem_rounded,
                        color: Colors.red,
                        size: 28,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Acceso Restringido',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Tu cuenta ha sido suspendida temporalmente por un administrador del sistema debido a:\n\n'
                    '⚠️ "$motivo"\n\n'
                    'Si consideras que esto es un error, por favor ponte en contacto con soporte institucional.',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[700],
                      ),
                      onPressed: () {
                        // 🚀 AQUÍ ESTÁ EL CAMBIO ESENCIAL:
                        // Cierra el cuadro de diálogo y limpia todo el stack de pantallas
                        // redirigiendo al usuario al LandingView (Home) de forma obligatoria.
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LandingView(),
                          ),
                          (route) =>
                              false, // Elimina todas las pantallas anteriores para que no pueda volver atrás
                        );
                      },
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }
            return; // Detiene por completo la carga de vistas internas
          }

          // 🟢 SI NO ESTÁ SUSPENDIDO (O FUE REACTIVADO), EL FLUJO SIGUE NORMAL COMO SI NADA HUBIESE PASADO:
          final String rolDetectado =
              (data['rol'] ?? data['tipo_usuario'] ?? 'Viajero')
                  .toString()
                  .trim();
          final String rolNormalizado = rolDetectado.toLowerCase();

          if (rolNormalizado == 'administrador' || rolNormalizado == 'admin') {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminPanelView()),
            );
            return;
          }

          setState(() {
            _userRole = rolDetectado;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
        ),
      );
    }

    final List<Widget> vistas = [
      const BuscarRutasView(),
      const ReservasView(),
      const ProfileView(),
    ];

    final List<BottomNavigationBarItem> barraItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore),
        label: 'Explorar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.assignment_turned_in_outlined),
        activeIcon: Icon(Icons.assignment_turned_in),
        label: 'Actividades',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    final String rolNormalizado = _userRole.toLowerCase().trim();

    if (rolNormalizado == 'operador' ||
        rolNormalizado == 'prestador de servicio') {
      vistas.add(const OperadorPanelView());
      barraItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          activeIcon: Icon(Icons.storefront),
          label: 'Operador',
        ),
      );
    }

    if (_selectedIndex >= vistas.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF2),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    spreadRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF1B5E20),
                unselectedItemColor: Colors.grey.shade400,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12,
                ),
                items: barraItems,
              ),
            ),
            Expanded(child: vistas[_selectedIndex]),
          ],
        ),
      ),
    );
  }
}
