import 'package:flutter/material.dart';

class ExplorarView extends StatefulWidget {
  const ExplorarView({super.key});

  @override
  State<ExplorarView> createState() => _ExplorarViewState();
}

class _ExplorarViewState extends State<ExplorarView> {
  // --- VARIABLES DE ESTADO PARA LOS FILTROS ---
  final TextEditingController _presupuestoController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  
  String _tipoSeleccionado = 'Todos';
  String _calificacionSeleccionada = 'Cualquiera';

  // Opciones para los menús desplegables
  final List<String> _tiposAlojamiento = ['Todos', 'Posada', 'Camping', 'Hotel', 'Cabaña'];
  final List<String> _calificaciones = ['Cualquiera', '4.5+', '4.0+', '3.5+'];

  // --- DATOS SIMULADOS ---
  final List<Map<String, dynamic>> _destinosCompletos = [
    {
      'title': 'Posada El Paraíso',
      'location': 'Los Roques',
      'rating': '4.8',
      'reviews': '24',
      'available': '8 disponibles',
      'description': 'Hermosa posada frente al mar con vista espectacular a las playas cristalinas de Los Roques.',
      'type': 'Posada',
      'price': 45, // Guardado como número para poder filtrar por presupuesto
      'tags': ['WiFi', 'Aire acondicionado', 'Desayuno incluido'],
      'image': '', 
    },
    {
      'title': 'Camping Montaña Aventura',
      'location': 'Mérida',
      'rating': '4.5',
      'reviews': '12',
      'available': '3 disponibles',
      'description': 'Disfruta del frío de los Andes acampando bajo las estrellas con seguridad guiada.',
      'type': 'Camping',
      'price': 15,
      'tags': ['Fogata', 'Guía', 'Duchas'],
      'image': 'https://images.unsplash.com/photo-1504280327395-5d2518e388ee?q=80&w=500&auto=format&fit=crop',
    },
    {
      'title': 'Posada Colonial Coro',
      'location': 'Falcón',
      'rating': '4.7',
      'reviews': '18',
      'available': '5 disponibles',
      'description': 'Habitaciones confortables en el corazón del centro histórico de Coro.',
      'type': 'Posada',
      'price': 30,
      'tags': ['WiFi', 'Estacionamiento', 'Piscina'],
      'image': '', 
    },
  ];

  // Lista que se mostrará en pantalla (filtrada en tiempo real)
  List<Map<String, dynamic>> _destinosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _destinosFiltrados = List.from(_destinosCompletos);

    // Escuchar cuando el usuario escribe para filtrar automáticamente sin presionar botones
    _presupuestoController.addListener(_aplicarFiltros);
    _ubicacionController.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _presupuestoController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE FILTRADO EN TIEMPO REAL ---
  void _aplicarFiltros() {
    setState(() {
      _destinosFiltrados = _destinosCompletos.where((destino) {
        // 1. Filtro de Tipo
        final cumpleTipo = _tipoSeleccionado == 'Todos' || destino['type'] == _tipoSeleccionado;

        // 2. Filtro de Ubicación
        final cumpleUbicacion = _ubicacionController.text.isEmpty ||
            destino['location'].toString().toLowerCase().contains(_ubicacionController.text.toLowerCase());

        // 3. Filtro de Presupuesto
        bool cumplePresupuesto = true;
        if (_presupuestoController.text.isNotEmpty) {
          final limite = double.tryParse(_presupuestoController.text);
          if (limite != null) {
            cumplePresupuesto = destino['price'] <= limite;
          }
        }

        // 4. Filtro de Calificación
        bool cumpleCalificacion = true;
        if (_calificacionSeleccionada != 'Cualquiera') {
          final califMin = double.parse(_calificacionSeleccionada.replaceAll('+', ''));
          final califDestino = double.parse(destino['rating']);
          cumpleCalificacion = califDestino >= califMin;
        }

        return cumpleTipo && cumpleUbicacion && cumplePresupuesto && cumpleCalificacion;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TARJETA DE FILTROS INTERACTIVA
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFF5EFE6),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
              ],
              border: Border.all(color: Colors.white, width: 2), 
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.tune_rounded, color: Color(0xFF1E3F32)),
                    SizedBox(width: 12),
                    Text('Filtros de Búsqueda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3F32))),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo Presupuesto (Entrada de texto)
                    Expanded(
                      child: _buildTextField(
                        label: 'Presupuesto Máximo',
                        hint: 'Ej: 50',
                        controller: _presupuestoController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Campo Tipo de Alojamiento (Desplegable Real)
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Tipo de Alojamiento',
                        value: _tipoSeleccionado,
                        items: _tiposAlojamiento,
                        onChanged: (nuevoValor) {
                          _tipoSeleccionado = nuevoValor!;
                          _aplicarFiltros();
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Campo Ubicación (Entrada de texto)
                    Expanded(
                      child: _buildTextField(
                        label: 'Ubicación',
                        hint: 'Ej: Los Roques',
                        controller: _ubicacionController,
                      ),
                    ),
                    const SizedBox(width: 20),
                    
                    // Campo Calificación Mínima (Desplegable Real)
                    Expanded(
                      child: _buildDropdownField(
                        label: 'Calificación Mínima',
                        value: _calificacionSeleccionada,
                        items: _calificaciones,
                        onChanged: (nuevoValor) {
                          _calificacionSeleccionada = nuevoValor!;
                          _aplicarFiltros();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // 2. TÍTULOS DE RESULTADOS DINÁMICOS
          Text(
            '${_destinosFiltrados.length} destinos encontrados',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3F32), letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text('Ordenados por popularidad', style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.6))),
          const SizedBox(height: 24),

          // 3. GALERÍA DE TARJETAS CON CLIC HABILITADO
          _destinosFiltrados.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('No hay destinos que coincidan con tu búsqueda 🔍', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _destinosFiltrados.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, 
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    mainAxisExtent: 450, 
                  ),
                  itemBuilder: (context, index) {
                    final dest = _destinosFiltrados[index];
                    return _buildFullDestinationCard(
                      context: context,
                      title: dest['title'],
                      location: dest['location'],
                      rating: dest['rating'],
                      reviews: dest['reviews'],
                      available: dest['available'],
                      description: dest['description'],
                      type: dest['type'],
                      price: '\$${dest['price']}/noche',
                      tags: List<String>.from(dest['tags']),
                      imageUrl: dest['image'],
                    );
                  },
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
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3F32), width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET AUXILIAR: DESPLEGABLE INTERACTIVO (DROPDOWN) ---
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item, style: const TextStyle(fontSize: 14)));
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E3F32), width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET AUXILIAR: TARJETA DE DESTINO CON DETECTOR DE CLIC (INKWELL) ---
  Widget _buildFullDestinationCard({
    required BuildContext context,
    required String title,
    required String location,
    required String rating,
    required String reviews,
    required String available,
    required String description,
    required String type,
    required String price,
    required List<String> tags,
    required String imageUrl,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Acción al clickear la posada
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seleccionaste: $title 🌴 ¡Pronto abriremos sus detalles!'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen o Placeholder
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      child: imageUrl.isEmpty 
                        ? _buildImagePlaceholder() 
                        : Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                          ),
                    ),
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.blue.shade700, borderRadius: BorderRadius.circular(20)),
                        child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Text(price, style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              // Datos de texto
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3F32)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.blueGrey.shade600),
                          const SizedBox(width: 4),
                          Text(location, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 18, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(' ($reviews)', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          const Spacer(),
                          Icon(Icons.people_outline, size: 16, color: Colors.blueGrey.shade600),
                          const SizedBox(width: 4),
                          Text(available, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(description, style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                          child: Text(tag, style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w500)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFEEEEEE),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 64, color: Color(0xFFBDBDBD)),
      ),
    );
  }
}