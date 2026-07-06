import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/sitio_model.dart';
import '../theme/eco_theme.dart';

class DetalleRutaView extends StatefulWidget {
  final SitioTuristico sitio;

  const DetalleRutaView({super.key, required this.sitio});

  @override
  State<DetalleRutaView> createState() => _DetalleRutaViewState();
}

class _DetalleRutaViewState extends State<DetalleRutaView> {
  final TextEditingController _emailSandboxController = TextEditingController();

  int _personas = 1;
  int _noches = 1;
  String _estadoFlujo = 'Disponible';
  String _idDocumentoReservaCreada = '';
  DateTimeRange? _fechasSeleccionadas;
  String _rolUsuarioActual = 'viajero';

  @override
  void initState() {
    super.initState();
    _verificarRolYEmail();
    _buscarReservaExistente();
  }

  Future<void> _verificarRolYEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.email != null) {
        _emailSandboxController.text = user.email!;
      }
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
        if (userDoc.exists && mounted) {
          setState(() {
            _rolUsuarioActual = userDoc.data()?['rol'] ?? 'viajero';
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _buscarReservaExistente() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('reservas')
          .where('id_viajero', isEqualTo: user.uid)
          .where('id_publicacion', isEqualTo: widget.sitio.id)
          .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        final docActivo = querySnapshot.docs.first;
        setState(() {
          _idDocumentoReservaCreada = docActivo.id;
          _estadoFlujo = 'EsperandoAprobacion';
        });
      }
    } catch (_) {}
  }

  Future<void> _seleccionarFechas(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: EcoTheme.forestGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: EcoTheme.darkForest,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final calculoDias = picked.end.difference(picked.start).inDays;
      setState(() {
        _fechasSeleccionadas = picked;
        _noches = calculoDias == 0 ? 1 : calculoDias;
      });
    }
  }

  Future<void> _procesarCreacionReserva() async {
    if (_fechasSeleccionadas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona las fechas de tu viaje.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reservar.')),
      );
      return;
    }

    final double montoTotal = widget.sitio.costoMaximo * _personas * _noches;

    try {
      final docRef = await FirebaseFirestore.instance.collection('reservas').add({
        'id_viajero': user.uid,
        'nombre_viajero': user.displayName ?? 'Viajero Eco',
        'email_viajero': user.email ?? '',
        'id_operador': widget.sitio.idOperador,
        'id_publicacion': widget.sitio.id,
        'nombre_destino': widget.sitio.nombre,
        'cantidad_personas': _personas,
        'fecha_inicio':
            "${_fechasSeleccionadas!.start.day}/${_fechasSeleccionadas!.start.month}/${_fechasSeleccionadas!.start.year}",
        'fecha_fin':
            "${_fechasSeleccionadas!.end.day}/${_fechasSeleccionadas!.end.month}/${_fechasSeleccionadas!.end.year}",
        'monto_total': montoTotal,
        'estado_actual': 'Solicitado',
        'creado_en': FieldValue.serverTimestamp(),
      });

      setState(() {
        _idDocumentoReservaCreada = docRef.id;
        _estadoFlujo = 'EsperandoAprobacion';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar la reserva: $e')),
      );
    }
  }

  Future<void> _simularPagoExitoso() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payment, size: 40, color: Color(0xFF003087)),
            const SizedBox(height: 16),
            const Text(
              'PayPal Developer Sandbox',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF003087)),
            ),
            const SizedBox(height: 8),
            Text(
              'Conectado como: ${_emailSandboxController.text}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Sandbox Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFC439),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                Navigator.pop(context);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                );

                await Future.delayed(const Duration(seconds: 2));

                try {
                  await FirebaseFirestore.instance
                      .collection('reservas')
                      .doc(_idDocumentoReservaCreada)
                      .update({'estado_actual': 'Pagado'});
                  
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('COMPRAR AHORA (SANDBOX)', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoEscribirResena() {
    final TextEditingController resenaController = TextEditingController();
    double estrellas = 5.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Dejar Reseña',
          style: TextStyle(
            color: EcoTheme.darkForest,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cuéntanos tu experiencia en este destino sustentable:'),
            const SizedBox(height: 12),
            TextField(
              controller: resenaController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Excelente atención, lugar mágico...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EcoTheme.forestGreen,
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && resenaController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('resenas').add({
                  'id_publicacion': widget.sitio.id,
                  'nombre_usuario': user.displayName ?? 'Anónimo',
                  'comentario': resenaController.text,
                  'estrellas': estrellas,
                  'creado_en': FieldValue.serverTimestamp(),
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Publicar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF2),
      appBar: AppBar(
        title: Text(
          widget.sitio.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: EcoTheme.darkForest,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool esPantallaAncha = constraints.maxWidth > 800;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: esPantallaAncha
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: constraints.maxWidth * 0.55,
                            child: _buildInformacionPrincipal(),
                          ),
                          const SizedBox(width: 40),
                          Expanded(child: _buildPanelLateralAcciones()),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInformacionPrincipal(),
                          const SizedBox(height: 32),
                          _buildPanelLateralAcciones(),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInformacionPrincipal() {
    final String imagenDestacada = widget.sitio.imagenes.isNotEmpty
        ? widget.sitio.imagenes.first
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: 400,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              image: imagenDestacada.isNotEmpty && imagenDestacada.startsWith('http')
                  ? DecorationImage(
                      image: NetworkImage(imagenDestacada),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imagenDestacada.isEmpty || !imagenDestacada.startsWith('http')
                ? const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: EcoTheme.forestGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.sitio.tipoAlojamiento.toUpperCase(),
                style: const TextStyle(
                  color: EcoTheme.forestGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            const Text(
              '5.0 (Calificación Eco)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Descripción del Destino',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: EcoTheme.darkForest,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.sitio.descripcion,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Servicios e Instalaciones Incluidas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: EcoTheme.darkForest,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            if (widget.sitio.tieneTransporte)
              _buildPillServicio(Icons.directions_bus, 'Transporte Integrado'),
            _buildPillServicio(Icons.eco, 'Energía Sustentable'),
            _buildPillServicio(Icons.water_drop, 'Agua Potable'),
            _buildPillServicio(Icons.wifi, 'Acceso a Red'),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Reseñas de la Comunidad',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: EcoTheme.darkForest,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('resenas')
              .where('id_publicacion', isEqualTo: widget.sitio.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text(
                'Nadie ha dejado comentarios sobre este hospedaje aún. ¡Sé el primero!',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              );
            }
            final listado = snapshot.data!.docs;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listado.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final rData = listado[i].data() as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rData['nombre_usuario'] ?? 'Anónimo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rData['comentario'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPanelLateralAcciones() {
    double costoTotalCalculado = widget.sitio.costoMaximo * _personas * _noches;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Precio por noche:',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                '\$${widget.sitio.costoMaximo.toInt()} USD',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: EcoTheme.forestGreen,
                ),
              ),
            ],
          ),
          if (_fechasSeleccionadas != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal ($_noches noches x $_personas huéspedes):',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  '\$${costoTotalCalculado.toInt()} USD',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: EcoTheme.darkForest,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 32),
          if (_rolUsuarioActual == 'operador') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Modo Vista Previa: Como operador de este viaje, no puedes realizar autoreservaciones.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            if (_estadoFlujo == 'Disponible') ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EcoTheme.darkForest,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _seleccionarFechas(context),
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _fechasSeleccionadas == null
                      ? 'Seleccionar Fechas de Estadía'
                      : 'Fechas: ${_fechasSeleccionadas!.start.day}/${_fechasSeleccionadas!.start.month} al ${_fechasSeleccionadas!.end.day}/${_fechasSeleccionadas!.end.month}',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Huéspedes:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _personas > 1
                            ? () => setState(() => _personas--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_personas',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _personas++),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EcoTheme.forestGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _procesarCreacionReserva,
                child: const Text(
                  'SOLICITAR RESERVA AHORA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ],
            if (_estadoFlujo == 'EsperandoAprobacion') ...[
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reservas')
                    .doc(_idDocumentoReservaCreada)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: CircularProgressIndicator(color: EcoTheme.forestGreen));
                  }

                  final rData = snapshot.data!.data() as Map<String, dynamic>;
                  final String estadoActual = rData['estado_actual'] ?? 'Solicitado';

                  if (estadoActual == 'Solicitado') {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(color: Colors.orange),
                          const SizedBox(height: 12),
                          const Text(
                            'Esperando que el operador acepte tu solicitud...',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Puedes cerrar esta página con total tranquilidad. El estado de tu solicitud quedará guardado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Volver al menú principal'),
                            style: TextButton.styleFrom(foregroundColor: EcoTheme.darkForest),
                          )
                        ],
                      ),
                    );
                  }

                  if (estadoActual == 'Rechazado') {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 40),
                          const SizedBox(height: 8),
                          const Text(
                            'La solicitud fue rechazada por falta de disponibilidad.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('reservas')
                                  .doc(_idDocumentoReservaCreada)
                                  .delete();
                              setState(() {
                                _estadoFlujo = 'Disponible';
                                _idDocumentoReservaCreada = '';
                              });
                            },
                            child: const Text('Intentar con otras fechas'),
                          )
                        ],
                      ),
                    );
                  }

                  if (estadoActual == 'Aceptado') {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                '¡Solicitud Aprobada!',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailSandboxController,
                            decoration: const InputDecoration(
                              labelText: 'PayPal Sandbox Account',
                              hintText: 'sb-buyer@business.example.com',
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC439),
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.payment, color: Colors.black),
                            label: const Text(
                              'PAGAR CON PAYPAL DEVELOPER',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _simularPagoExitoso,
                          ),
                        ],
                      ),
                    );
                  }

                  if (estadoActual == 'Pagado') {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            '¡Pago Procesado Exitosamente!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tu lugar ha quedado completamente asegurado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: EcoTheme.darkForest,
                            ),
                            onPressed: _mostrarDialogoEscribirResena,
                            icon: const Icon(Icons.rate_review, size: 18),
                            label: const Text('Dejar Reseña del Destino'),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: EcoTheme.darkForest),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Volver a Explorar Destinos'),
                          ),
                        ],
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPillServicio(IconData icono, String etiqueta) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: EcoTheme.forestGreen),
          const SizedBox(width: 4),
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}