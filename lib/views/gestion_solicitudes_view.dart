import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/eco_theme.dart';

class GestionSolicitudesView extends StatelessWidget {
  const GestionSolicitudesView({super.key});

  Future<void> _abrirDocumentoAval(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta solicitud no contiene un enlace válido.'),
        ),
      );
      return;
    }
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir la URL';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir el documento: $e')),
        );
      }
    }
  }

  Future<void> _aprobarUsuario(
    BuildContext context,
    String uid,
    String rolSolicitado,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'rol': rolSolicitado,
        'estado_solicitud': 'Aprobado',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud aprobada con éxito.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al aprobar: $e')));
      }
    }
  }

  Future<void> _rechazarUsuario(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'rol': 'Viajero',
        'estado_solicitud': 'Rechazado',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud rechazada correctamente.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al rechazar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTheme.warmCream,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            // Se sincroniza con el estado que pondrás al registrar en Firebase
            .where('estado_solicitud', isEqualTo: 'Pendiente de Aprobación')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: EcoTheme.darkForest),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay solicitudes de operador pendientes.',
                style: TextStyle(color: EcoTheme.softGray, fontSize: 14),
              ),
            );
          }

          final solicitudes = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: solicitudes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = solicitudes[index].data() as Map<String, dynamic>;
              final String uid = solicitudes[index].id;

              // 🔄 MAPEADO CORREGIDO Y BLINDADO:
              // Sincronizado con los nombres de campos estándar basados en el formulario de registro
              final String nombre =
                  user['nombre_completo'] ?? user['nombre'] ?? 'Sin nombre';
              final String correo =
                  user['correo'] ??
                  user['correo_institucional'] ??
                  'Sin correo';
              final String cedula = user['cedula'] ?? 'No registrada';
              final String rolSolicitado = user['rol_solicitado'] ?? 'operador';
              final String urlAval =
                  user['aval_url'] ?? user['documento_aval_url'] ?? '';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(
                              Icons.assignment_ind,
                              color: EcoTheme.darkForest,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  correo,
                                  style: const TextStyle(
                                    color: EcoTheme.softGray,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(),
                      ),
                      _buildDetailRow(Icons.badge_outlined, 'Cédula', cedula),
                      _buildDetailRow(
                        Icons.stars_rounded,
                        'Rol Solicitado',
                        rolSolicitado.toUpperCase(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: EcoTheme.darkForest,
                                side: const BorderSide(
                                  color: EcoTheme.darkForest,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.file_present_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Ver Aval',
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () =>
                                  _abrirDocumentoAval(context, urlAval),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red[700],
                            ),
                            icon: const Icon(Icons.close),
                            onPressed: () => _rechazarUsuario(context, uid),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFE8F5E9),
                              foregroundColor: EcoTheme.darkForest,
                            ),
                            icon: const Icon(Icons.check),
                            onPressed: () =>
                                _aprobarUsuario(context, uid, rolSolicitado),
                          ),
                        ],
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: EcoTheme.softGray),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: EcoTheme.darkForest,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: EcoTheme.darkForest, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
