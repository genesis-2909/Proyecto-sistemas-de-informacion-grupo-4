import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    void cerrarSesion(BuildContext context) async {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginView()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil Unimetano'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () => cerrarSesion(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No hay sesión activa.'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }
                
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Error al sincronizar los datos de Firestore.'));
                }

                var datosUsuario = snapshot.data!.data() as Map<String, dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.greenAccent,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        'Nombre Completo: ${datosUsuario['nombre_completo'] ?? 'No registrado'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Correo Institucional: ${datosUsuario['correo_institucional'] ?? 'No registrado'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Tipo de Usuario: ${datosUsuario['tipo_usuario'] ?? 'Estudiante'}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 15),
                      Chip(
                        label: Text('Rol: ${datosUsuario['rol'] ?? 'Viajero'}'),
                        backgroundColor: Colors.green.withOpacity(0.2),
                      ),
                      const Spacer(), 
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => cerrarSesion(context),
                        icon: const Icon(Icons.power_settings_new),
                        label: const Text('Cerrar Sesión Activa', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}