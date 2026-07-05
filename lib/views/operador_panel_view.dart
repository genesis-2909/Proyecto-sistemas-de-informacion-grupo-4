import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/eco_theme.dart';
import '../models/sitio_model.dart';
import 'explorar_view.dart';
import 'cargar_ruta_view.dart';
import 'landing_view.dart';

class OperadorPanelView extends StatefulWidget {
  const OperadorPanelView({super.key});

  @override
  State<OperadorPanelView> createState() => _OperadorPanelViewState();
}

class _OperadorPanelViewState extends State<OperadorPanelView> {
  int _selectedIndex = 2; // Pestaña inicial por defecto (Reservas)

  @override
  Widget build(BuildContext context) {
    final List<Widget> secciones = [
      const ExplorarView(),
      const _VistaPublicaciones(),
      const _VistaGestionReservas(),
      const _VistaResenasCalificaciones(),
      const _VistaPerfilOperador(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF2),
      body: SafeArea(bottom: false, child: secciones[_selectedIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              spreadRadius: 4,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: EcoTheme.forestGreen,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.remove_red_eye_outlined, size: 22),
              activeIcon: Icon(Icons.remove_red_eye, size: 24),
              label: 'Vista Espejo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined, size: 22),
              activeIcon: Icon(Icons.layers, size: 24),
              label: 'Mis Ofertas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined, size: 22),
              activeIcon: Icon(Icons.assignment, size: 24),
              label: 'Reservas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_border_rounded, size: 22),
              activeIcon: Icon(Icons.star_rounded, size: 24),
              label: 'Reseñas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded, size: 22),
              activeIcon: Icon(Icons.person_rounded, size: 24),
              label: 'Mi Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 1. VISTA: MIS OFERTAS / PUBLICACIONES (DISEÑO SEGURO ADAPTATIVO)
// =========================================================================
class _VistaPublicaciones extends StatelessWidget {
  const _VistaPublicaciones();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Inicia sesión para ver tus publicaciones.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              const SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis Hospedajes',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: EcoTheme.darkForest,
                      ),
                    ),
                    Text(
                      'Administra y edita tus ofertas turísticas',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EcoTheme.forestGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(
                  'Nueva Oferta',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CargarRutaView(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('id_operador', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar datos.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: EcoTheme.forestGreen,
                    ),
                  );
                }

                final publicaciones = <SitioTuristico>[];
                if (snapshot.hasData && snapshot.data != null) {
                  for (var doc in snapshot.data!.docs) {
                    try {
                      final sitio = SitioTuristico.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                      publicaciones.add(sitio);
                    } catch (e) {
                      debugPrint('Error parseando documento ${doc.id}: $e');
                    }
                  }
                }

                if (publicaciones.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aún no has publicado ofertas turísticas. ¡Crea la primera! ✨',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: publicaciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final sitio = publicaciones[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: sitio.imagenes.isNotEmpty
                                ? Image.network(
                                    sitio.imagenes.first,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sitio.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: EcoTheme.darkForest,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sitio.tipoAlojamiento,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\$${sitio.costoMaximo.toInt()} USD / noche',
                                  style: const TextStyle(
                                    color: EcoTheme.forestGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CargarRutaView(sitioAEditar: sitio),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _confirmarEliminacion(context, sitio.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, String idDocumento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar publicación?'),
        content: const Text(
          'Esta acción no se puede deshacer y el hospedaje dejará de estar disponible para viajeros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('publicaciones')
                  .doc(idDocumento)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 2. VISTA: GESTIÓN DE RESERVAS (CORREGIDA PARA EVITAR RESTRICCIONES INFINITAS)
// =========================================================================
class _VistaGestionReservas extends StatelessWidget {
  const _VistaGestionReservas();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Inicia sesión para gestionar reservas.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solicitudes de Reserva',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: EcoTheme.darkForest,
            ),
          ),
          const Text(
            'Acepta, gestiona o cancela los viajes entrantes',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reservas')
                  .where('id_operador', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar solicitudes.'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: EcoTheme.forestGreen,
                    ),
                  );
                }

                final reservas = snapshot.data!.docs;

                if (reservas.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tienes solicitudes de reserva registradas. 📋',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: reservas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final resDoc = reservas[index];
                    final data = resDoc.data() as Map<String, dynamic>;

                    final String estado = data['estado_actual'] ?? 'Solicitado';
                    Color colorEstado = Colors.orange;

                    // Lógica extendida de colores según tus nuevos estados del flujo
                    if (estado == 'Aceptado') colorEstado = Colors.blue;
                    if (estado == 'Pagado') colorEstado = Colors.green;
                    if (estado == 'Disfrutado') colorEstado = Colors.teal;
                    if (estado == 'Rechazado') colorEstado = Colors.red;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['nombre_destino'] ?? 'Destino Turístico',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: EcoTheme.darkForest,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorEstado.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  estado.toUpperCase(),
                                  style: TextStyle(
                                    color: colorEstado,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            '📅 Fechas: ${data['fecha_inicio']} al ${data['fecha_fin']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '👥 Personas: ${data['cantidad_personas']}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '💰 Monto Total: \$${data['monto_total']} USD',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: EcoTheme.forestGreen,
                            ),
                          ),
                          if (estado == 'Solicitado') ...[
                            const SizedBox(height: 14),
                            // CORREGIDO: Se usa Wrap en lugar de Row para evitar desbordamiento horizontal infinito en la Web
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => FirebaseFirestore.instance
                                      .collection('reservas')
                                      .doc(resDoc.id)
                                      .update({'estado_actual': 'Rechazado'}),
                                  child: const Text('Rechazar'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: EcoTheme.forestGreen,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => FirebaseFirestore.instance
                                      .collection('reservas')
                                      .doc(resDoc.id)
                                      .update({'estado_actual': 'Aceptado'}),
                                  child: const Text('Aceptar Reserva'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. VISTA: RESEÑAS
// =========================================================================
class _VistaResenasCalificaciones extends StatelessWidget {
  const _VistaResenasCalificaciones();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reseñas e Historial',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: EcoTheme.darkForest,
            ),
          ),
          Text(
            'Lo que los viajeros opinan de tus hospedajes ecológicos',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 40),
          Center(
            child: Text(
              'Las valoraciones de tus destinos aparecerán sincronizadas en esta sección.',
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 4. VISTA: PERFIL OPERADOR
// =========================================================================
class _VistaPerfilOperador extends StatelessWidget {
  const _VistaPerfilOperador();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String nombre = 'Operador Turístico';
          String email = user?.email ?? 'sin_correo@eco.com';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            nombre = data['nombre'] ?? nombre;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mi Cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: EcoTheme.darkForest,
                ),
              ),
              const Text(
                'Información del perfil de operador certificado',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: EcoTheme.forestGreen,
                      child: Icon(
                        Icons.business_center,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: EcoTheme.darkForest,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 250,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    'CERRAR SESIÓN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LandingView(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
