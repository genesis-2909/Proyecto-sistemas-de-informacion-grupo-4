import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionSolicitudesView extends StatelessWidget {
  const GestionSolicitudesView({super.key});

  Future<void> _aprobarUsuario(BuildContext context, String uid, String rolSolicitado) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'rol': rolSolicitado,
        'estado_solicitud': 'Aprobado',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario aprobado como $rolSolicitado')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar la aprobación')),
        );
      }
    }
  }

  Future<void> _rechazarUsuario(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'estado_solicitud': 'Rechazado',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud rechazada')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al denegar la solicitud')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes de Roles'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('estado_solicitud', isEqualTo: 'Pendiente de Aprobación')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay solicitudes pendientes.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final solicitudes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: solicitudes.length,
            itemBuilder: (context, index) {
              final usuario = solicitudes[index];
              final data = usuario.data() as Map<String, dynamic>;
              final String uid = usuario.id;
              final String nombre = data['nombre_completo'] ?? 'Sin Nombre';
              final String rolSolicitado = data['rol_solicitado'] ?? 'Operador';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Solicita el rol: $rolSolicitado'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rechazarUsuario(context, uid),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _aprobarUsuario(context, uid, rolSolicitado),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}