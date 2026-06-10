import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservasView extends StatelessWidget {
  const ReservasView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis actividades'), 
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(child: Text('Por favor, inicia sesión para verificar tus transacciones.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reservas')
                  .where('id_viajero', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 65, color: Colors.grey),
                        SizedBox(height: 15),
                        Text(
                          'No posees actividades registradas actualmente.',
                          style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                final documentos = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    var datos = documentos[index].data() as Map<String, dynamic>;
                    
                    String destino = datos['nombre_destino'] ?? 'Destino Ecológico';
                    String estado = datos['estado_actual'] ?? 'Solicitado';
                    double monto = (datos['monto_total'] ?? 0.0).toDouble();
                    String fecha = datos['fecha_inicio'] ?? 'Pendiente';

                    Color colorEstado = estado == 'Pagado' ? Colors.green.shade700 : Colors.orange.shade700;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(destino, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text('Fecha de Viaje: $fecha', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Monto: \$${monto.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorEstado,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
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