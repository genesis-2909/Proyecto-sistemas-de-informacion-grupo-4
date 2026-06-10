import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CargarRutaView extends StatefulWidget {
  const CargarRutaView({super.key});

  @override
  State<CargarRutaView> createState() => _CargarRutaViewState();
}

class _CargarRutaViewState extends State<CargarRutaView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  
  String _tipoAlojamiento = 'Posada';
  bool _tieneTransporte = false;
  bool _isSaving = false;

  Future<void> _subirPublicacion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('publicaciones').add({
          'nombre': _nombreController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'costo_maximo': double.parse(_precioController.text.trim()),
          'tipo_alojamiento': _tipoAlojamiento,
          'tiene_transporte': _tieneTransporte,
          'id_operador': user.uid,
          'imagenes': [], 
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Destino turístico publicado con éxito!'), backgroundColor: Colors.green),
          );
          _nombreController.clear();
          _descripcionController.clear();
          _precioController.clear();
          setState(() { _tieneTransporte = false; });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Oferta Turística'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre del Lugar / Destino'),
                  validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción del Servicio'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _precioController,
                  decoration: const InputDecoration(labelText: 'Costo por noche (\$ USD)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  initialValue: _tipoAlojamiento,
                  decoration: const InputDecoration(labelText: 'Tipo de Hospedaje'),
                  items: const [
                    DropdownMenuItem(value: 'Posada', child: Text('Posada')),
                    DropdownMenuItem(value: 'Camping', child: Text('Camping')),
                  ],
                  onChanged: (value) => setState(() { _tipoAlojamiento = value!; }),
                ),
                const SizedBox(height: 15),
                SwitchListTile(
                  title: const Text('¿El destino cuenta con acceso a transporte público?'),
                  value: _tieneTransporte,
                  activeThumbColor: const Color(0xFF1B5E20),
                  onChanged: (value) => setState(() { _tieneTransporte = value; }),
                ),
                const SizedBox(height: 30),
                _isSaving
                    ? const CircularProgressIndicator(color: Color(0xFF1B5E20))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: _subirPublicacion,
                        child: const Text('Publicar Destino Low-Cost'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}