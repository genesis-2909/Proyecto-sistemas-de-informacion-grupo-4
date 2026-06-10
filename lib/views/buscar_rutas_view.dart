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
  double _presupuestoMaximo = 100.0;
  String _tipoAlojamiento = 'Todos';
  bool _soloConTransporte = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoRutas - Buscar Destinos'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.green.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Presupuesto Máximo: \$${_presupuestoMaximo.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _presupuestoMaximo,
                  min: 5.0,
                  max: 200.0,
                  divisions: 39,
                  activeColor: const Color(0xFF1B5E20),
                  inactiveColor: Colors.grey,
                  onChanged: (value) {
                    setState(() {
                      _presupuestoMaximo = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Alojamiento:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: _tipoAlojamiento,
                      items: const [
                        DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'Posada', child: Text('Posadas')),
                        DropdownMenuItem(value: 'Camping', child: Text('Campings')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _tipoAlojamiento = value ?? 'Todos';
                        });
                      },
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Solo con Transporte Público', style: TextStyle(fontWeight: FontWeight.bold)),
                  value: _soloConTransporte,
                  activeColor: const Color(0xFF1B5E20),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (value) {
                    setState(() {
                      _soloConTransporte = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('publicaciones').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay rutas disponibles creadas en Firebase.'));
                }

                List<SitioTuristico> todosLosSitios = snapshot.data!.docs.map((doc) {
                  return SitioTuristico.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                List<SitioTuristico> sitiosFiltrados = todosLosSitios.where((sitio) {
                  final cumplePrecio = sitio.costoMaximo <= _presupuestoMaximo;
                  final cumpleAlojamiento = _tipoAlojamiento == 'Todos' || sitio.tipoAlojamiento == _tipoAlojamiento;
                  final cumpleTransporte = !_soloConTransporte || sitio.tieneTransporte;
                  return cumplePrecio && cumpleAlojamiento && cumpleTransporte;
                }).toList();

                if (sitiosFiltrados.isEmpty) {
                  return const Center(child: Text('Ningún destino económico coincide con tus filtros.'));
                }

                return ListView.builder(
                  itemCount: sitiosFiltrados.length,
                  itemBuilder: (context, index) {
                    final sitio = sitiosFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleRutaView(sitio: sitio),
                            ),
                          );
                        },
                        leading: const Icon(Icons.landscape, color: Color(0xFF1B5E20), size: 40),
                        title: Text(sitio.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${sitio.descripcion}\nTransporte: ${sitio.tieneTransporte ? "Sí" : "No"} - Tipo: ${sitio.tipoAlojamiento}'),
                        trailing: Text('\$${sitio.costoMaximo.toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        isThreeLine: true,
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