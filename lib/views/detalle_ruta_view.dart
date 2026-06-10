import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sitio_model.dart';
import '../controllers/reserva_controller.dart';

class DetalleRutaView extends StatefulWidget {
  final SitioTuristico sitio;

  const DetalleRutaView({super.key, required this.sitio});

  @override
  State<DetalleRutaView> createState() => _DetalleRutaViewState();
}

class _DetalleRutaViewState extends State<DetalleRutaView> {
  final ReservaController _reservaCtrl = ReservaController();
  final TextEditingController _resenaController = TextEditingController();

  int _personas = 1;
  String _estadoFlujo = 'Disponible';
  String _idDocumentoReservaCreada = '';
  int _calificacionNueva = 5;

  // Rango de fechas seleccionado
  DateTimeRange? _fechasSeleccionadas;

  @override
  void initState() {
    super.initState();
    _verificarDisponibilidadInicial();
  }

  void _verificarDisponibilidadInicial() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(widget.sitio.id)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['disponible'] == false || data['estado'] == 'Ocupado') {
          setState(() {
            _estadoFlujo = 'Ocupado';
          });
        }
      }
    } catch (e) {
      debugPrint("Error inicialización: $e");
    }
  }

  // Selector de calendario nativo de Flutter
  void _seleccionarFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _fechasSeleccionadas,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechasSeleccionadas = picked;
      });
    }
  }

  // Formateador manual rápido para evitar el error de DateFormat
  String _formatearFecha(DateTime fecha) {
    String dia = fecha.day.toString().padLeft(2, '0');
    String mes = fecha.month.toString().padLeft(2, '0');
    return "$dia/$mes/${fecha.year}";
  }

  void _ejecutarReserva() async {
    if (_fechasSeleccionadas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, seleccione el rango de fechas para su estadía.',
          ),
        ),
      );
      return;
    }

    // CORRECCIÓN SOLVENTADA: Formateo nativo sin usar el paquete intl externo
    String fechaInicioFormateada = _formatearFecha(_fechasSeleccionadas!.start);
    String fechaFinFormateada = _formatearFecha(_fechasSeleccionadas!.end);

    String idCreado = await _reservaCtrl.crearSolicitudReserva(
      idOferta: widget.sitio.id,
      nombreDestino: widget.sitio.nombre,
      fechaInicio: fechaInicioFormateada,
      fechaFin: fechaFinFormateada,
      cantidadPersonas: _personas,
      precioNoche: widget.sitio.costoMaximo,
    );

    if (mounted) {
      setState(() {
        if (idCreado.isNotEmpty) {
          _idDocumentoReservaCreada = idCreado;
          _estadoFlujo = 'Solicitado';
        } else {
          _estadoFlujo = 'Ocupado';
        }
      });
    }
  }

  void _abrirPaypalSandbox() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaypalSandboxWidget(
        monto: widget.sitio.costoMaximo * _personas,
        onPagoExitoso: () async {
          setState(() {
            _estadoFlujo = 'Procesando Pago';
          });

          bool exito = await _reservaCtrl.procesarPagoReal(
            _idDocumentoReservaCreada,
          );

          if (mounted) {
            setState(() {
              _estadoFlujo = exito ? 'Pagado' : 'Ocupado';
            });
          }
        },
      ),
    );
  }

  void _agregarResena() async {
    if (_resenaController.text.trim().isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('publicaciones')
          .doc(widget.sitio.id)
          .collection('resenas')
          .add({
            'usuario': 'Usuario Unimetano',
            'comentario': _resenaController.text.trim(),
            'calificacion': _calificacionNueva,
            'fecha': Timestamp.now(),
          });
      _resenaController.clear();
      setState(() {
        _calificacionNueva = 5;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('¡Reseña añadida!')));
      }
    } catch (e) {
      debugPrint("Error reseña: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String textoFechas = _fechasSeleccionadas == null
        ? 'Toca para seleccionar fechas'
        : '${_formatearFecha(_fechasSeleccionadas!.start)} al ${_formatearFecha(_fechasSeleccionadas!.end)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sitio.nombre),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CONTENEDOR TEMPORAL SIN IMAGENES DE INTERNET
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 45,
                      color: Color(0xFF1B5E20),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Detalle de la Ruta Turística',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(label: Text(widget.sitio.tipoAlojamiento)),
                  Text(
                    '\$${widget.sitio.costoMaximo.toInt()} / Noche',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                widget.sitio.descripcion,
                style: const TextStyle(fontSize: 15),
              ),
              const Divider(height: 40),

              // SECCIÓN DE RESERVAS / CONFIGURACIÓN DE VIAJE
              if (_estadoFlujo == 'Disponible') ...[
                const Text(
                  'Fechas de Estadía:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _seleccionarFechas,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF1B5E20),
                        ),
                        const SizedBox(width: 10),
                        Text(textoFechas, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text('Viajeros: ', style: TextStyle(fontSize: 16)),
                    DropdownButton<int>(
                      value: _personas,
                      items: [1, 2, 3, 4, 5]
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text('$e')),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _personas = v!;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _ejecutarReserva,
                  child: const Text(
                    'Solicitar Reserva',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],

              if (_estadoFlujo == 'Solicitado') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  color: Colors.orange.withOpacity(0.1),
                  child: const Text(
                    'Estado: SOLICITADO.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003087),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: _abrirPaypalSandbox,
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text(
                    'Pagar con PayPal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],

              if (_estadoFlujo == 'Procesando Pago') ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF1B5E20)),
                        SizedBox(height: 10),
                        Text('Procesando transacción...'),
                      ],
                    ),
                  ),
                ),
              ],

              if (_estadoFlujo == 'Pagado') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.green[50],
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 50),
                      SizedBox(height: 10),
                      Text(
                        '¡PAGO APROBADO!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_estadoFlujo == 'Ocupado') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[50],
                  child: const Text(
                    'Ruta turística no disponible en este momento.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const Divider(height: 40),

              // SECCIÓN DE RESEÑAS E INTERACCIÓN DE ESTRELLAS
              const Text(
                'Reseñas de la Comunidad',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Calificación: '),
                  DropdownButton<int>(
                    value: _calificacionNueva,
                    items: [1, 2, 3, 4, 5]
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text('$s ⭐')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _calificacionNueva = v!;
                    }),
                  ),
                ],
              ),
              TextField(
                controller: _resenaController,
                decoration: const InputDecoration(
                  hintText: 'Añade un comentario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                  ),
                  onPressed: _agregarResena,
                  child: const Text(
                    'Enviar Reseña',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('publicaciones')
                    .doc(widget.sitio.id)
                    .collection('resenas')
                    .orderBy('fecha', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      'Sin reseñas de costos reales.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data =
                          snapshot.data!.docs[index].data()
                              as Map<String, dynamic>;
                      int est = data['calificacion'] ?? 5;
                      return Card(
                        child: ListTile(
                          title: Text(
                            data['usuario'] ?? 'Anónimo',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(data['comentario'] ?? ''),
                          trailing: Text('⭐' * est),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= COMPONENTE: SIMULADOR INTERACTIVO DE PAYPAL SANDBOX =================
class _PaypalSandboxWidget extends StatefulWidget {
  final double monto;
  final VoidCallback onPagoExitoso;

  const _PaypalSandboxWidget({
    required this.monto,
    required this.onPagoExitoso,
  });

  @override
  State<_PaypalSandboxWidget> createState() => _PaypalSandboxWidgetState();
}

class _PaypalSandboxWidgetState extends State<_PaypalSandboxWidget> {
  bool _cargandoPasarela = false;
  final _emailSandboxController = TextEditingController(
    text: 'unimet-buyer@sandbox.paypal.com',
  );

  void _procesarTransaccionSandbox() async {
    setState(() {
      _cargandoPasarela = true;
    });
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      Navigator.pop(context);
      widget.onPagoExitoso();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PayPal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF003087),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.yellow[700],
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'SANDBOX',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          if (!_cargandoPasarela) ...[
            Text(
              'Resumen del Pago Técnico:',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              '\$${widget.monto.toStringAsFixed(2)} USD',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailSandboxController,
              decoration: const InputDecoration(
                labelText: 'Cuenta de Comprador (Email)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_circle_outlined),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC439),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: _procesarTransaccionSandbox,
              child: const Text(
                'Completar Compra ',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 15),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF003087)),
                  SizedBox(height: 10),
                  Text(
                    'Autorizando Fondos...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
