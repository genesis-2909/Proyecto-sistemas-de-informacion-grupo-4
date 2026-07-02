import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/eco_theme.dart';

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> {
  // 0 = Tabla Principal, 1 = Aprobar Operadores, 2 = Moderar Reseñas
  int _currentSubView = 0; 
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Contadores para las tarjetas KPI
  int _cantViajeros = 0;
  int _cantOperadores = 0;
  int _cantAdministradores = 0;

  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDatosAdmin();
  }

  // Carga de usuarios reales desde Firestore y cálculo de métricas
  Future<void> _fetchDatosAdmin() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('usuarios').get();
      List<Map<String, dynamic>> temporalUsers = [];
      int viajeros = 0;
      int operadores = 0;
      int admins = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['uid'] = doc.id; // Guardamos el UID para operaciones individuales
        temporalUsers.add(data);

        final String rol = data['rol'] ?? 'Viajero';
        if (rol == 'Administrador') {
          admins++;
        } else if (rol == 'Operador') {
          operadores++;
        } else {
          viajeros++;
        }
      }

      setState(() {
        _usuarios = temporalUsers;
        _cantViajeros = viajeros;
        _cantOperadores = operadores;
        _cantAdministradores = admins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoTheme.warmCream,
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        // 🛠️ MODIFICACIONES SOLICITADAS:
        centerTitle: true, // Centra el título en el medio de la barra
        automaticallyImplyLeading: false, // Elimina la flecha de retroceso de raíz
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDatosAdmin, // Mantiene la funcionalidad de volver a cargar intacta
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: EcoTheme.forestGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFiltrosSubVistas(),
                  const SizedBox(height: 20),
                  if (_currentSubView == 0) ...[
                    _buildTarjetasMetricas(),
                    const SizedBox(height: 20),
                    _buildBarraBusqueda(),
                    const SizedBox(height: 15),
                    _buildTablaUsuarios(),
                  ] else if (_currentSubView == 1) ...[
                    _buildSeccionAprobaciones(),
                  ] else ...[
                    _buildSeccionResenas(),
                  ]
                ],
              ),
            ),
    );
  }

  // --- COMPONENTES VISUALES ---

  Widget _buildFiltrosSubVistas() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildBotonFiltro('Usuarios', 0),
        _buildBotonFiltro('Solicitudes', 1),
        _buildBotonFiltro('Reseñas', 2),
      ],
    );
  }

  Widget _buildBotonFiltro(String label, int index) {
    final bool activo = _currentSubView == index;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: activo ? EcoTheme.forestGreen : Colors.white,
        foregroundColor: activo ? Colors.white : EcoTheme.darkForest,
        minimumSize: const Size(100, 40),
        elevation: activo ? 4 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () => setState(() => _currentSubView = index),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTarjetasMetricas() {
    return Row(
      children: [
        _buildKpiCard('Viajeros', _cantViajeros.toString(), Icons.person_outline, Colors.blue),
        const SizedBox(width: 10),
        _buildKpiCard('Operadores', _cantOperadores.toString(), Icons.directions_boat_outlined, Colors.orange),
        const SizedBox(width: 10),
        _buildKpiCard('Admins', _cantAdministradores.toString(), Icons.admin_panel_settings_outlined, Colors.red),
      ],
    );
  }

  Widget _buildKpiCard(String titulo, String valor, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EcoTheme.darkForest)),
            Text(titulo, style: const TextStyle(fontSize: 11, color: EcoTheme.softGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o correo...',
        prefixIcon: const Icon(Icons.search, color: EcoTheme.forestGreen),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildTablaUsuarios() {
    final filtrados = _usuarios.where((u) {
      final nombre = (u['nombre_completo'] ?? '').toString().toLowerCase();
      final correo = (u['correo_institucional'] ?? '').toString().toLowerCase();
      return nombre.contains(_searchQuery) || correo.contains(_searchQuery);
    }).toList();

    if (filtrados.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text('No se encontraron usuarios.')));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filtrados.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = filtrados[index];
          final String nombre = user['nombre_completo'] ?? 'No registrado';
          final String correo = user['correo_institucional'] ?? '';
          final String rol = user['rol'] ?? 'Viajero';

          return ListTile(
            title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('$correo\nRol actual: $rol', style: const TextStyle(fontSize: 12)),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (accion) {
                if (accion == 'editar') _abrirModalModificarRol(user);
                if (accion == 'eliminar') _eliminarUsuarioFirestore(user['uid']);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar Rol')])),
                const PopupMenuItem(value: 'eliminar', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Colors.red))])),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSeccionAprobaciones() {
    final pendientes = _usuarios.where((u) => u['estado_solicitud'] == 'Pendiente de Aprobación').toList();

    if (pendientes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 50, color: EcoTheme.forestGreen),
              SizedBox(height: 10),
              Text('No hay solicitudes de operador pendientes.', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pendientes.length,
      itemBuilder: (context, index) {
        final user = pendientes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(user['nombre_completo'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Solicita: ${user['rol_solicitado'] ?? 'Operador'}\nCorreo: ${user['correo_institucional'] ?? ''}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _rechazarSolicitud(user['uid'], 'estado_solicitud'),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => _cambiarRolVerificado(user['uid'], user['rol_solicitado'] ?? 'Operador'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeccionResenas() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text('Módulo de moderación de comentarios y estrellas (Próximamente).', style: TextStyle(color: EcoTheme.softGray)),
      ),
    );
  }

  // --- MÉTODOS DE EDICIÓN Y FIREBASE ---

  void _abrirModalModificarRol(Map<String, dynamic> user) {
    String selectedRol = user['rol'] ?? 'Viajero';
    String estadoSolicitud = user['estado_solicitud'] ?? 'Aprobado';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          title: Text('Modificar a ${user['nombre_completo']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedRol,
                items: ['Viajero', 'Operador', 'Administrador']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setStateModal(() => selectedRol = val!),
                decoration: const InputDecoration(labelText: 'Rol del Sistema'),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: estadoSolicitud,
                items: ['Aprobado', 'Pendiente de Aprobación', 'Rechazado']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setStateModal(() => estadoSolicitud = val!),
                decoration: const InputDecoration(labelText: 'Estado de la Solicitud'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('usuarios').doc(user['uid']).update({
                  'rol': selectedRol,
                  'estado_solicitud': estadoSolicitud,
                });
                Navigator.pop(context);
                _fetchDatosAdmin();
              },
              child: const Text('Guardar'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _eliminarUsuarioFirestore(String uid) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).delete();
    _fetchDatosAdmin();
  }

  Future<void> _cambiarRolVerificado(String uid, String nuevoRol) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'role': nuevoRol,
      'estado_solicitud': 'Aprobado',
    });
    _fetchDatosAdmin();
  }

  Future<void> _rechazarSolicitud(String uid, String campoLlave) async {
    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'estado_solicitud': 'Rechazado',
    });
    _fetchDatosAdmin();
  }
}