import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sitio_model.dart';
import 'detalle_ruta_view.dart';

class BuscarRutasView extends StatefulWidget {
  const BuscarRutasView({super.key});

  @override
  State<BuscarRutasView> createState() => _BuscarRutasViewState();
}

class _BuscarRutasViewState extends State<BuscarRutasView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  double _presupuestoMaximo = 300.0;
  String _tipoAlojamiento = 'Todos';
  String _ubicacionFiltro = 'Todas';

  final List<String> _tiposDisponibles = [
    'Todos',
    'Posada',
    'Camping',
    'Hotel',
    'Cabaña',
    'Hostal',
    'Resort',
  ];

  final List<String> _ubicacionesDisponibles = [
    'Todas',
    'Los Roques',
    'Morrocoy',
    'Mérida',
    'Galipán',
    'Canaima',
    'Choroní',
    'Caracas',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Widget auxiliar para las píldoras visuales
  Widget _buildPildoraVisual(String texto, Color colorFondo) {
    final bool esVerde = colorFondo == const Color(0xFF1B5E20);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: esVerde ? Colors.white : Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF2),
      body: SafeArea(
        child: Column(
          children: [
            // BARRA SUPERIOR DE BÚSQUEDA Y FILTROS
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Encuentra tu próximo destino',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF1B5E20),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _tipoAlojamiento,
                          decoration: InputDecoration(
                            labelText: 'Tipo',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _tiposDisponibles
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _tipoAlojamiento = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _ubicacionFiltro,
                          decoration: InputDecoration(
                            labelText: 'Ubicación',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: _ubicacionesDisponibles
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(
                                    u,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _ubicacionFiltro = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Text(
                        'Presupuesto máx: \$${_presupuestoMaximo.toInt()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: _presupuestoMaximo,
                          min: 10.0,
                          max: 500.0,
                          activeColor: const Color(0xFF1B5E20),
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (val) =>
                              setState(() => _presupuestoMaximo = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // LISTADO REAL DE FIRESTORE (REESTRUCTURADO Y BLINDADO)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('hospedajes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1B5E20),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay hospedajes publicados por operadores en este momento.',
                      ),
                    );
                  }

                  final todosLosDocs = snapshot.data!.docs;

                  final listaSitiosFiltrados = todosLosDocs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        final String nombre = data['nombre'] ?? '';
                        final String descripcion =
                            data['ubicacion'] ?? data['descripcion'] ?? '';
                        final double costoMaximo =
                            double.tryParse(
                              data['precio']?.toString() ??
                                  data['costo_maximo']?.toString() ??
                                  '0.0',
                            ) ??
                            0.0;
                        final String tipoAlojamiento =
                            data['tipo'] ??
                            data['tipo_alojamiento'] ??
                            'Posada';
                        final bool tieneTransporte =
                            data['incluye_transporte'] == true ||
                            data['tiene_transporte'] == true;
                        final String idOperador =
                            data['operador_id'] ?? data['id_operador'] ?? '';

                        // 🔥 AUDITORÍA MULTI-LLAVE PARA EXTRAER LA FOTO CORRETA
                        List<String> imgs = [];

                        if (data['imagen_url'] != null &&
                            data['imagen_url'].toString().trim().isNotEmpty) {
                          imgs.add(data['imagen_url'].toString().trim());
                        } else if (data['url'] != null &&
                            data['url'].toString().trim().isNotEmpty) {
                          imgs.add(data['url'].toString().trim());
                        } else if (data['foto'] != null &&
                            data['foto'].toString().trim().isNotEmpty) {
                          imgs.add(data['foto'].toString().trim());
                        } else if (data['imagen'] != null &&
                            data['imagen'].toString().trim().isNotEmpty) {
                          imgs.add(data['imagen'].toString().trim());
                        } else if (data['imagenes'] != null) {
                          try {
                            imgs = List<String>.from(data['imagenes']);
                          } catch (_) {}
                        }

                        // Si tras verificar todo sigue vacío, se aplica el fallback elegante de respaldo
                        if (imgs.isEmpty) {
                          imgs.add(
                            'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=500',
                          );
                        }

                        return SitioTuristico(
                          id: doc.id,
                          nombre: nombre,
                          descripcion: descripcion,
                          costoMaximo: costoMaximo,
                          tipoAlojamiento: tipoAlojamiento,
                          tieneTransporte: tieneTransporte,
                          idOperador: idOperador,
                          imagenes: imgs,
                        );
                      })
                      .where((sitio) {
                        final String query = _searchQuery.toLowerCase();
                        if (query.isNotEmpty &&
                            !sitio.nombre.toLowerCase().contains(query)) {
                          return false;
                        }
                        if (_tipoAlojamiento != 'Todos' &&
                            sitio.tipoAlojamiento != _tipoAlojamiento) {
                          return false;
                        }
                        if (_ubicacionFiltro != 'Todas' &&
                            !sitio.descripcion.toLowerCase().contains(
                              _ubicacionFiltro.toLowerCase(),
                            )) {
                          return false;
                        }
                        if (sitio.costoMaximo > _presupuestoMaximo) {
                          return false;
                        }
                        return true;
                      })
                      .toList();

                  if (listaSitiosFiltrados.isEmpty) {
                    return const Center(
                      child: Text('Ningún hospedaje coincide con los filtros.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: listaSitiosFiltrados.length,
                    itemBuilder: (context, index) {
                      final sitio = listaSitiosFiltrados[index];
                      final String urlAMostrar = sitio.imagenes.isNotEmpty
                          ? sitio.imagenes.first
                          : 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=500';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalleRutaView(sitio: sitio),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                                child: Image.network(
                                  urlAMostrar,
                                  width: 130,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 130,
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF1B5E20,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  sitio.tipoAlojamiento,
                                                  style: const TextStyle(
                                                    color: Color(0xFF1B5E20),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    color: Colors.amber,
                                                    size: 14,
                                                  ),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    '5.0',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            sitio.nombre,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            sitio.descripcion,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${sitio.costoMaximo.toInt()}/noc',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B5E20),
                                            ),
                                          ),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 2,
                                            children: [
                                              _buildPildoraVisual(
                                                'WiFi',
                                                Colors.grey.shade100,
                                              ),
                                              if (sitio.tieneTransporte)
                                                _buildPildoraVisual(
                                                  'Transporte',
                                                  const Color(0xFF1B5E20),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
