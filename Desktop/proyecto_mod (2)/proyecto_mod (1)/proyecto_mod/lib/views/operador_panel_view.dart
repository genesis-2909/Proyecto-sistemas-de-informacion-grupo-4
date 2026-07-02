import 'package:flutter/material.dart';

class OperadorPanelView extends StatefulWidget {
  const OperadorPanelView({super.key});

  @override
  State<OperadorPanelView> createState() => _OperadorPanelViewState();
}

class _OperadorPanelViewState extends State<OperadorPanelView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estructura de los destinos con todos los campos requeridos
  final List<Map<String, dynamic>> _destinos = [
    {'nombre': 'Hostal Playero Morrocoy', 'ubicacion': 'Morrocoy, Falcón', 'tipo': 'Hostal', 'precio': 25, 'invActual': 10, 'invTotal': 18, 'rating': 4.6, 'reviews': 42},
    {'nombre': 'Posada Colonial Coro', 'ubicacion': 'Coro, Falcón', 'tipo': 'Posada', 'precio': 30, 'invActual': 4, 'invTotal': 12, 'rating': 4.3, 'reviews': 31},
    {'nombre': 'Posada El Paraíso', 'ubicacion': 'Los Roques', 'tipo': 'Posada', 'precio': 45, 'invActual': 8, 'invTotal': 20, 'rating': 4.8, 'reviews': 24},
    {'nombre': 'Camping Montaña Aventura', 'ubicacion': 'Mérida', 'tipo': 'Camping', 'precio': 15, 'invActual': 15, 'invTotal': 30, 'rating': 4.5, 'reviews': 18}
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF2),
      appBar: AppBar(
        title: const Text('Panel Operador'), // 🛠️ CORREGIDO: Texto solicitado
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true, // 🛠️ CORREGIDO: Texto colocado en el medio
        automaticallyImplyLeading: false, // 🛠️ CORREGIDO: Se quita la flecha de retroceso de raíz
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.playlist_add_check), text: 'Mis Solicitudes'),
            Tab(icon: Icon(Icons.map_outlined), text: 'Mis Destinos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSeccionSolicitudes(),
          _buildSeccionDestinos(),
        ],
      ),
    );
  }

  Widget _buildSeccionSolicitudes() {
    return const Center(
      child: Text(
        'No tienes solicitudes de reserva pendientes.',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSeccionDestinos() {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF2),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1B5E20),
        onPressed: () => _abrirModalDestino(context), // Abrir en modo creación
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _destinos.length,
        itemBuilder: (context, index) {
          final dest = _destinos[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dest['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0C2E0E)),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _abrirModalDestino(context, destino: dest, index: index), // Modo edición
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmarEliminar(context, index, dest['nombre']),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(dest['ubicacion'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tipo: ${dest['tipo']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text('Precio: \$${dest['precio']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cupos: ${dest['invActual']} / ${dest['invTotal']}', style: const TextStyle(fontSize: 13)),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${dest['rating']} (${dest['reviews']})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _abrirModalDestino(BuildContext context, {Map<String, dynamic>? destino, int? index}) {
    final bool esEdicion = destino != null;

    final nombreController = TextEditingController(text: esEdicion ? destino['nombre'] : '');
    final ubicacionController = TextEditingController(text: esEdicion ? destino['ubicacion'] : '');
    final tipoController = TextEditingController(text: esEdicion ? destino['tipo'] : 'Posada');
    final precioController = TextEditingController(text: esEdicion ? destino['precio'].toString() : '');
    final invActualController = TextEditingController(text: esEdicion ? destino['invActual'].toString() : '');
    final invTotalController = TextEditingController(text: esEdicion ? destino['invTotal'].toString() : '');
    final ratingController = TextEditingController(text: esEdicion ? destino['rating'].toString() : '5.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(esEdicion ? 'Editar destino' : 'Agregar destino'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre del Hospedaje'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ubicacionController,
                decoration: const InputDecoration(labelText: 'Ubicación'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tipoController,
                decoration: const InputDecoration(labelText: 'Tipo (Posada, Hostal, Camping, etc.)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: precioController,
                      decoration: const InputDecoration(labelText: 'Precio'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ratingController,
                      decoration: const InputDecoration(labelText: 'Rating (0.0 - 5.0)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: invActualController,
                      decoration: const InputDecoration(labelText: 'Inv. Disponible'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: invTotalController,
                      decoration: const InputDecoration(labelText: 'Inv. Total'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
            onPressed: () {
              setState(() {
                final nuevoDestino = {
                  'nombre': nombreController.text.trim(),
                  'ubicacion': ubicacionController.text.trim(),
                  'tipo': tipoController.text.trim(),
                  'precio': int.tryParse(precioController.text.trim()) ?? 0,
                  'invActual': int.tryParse(invActualController.text.trim()) ?? 0,
                  'invTotal': int.tryParse(invTotalController.text.trim()) ?? 0,
                  'rating': double.tryParse(ratingController.text.trim()) ?? 5.0,
                  'reviews': esEdicion ? destino['reviews'] : 0,
                };

                if (esEdicion && index != null) {
                  _destinos[index] = nuevoDestino;
                } else {
                  _destinos.add(nuevoDestino);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, int index, String nombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar destino?'),
        content: Text('Esta acción eliminará definitivamente "$nombre".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _destinos.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}