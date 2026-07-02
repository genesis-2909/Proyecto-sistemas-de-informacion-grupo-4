import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importaciones originales intactas
import 'buscar_rutas_view.dart';
import 'reservas_view.dart';
import 'profile_view.dart';
import 'admin_panel_view.dart'; 
import 'operador_panel_view.dart'; 

class DashboardNavigationView extends StatefulWidget {
  const DashboardNavigationView({super.key});

  @override
  State<DashboardNavigationView> createState() => _DashboardNavigationViewState();
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
          setState(() {
            // Evaluamos ambos campos por si la cuenta se creó desde el panel o desde registro publico
            _userRole = (data['rol'] ?? data['tipo_usuario'] ?? 'Viajero').toString().trim();
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
      );
    }

    // 1. Reconstrucción exacta de tus vistas funcionales según el rol
    final List<Widget> vistas = [
      const BuscarRutasView(),
      const ReservasView(),
      const ProfileView(),
    ];

    // 2. Elementos de la barra de navegación (ahora ubicados arriba)
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

    // Convertimos a minúsculas y limpiamos espacios fantasmas de Firestore
    final String rolNormalizado = _userRole.toLowerCase().trim();

    // TU LÓGICA ORIGINAL RESTAURADA:
    // Si es administrador -> Se le añade Operador Y ADEMÁS Gestionar (Admin)
    if (rolNormalizado == 'administrador' || rolNormalizado == 'admin') {
      vistas.add(const OperadorPanelView());
      barraItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.storefront_outlined),
        activeIcon: Icon(Icons.storefront),
        label: 'Operador',
      ));

      vistas.add(const AdminPanelView());
      barraItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.admin_panel_settings_outlined),
        activeIcon: Icon(Icons.admin_panel_settings),
        label: 'Gestionar',
      ));
    } 
    // Si es operador únicamente -> Se le añade solo Operador
    else if (rolNormalizado == 'operador' || rolNormalizado == 'prestador de servicio') {
      vistas.add(const OperadorPanelView());
      barraItems.add(const BottomNavigationBarItem(
        icon: Icon(Icons.storefront_outlined),
        activeIcon: Icon(Icons.storefront),
        label: 'Operador',
      ));
    }

    // Seguridad de índice duplicado original intacto
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
                  )
                ]
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
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                items: barraItems,
              ),
            ),
            Expanded(
              child: vistas[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }
}