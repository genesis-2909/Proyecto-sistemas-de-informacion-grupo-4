import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/eco_theme.dart';
import 'gestion_solicitudes_view.dart';
import 'landing_view.dart';

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> {
  int _currentIndex = 0;

  // Títulos oficiales para las 5 secciones requeridas
  final List<String> _titles = [
    'Dashboard Macro',
    'Control de Publicaciones',
    'Gestión de Operadores',
    'Control de Usuarios',
    'Mi Perfil Admin',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTheme.warmCream,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: EcoTheme.darkForest,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() {}),
              tooltip: 'Actualizar Dashboard',
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardSection(),
          _buildPublicacionesSection(),
          const GestionSolicitudesView(), // Vista de aprobación de documentos avales
          _buildControlUsuariosSection(),
          _buildPerfilSection(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: EcoTheme.darkForest,
        selectedItemColor: Colors.amberAccent,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Publicaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_outlined),
            activeIcon: Icon(Icons.gavel),
            label: 'Gestión',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SECCIÓN 1: DASHBOARD CON GRÁFICOS INTERACTIVOS (fl_chart) Y CONTADORES
  // =========================================================================
  Widget _buildDashboardSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        int totalViajeros = 0;
        int totalOperadores = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String rol = (data['rol'] ?? data['tipo_usuario'] ?? 'Viajero')
                .toString()
                .toLowerCase()
                .trim();
            if (rol == 'viajero') totalViajeros++;
            if (rol == 'operador' || rol == 'prestador de servicio') {
              totalOperadores++;
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Contadores en Tiempo Real superiores
            Row(
              children: [
                _buildCounterCard(
                  'Viajeros Activos',
                  totalViajeros.toString(),
                  Icons.directions_walk_rounded,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildCounterCard(
                  'Operadores',
                  totalOperadores.toString(),
                  Icons.airport_shuttle_rounded,
                  EcoTheme.forestGreen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .where(
                    'estado_solicitud',
                    isEqualTo: 'Pendiente de Aprobación',
                  )
                  .snapshots(),
              builder: (context, snapPend) {
                int pendientes = snapPend.hasData
                    ? snapPend.data!.docs.length
                    : 0;
                return _buildCounterCard(
                  'Publicaciones/Solicitudes Pendientes',
                  pendientes.toString(),
                  Icons.assignment_late_rounded,
                  Colors.orange[800]!,
                );
              },
            ),
            const SizedBox(height: 24),

            // GRÁFICO 1: Destinos más buscados
            const Text(
              'Destinos Más Buscados vs Rango de Precio',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: EcoTheme.darkForest,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: EcoTheme.luxuryCard(),
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 8,
                          color: EcoTheme.forestGreen,
                          width: 16,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 15,
                          color: Colors.amber,
                          width: 16,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 5,
                          color: EcoTheme.darkForest,
                          width: 16,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(toY: 11, color: Colors.teal, width: 16),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // GRÁFICO 2: Métricas de Transacciones
            const Text(
              'Métricas Financieras (Reservas Efectivas vs Canceladas)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: EcoTheme.darkForest,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              decoration: EcoTheme.luxuryCard(),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green[600],
                      value: 75,
                      title: '75% Reservas',
                      radius: 45,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.red[400],
                      value: 25,
                      title: '25% Canc.',
                      radius: 45,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // GRÁFICO 3: Tasa de Conversión Turística
            const Text(
              'Tasa de Conversión Turística (Búsqueda vs Reserva Efectiva)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: EcoTheme.darkForest,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: EcoTheme.luxuryCard(),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1.2),
                        FlSpot(1, 3.4),
                        FlSpot(2, 2.1),
                        FlSpot(3, 4.8),
                      ],
                      isCurved: true,
                      color: EcoTheme.forestGreen,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCounterCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: EcoTheme.luxuryCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: EcoTheme.darkForest,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: EcoTheme.softGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SECCIÓN 2: CONTROL DE PUBLICACIONES (ACTIVAR / DESACTIVAR)
  // =========================================================================
  Widget _buildPublicacionesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rutas').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: EcoTheme.forestGreen),
          );
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No hay rutas o publicaciones registradas.'),
          );
        }

        final rutas = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rutas.length,
          itemBuilder: (context, index) {
            final doc = rutas[index];
            final data = doc.data() as Map<String, dynamic>;
            final bool isActiva = data['activo'] ?? true;
            final String origen = data['origen'] ?? 'Sin especificar';
            final String destino = data['destino'] ?? 'Sin especificar';
            final String operador =
                data['nombre_operador'] ?? 'Operador del Sistema';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: EcoTheme.luxuryCard(),
              child: ListTile(
                title: Text(
                  '$origen ➔ $destino',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: EcoTheme.darkForest,
                  ),
                ),
                subtitle: Text(
                  'Dueño: $operador\nVisualización: ${isActiva ? "Visible en Explorar" : "Desactivada / Operador Notificado"}',
                ),
                trailing: Switch(
                  value: isActiva,
                  activeColor: EcoTheme.forestGreen,
                  inactiveThumbColor: Colors.red,
                  onChanged: (value) async {
                    await FirebaseFirestore.instance
                        .collection('rutas')
                        .doc(doc.id)
                        .update({'activo': value});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // SECCIÓN 4: CONTROL DE USUARIOS (TOTALMENTE EN VIVO Y CORREGIDO)
  // =========================================================================
  Widget _buildControlUsuariosSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: EcoTheme.forestGreen),
          );
        }
        final usuarios = snapshot.data!.docs;

        if (usuarios.isEmpty) {
          return const Center(
            child: Text('No hay usuarios registrados en el sistema.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            final doc = usuarios[index];
            final data = doc.data() as Map<String, dynamic>;
            final String name = data['nombre_completo'] ?? 'Sin Nombre';
            final String email = data['correo_institucional'] ?? 'Sin Correo';
            final String currentRol = data['rol'] ?? 'Viajero';
            final bool isSuspendido = data['suspendido'] ?? false;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: EcoTheme.luxuryCard(),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: isSuspendido
                      ? Colors.red[100]
                      : EcoTheme.forestGreen.withOpacity(0.1),
                  child: Icon(
                    isSuspendido ? Icons.block_flipped : Icons.person,
                    color: isSuspendido ? Colors.red : EcoTheme.forestGreen,
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Rol: $currentRol\n$email'),
                // Solución definitiva al error de renderizado usando SizedBox restrictivo
                trailing: SizedBox(
                  width: 110,
                  child: isSuspendido
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('usuarios')
                                .doc(doc.id)
                                .update({
                                  'suspendido': false,
                                  'motivo_suspension': FieldValue.delete(),
                                });
                          },
                          child: const Text(
                            'HABILITAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () =>
                              _mostrarDialogoSuspension(doc.id, name),
                          child: const Text(
                            'SUSPENDER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarDialogoSuspension(String uid, String nombreUsuario) {
    String motivoSeleccionado = 'Violación de los términos de servicio';
    final motivos = [
      'Violación de los términos de servicio',
      'Sospecha o intento de estafa reportado',
      'Comportamiento inadecuado con los viajeros',
      'Publicación de datos falsos o de rutas engañosas',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: EcoTheme.warmCream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Suspender a $nombreUsuario',
                style: const TextStyle(
                  color: EcoTheme.darkForest,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona la razón reglamentaria de la suspensión. Esto impactará de inmediato el perfil del usuario:',
                    style: TextStyle(fontSize: 12, color: EcoTheme.softGray),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: motivoSeleccionado,
                    isExpanded: true,
                    dropdownColor: EcoTheme.warmCream,
                    style: const TextStyle(
                      color: EcoTheme.darkForest,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    items: motivos
                        .map(
                          (motivo) => DropdownMenuItem(
                            value: motivo,
                            child: Text(motivo),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => motivoSeleccionado = val!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('usuarios')
                        .doc(uid)
                        .update({
                          'suspendido': true,
                          'motivo_suspension': motivoSeleccionado,
                        });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'CONFIRMAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // SECCIÓN 5: PERFIL DEL ADMINISTRADOR Y LOGOUT DIRECTO AL HOME
  // =========================================================================
  Widget _buildPerfilSection() {
    final User? adminFirebase = FirebaseAuth.instance.currentUser;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: EcoTheme.luxuryCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: EcoTheme.darkForest,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 50,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Administrador Central',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: EcoTheme.darkForest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                adminFirebase?.email ?? 'admin@correo.unimet.edu.ve',
                style: const TextStyle(
                  color: EcoTheme.softGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'CERRAR SESIÓN DE ADMINISTRACIÓN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
