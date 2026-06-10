import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_view.dart';
import 'buscar_rutas_view.dart';
import 'cargar_ruta_view.dart';
import 'reservas_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  String _rolUsuario = 'Viajero';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _obtenerRolUsuario();
  }

  Future<void> _obtenerRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _rolUsuario = doc.data()?['rol'] ?? 'Viajero';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20))),
      );
    }

    final List<Widget> vistas = [
      _rolUsuario == 'Prestador de Servicio'
          ? const CargarRutaView()
          : const BuscarRutasView(),
      const ReservasView(),
      const ProfileView(),
    ];

    return Scaffold(
      body: vistas[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1B5E20),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(_rolUsuario == 'Prestador de Servicio' ? Icons.add_photo_alternate : Icons.search),
            label: _rolUsuario == 'Prestador de Servicio' ? 'Publicar' : 'Explorar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Mis Actividades',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}