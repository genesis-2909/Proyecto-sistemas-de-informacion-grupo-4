import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sitio_model.dart';

class CargarRutaView extends StatefulWidget {
  final SitioTuristico? sitioAEditar;

  const CargarRutaView({super.key, this.sitioAEditar});

  @override
  State<CargarRutaView> createState() => _CargarRutaViewState();
}

class _CargarRutaViewState extends State<CargarRutaView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioController;
  late TextEditingController _imagenController;

  // Lista exacta con las opciones de alojamiento que solicitaste
  final List<String> _opcionesAlojamiento = [
    'Posada',
    'Camping',
    'Hotel',
    'Cabaña',
    'Hostal',
    'Resort',
  ];

  // Opción por defecto configurada en la primera de la lista
  String _tipoAlojamiento = 'Posada';
  bool _tieneTransporte = false;
  bool _isSaving = false;

  bool get esEdicion => widget.sitioAEditar != null;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.sitioAEditar?.nombre ?? '',
    );
    _descripcionController = TextEditingController(
      text: widget.sitioAEditar?.descripcion ?? '',
    );
    _precioController = TextEditingController(
      text: widget.sitioAEditar?.costoMaximo != null
          ? widget.sitioAEditar!.costoMaximo.toString()
          : '',
    );
    _imagenController = TextEditingController(
      text:
          (widget.sitioAEditar?.imagenes != null &&
              widget.sitioAEditar!.imagenes.isNotEmpty)
          ? widget.sitioAEditar!.imagenes.first
          : '',
    );

    if (esEdicion) {
      _tieneTransporte = widget.sitioAEditar!.tieneTransporte;

      // Al editar, validamos que el valor guardado en base de datos exista en la lista nueva
      final tipoPrevio = widget.sitioAEditar!.tipoAlojamiento;
      if (_opcionesAlojamiento.contains(tipoPrevio)) {
        _tipoAlojamiento = tipoPrevio;
      } else {
        _tipoAlojamiento = 'Posada'; // Respaldo por defecto por si acaso
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _imagenController.dispose();
    super.dispose();
  }

  Future<void> _subirOActualizarPublicacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String urlImagen = _imagenController.text.trim().isNotEmpty
          ? _imagenController.text.trim()
          : 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=800';

      final List<String> listaImagenes = [urlImagen];

      final data = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'costo_maximo': double.parse(_precioController.text.trim()),
        'tipo_alojamiento':
            _tipoAlojamiento, // Aquí se guarda la opción seleccionada
        'tiene_transporte': _tieneTransporte,
        'id_operador': user.uid,
        'imagenes': listaImagenes,
      };

      if (esEdicion) {
        await FirebaseFirestore.instance
            .collection('publicaciones')
            .doc(widget.sitioAEditar!.id)
            .update(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Cambios guardados correctamente!')),
          );
          Navigator.pop(context);
        }
      } else {
        await FirebaseFirestore.instance.collection('publicaciones').add(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Oferta turística publicada con éxito!'),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF2),
      appBar: AppBar(
        title: Text(
          esEdicion ? 'Editar Hospedaje' : 'Publicar Hospedaje',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información del Destino',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del alojamiento / destino',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa un nombre válido'
                      : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación y descripción detallada',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa una descripción'
                      : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _precioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Precio por noche por persona (USD)',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el costo';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _imagenController,
                  decoration: const InputDecoration(
                    labelText: 'URL de la Imagen del alojamiento (Opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'https://ejemplo.com/imagen.jpg',
                  ),
                ),
                const SizedBox(height: 15),

                // Dropdown dinámico con tu lista exacta de tipos de alojamiento
                DropdownButtonFormField<String>(
                  value: _tipoAlojamiento,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Hospedaje',
                    border: OutlineInputBorder(),
                  ),
                  items: _opcionesAlojamiento.map((String opcion) {
                    return DropdownMenuItem<String>(
                      value: opcion,
                      child: Text(opcion),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() {
                    _tipoAlojamiento = value!;
                  }),
                ),

                const SizedBox(height: 15),
                SwitchListTile(
                  title: const Text(
                    '¿El destino cuenta con acceso a transporte público?',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _tieneTransporte,
                  activeColor: const Color(0xFF1B5E20),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) => setState(() {
                    _tieneTransporte = value;
                  }),
                ),
                const SizedBox(height: 30),
                _isSaving
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B5E20),
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _subirOActualizarPublicacion,
                        child: Text(
                          esEdicion
                              ? 'Guardar Cambios'
                              : 'Publicar Oferta Turística',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
