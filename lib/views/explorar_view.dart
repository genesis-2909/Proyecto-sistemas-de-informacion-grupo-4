import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sitio_model.dart';
import 'detalle_ruta_view.dart';

class ExplorarView extends StatefulWidget {
  final String?
  soloIdOperador; // ACOMODADO: Filtro opcional para vista espejo del operador

  const ExplorarView({
    super.key,
    this.soloIdOperador,
  }); // ACOMODADO: Constructor con parámetro opcional

  @override
  State<ExplorarView> createState() => _ExplorarViewState();
}

class _ExplorarViewState extends State<ExplorarView> {
  // --- VARIABLES DE ESTADO PARA LOS FILTROS ---
  final TextEditingController _presupuestoController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();

  String _tipoSeleccionado = 'Todos';
  String _calificacionSeleccionada = 'Cualquiera';

  final List<String> _tiposAlojamiento = [
    'Todos',
    'Posada',
    'Camping',
    'Hotel',
    'Cabaña',
    'Hostal',
    'Resort',
  ];
  final List<String> _calificaciones = ['Cualquiera', '4.5+', '4.0+', '3.5+'];

  @override
  void initState() {
    super.initState();
    _presupuestoController.addListener(() => setState(() {}));
    _ubicacionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _presupuestoController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TARJETA DE FILTROS INTERACTIVA
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE6),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Color(0xFF1E3F32)),
                    SizedBox(width: 12),
                    Text(
                      'Filtros de Búsqueda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3F32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: _buildTextField(
                        label: 'Presupuesto Máximo',
                        hint: 'Ej: 50',
                        controller: _presupuestoController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: _buildDropdownField(
                        label: 'Tipo de Alojamiento',
                        value: _tipoSeleccionado,
                        items: _tiposAlojamiento,
                        onChanged: (nuevoValor) {
                          setState(() {
                            _tipoSeleccionado = nuevoValor!;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: _buildTextField(
                        label: 'Ubicación / Descripción',
                        hint: 'Ej: Los Roques',
                        controller: _ubicacionController,
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: _buildDropdownField(
                        label: 'Calificación Mínima',
                        value: _calificacionSeleccionada,
                        items: _calificaciones,
                        onChanged: (nuevoValor) {
                          setState(() {
                            _calificacionSeleccionada = nuevoValor!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 2. RENDEREADO DE DATOS DESDE FIRESTORE
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ACOMODADO: Si viene soloIdOperador filtramos sus publicaciones, si no traemos todo global
              stream: widget.soloIdOperador != null
                  ? FirebaseFirestore.instance
                        .collection('publicaciones')
                        .where('id_operador', isEqualTo: widget.soloIdOperador)
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('publicaciones')
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al sincronizar hospedajes de red.'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3F32)),
                  );
                }

                // Evitamos duplicidad mapeando de manera estricta por el ID del documento de Firebase
                final Map<String, SitioTuristico> mapeoUnico = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  mapeoUnico[doc.id] = SitioTuristico.fromFirestore(
                    data,
                    doc.id,
                  );
                }

                final listadoSitios = mapeoUnico.values.toList();

                // Filtrado local en memoria
                final sitiosFiltrados = listadoSitios.where((sitio) {
                  final cumpleTipo =
                      _tipoSeleccionado == 'Todos' ||
                      sitio.tipoAlojamiento.toLowerCase() ==
                          _tipoSeleccionado.toLowerCase();

                  final cumpleUbicacion =
                      _ubicacionController.text.isEmpty ||
                      sitio.nombre.toLowerCase().contains(
                        _ubicacionController.text.toLowerCase(),
                      ) ||
                      sitio.descripcion.toLowerCase().contains(
                        _ubicacionController.text.toLowerCase(),
                      );

                  bool cumplePresupuesto = true;
                  if (_presupuestoController.text.isNotEmpty) {
                    final limite = double.tryParse(_presupuestoController.text);
                    if (limite != null) {
                      cumplePresupuesto = sitio.costoMaximo <= limite;
                    }
                  }

                  bool cumpleCalificacion = true;
                  if (_calificacionSeleccionada != 'Cualquiera') {
                    final califMin = double.parse(
                      _calificacionSeleccionada.replaceAll('+', ''),
                    );
                    const califDestino = 5.0;
                    cumpleCalificacion = califDestino >= califMin;
                  }

                  return cumpleTipo &&
                      cumpleUbicacion &&
                      cumplePresupuesto &&
                      cumpleCalificacion;
                }).toList();

                if (sitiosFiltrados.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay hospedajes disponibles que coincidan con los filtros 🔍',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sitiosFiltrados.length} destinos encontrados',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3F32),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sincronizados en tiempo real',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 380,
                            mainAxisSpacing: 24,
                            crossAxisSpacing: 24,
                            mainAxisExtent: 420,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final sitio = sitiosFiltrados[index];
                        return _buildFullDestinationCard(
                          context: context,
                          sitioModel: sitio,
                        );
                      }, childCount: sitiosFiltrados.length),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR: CAMPO DE TEXTO INTERACTIVO ---
  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF1E3F32),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET AUXILIAR: DROPDOWN ---
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.black54,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF1E3F32),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET AUXILIAR: TARJETA DE DESTINO ---
  Widget _buildFullDestinationCard({
    required BuildContext context,
    required SitioTuristico sitioModel,
  }) {
    final String imageUrl = sitioModel.imagenes.isNotEmpty
        ? sitioModel.imagenes.first
        : '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleRutaView(sitio: sitioModel),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: imageUrl.isEmpty
                        ? _buildImagePlaceholder()
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3F32),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sitioModel.tipoAlojamiento,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\$${sitioModel.costoMaximo.toInt()}/noc',
                        style: const TextStyle(
                          color: Color(0xFF1E3F32),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sitioModel.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3F32),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.blueGrey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sitioModel.descripcion,
                            style: TextStyle(
                              color: Colors.blueGrey.shade600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        const Text(
                          '5.0',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          ' (Eco)',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (sitioModel.tieneTransporte) ...[
                          Icon(
                            Icons.directions_bus_filled_outlined,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Transp.',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        sitioModel.descripcion,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildCardTag('Reserva Inmediata'),
                        if (sitioModel.tieneTransporte)
                          _buildCardTag('Ruta Segura'),
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
  }

  Widget _buildCardTag(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFEEEEEE),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Color(0xFFBDBDBD)),
      ),
    );
  }
}
