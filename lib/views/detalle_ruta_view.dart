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
  String _estadoFlujo = 'Disponible'; // Estados: Disponible -> SolicitadoExito
  String _idDocumentoReservaCreada = '';
  DateTimeRange? _fechasSeleccionadas;
  String _rolUsuarioActual = 'viajero';

  @override
  void initState() {
    super.initState();
    _verificarRolYEmail();
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
      } catch (e) {
        debugPrint('Error obteniendo rol: $e');
      }
    }
  }

  // Corregido: Letra 'ñ' cambiada por 'nio' para evitar caracteres ilegales en Web
  void _verificarSiYaFueDisfrutado(
    String idDoc,
    String estadoActual,
    String fechaFinStr,
  ) {
    try {
      if (estadoActual == 'Pagado') {
        final partes = fechaFinStr.split('/');
        if (partes.length == 3) {
          final anio = int.parse(partes[2]);
          final mes = int.parse(partes[1]);
          final dia = int.parse(partes[0]);
          final fechaFin = DateTime(anio, mes, dia);

          if (DateTime.now().isAfter(fechaFin.add(const Duration(days: 1)))) {
            FirebaseFirestore.instance.collection('reservas').doc(idDoc).update(
              {'estado_actual': 'Disfrutado'},
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error verificando fecha de finalización: $e');
    }
  }

  Future<void> _crearSolicitudDeReserva() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reservar.')),
      );
      return;
    }

    if (_fechasSeleccionadas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona las fechas de tu estadía.'),
        ),
      );
      return;
    }

    final dias = _fechasSeleccionadas!.duration.inDays;
    final noches = dias == 0 ? 1 : dias;
    final montoTotal = widget.sitio.costoMaximo * noches * _personas;

    final fechaInicioStr =
        "${_fechasSeleccionadas!.start.day}/${_fechasSeleccionadas!.start.month}/${_fechasSeleccionadas!.start.year}";
    final fechaFinStr =
        "${_fechasSeleccionadas!.end.day}/${_fechasSeleccionadas!.end.month}/${_fechasSeleccionadas!.end.year}";

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('reservas')
          .add({
            'id_viajero': user.uid,
            'email_viajero': user.email,
            'id_operador': widget.sitio.idOperador,
            'id_publicacion': widget.sitio.id,
            'nombre_destino': widget.sitio.nombre,
            'cantidad_personas': _personas,
            'fecha_inicio': fechaInicioStr,
            'fecha_fin': fechaFinStr,
            'monto_total': montoTotal,
            'estado_actual': 'Solicitado',
            'fecha_creacion': FieldValue.serverTimestamp(),
          });

      setState(() {
        _idDocumentoReservaCreada = docRef.id;
        _estadoFlujo = 'SolicitadoExito';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar la solicitud: $e')),
      );
    }
  }

  Future<void> _ejecutarPagoFicticio() async {
    if (_idDocumentoReservaCreada.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: EcoTheme.forestGreen),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    try {
      await FirebaseFirestore.instance
          .collection('reservas')
          .doc(_idDocumentoReservaCreada)
          .update({'estado_actual': 'Pagado'});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              '¡Pago simulado con éxito! Tu reserva está confirmada.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al procesar pago: $e')));
    }
  }

  Future<void> _seleccionarFechas(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _fechasSeleccionadas,
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
      setState(() {
        _fechasSeleccionadas = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double anchoPantalla = MediaQuery.of(context).size.width;
    final bool esWeb = anchoPantalla > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAF2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EcoTheme.darkForest),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.sitio.nombre,
          style: const TextStyle(
            color: EcoTheme.darkForest,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: esWeb ? anchoPantalla * 0.15 : 20.0,
          vertical: 20.0,
        ),
        child: _estadoFlujo == 'SolicitadoExito'
            ? _buildPantallaSeguimientoFlujo()
            : _buildFormularioYDetallesOriginales(esWeb),
      ),
    );
  }

  Widget _buildPantallaSeguimientoFlujo() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservas')
          .doc(_idDocumentoReservaCreada)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: CircularProgressIndicator(color: EcoTheme.forestGreen),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final estado = data['estado_actual'] ?? 'Solicitado';
        final fechaFinStr = data['fecha_fin'] ?? '';

        _verificarSiYaFueDisfrutado(
          _idDocumentoReservaCreada,
          estado,
          fechaFinStr,
        );

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 15),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconoSegunEstado(estado),
                const SizedBox(height: 24),
                Text(
                  _getTituloSegunEstado(estado),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: EcoTheme.darkForest,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getDescripcionSegunEstado(estado),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                _buildFilaDetalle('Destino:', widget.sitio.nombre),
                _buildFilaDetalle(
                  'Fechas:',
                  '${data['fecha_inicio']} al ${data['fecha_fin']}',
                ),
                _buildFilaDetalle(
                  'Personas:',
                  '${data['cantidad_personas']} viajero(s)',
                ),
                _buildFilaDetalle(
                  'Monto Total:',
                  '\$${data['monto_total']} USD',
                  resaltar: true,
                ),
                const SizedBox(height: 30),

                if (estado == 'Aceptado') ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text(
                      'PROCEDER AL PAGO SIMULADO',
                    ), // Corregido: Estilo del texto simplificado
                    onPressed: _ejecutarPagoFicticio,
                  ),
                  const SizedBox(height: 12),
                ],

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Volver al Catálogo Global',
                    style: TextStyle(
                      color: EcoTheme.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconoSegunEstado(String estado) {
    if (estado == 'Solicitado')
      return const CircleAvatar(
        radius: 40,
        backgroundColor: Colors.orange,
        child: Icon(
          Icons.hourglass_empty_rounded,
          size: 40,
          color: Colors.white,
        ),
      );
    if (estado == 'Aceptado')
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.blue.shade100,
        child: const Icon(Icons.gavel_rounded, size: 40, color: Colors.blue),
      );
    if (estado == 'Pagado')
      return const CircleAvatar(
        radius: 40,
        backgroundColor: Colors.green,
        child: Icon(Icons.check_circle, size: 40, color: Colors.white),
      );
    if (estado == 'Rechazado')
      return const CircleAvatar(
        radius: 40,
        backgroundColor: Colors.red,
        child: Icon(Icons.cancel_rounded, size: 40, color: Colors.white),
      );
    return const CircleAvatar(
      radius: 40,
      backgroundColor: EcoTheme.forestGreen,
      child: Icon(Icons.card_travel_rounded, size: 40, color: Colors.white),
    );
  }

  String _getTituloSegunEstado(String estado) {
    if (estado == 'Solicitado') return 'Solicitud Enviada Exitosamente';
    if (estado == 'Aceptado') return '¡Tu solicitud fue aprobada!';
    if (estado == 'Pagado') return '¡Reserva Pagada y Confirmada!';
    if (estado == 'Rechazado') return 'Solicitud de Reserva Amazonía Rechazada';
    return '¡Viaje Disfrutado! ✨';
  }

  String _getDescripcionSegunEstado(String estado) {
    if (estado == 'Solicitado')
      return 'El operador ha sido notificado. Aparecerá en tu sección de "Mis Actividades" en espera de su aprobación.';
    if (estado == 'Aceptado')
      return 'El operador tiene disponibilidad para tus fechas. Por favor, realiza el pago ficticio para asegurar tu cupo.';
    if (estado == 'Pagado')
      return 'El pago se procesó de forma simulada correctamente. ¡Disfruta al máximo tu ecosistema!';
    if (estado == 'Rechazado')
      return 'Lamentablemente el operador no cuenta con disponibilidad para las fechas marcadas.';
    return 'Esperamos que hayas tenido una experiencia ecológica inolvidable. ¡Gracias por viajar sustentable!';
  }

  Widget _buildFilaDetalle(
    String titulo,
    String valor, {
    bool resaltar = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: resaltar ? 16 : 14,
              color: resaltar ? EcoTheme.forestGreen : EcoTheme.darkForest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioYDetallesOriginales(bool esWeb) {
    return Wrap(
      spacing: 30,
      runSpacing: 30,
      children: [
        SizedBox(
          width: esWeb
              ? MediaQuery.of(context).size.width * 0.45
              : double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: widget.sitio.imagenes.isNotEmpty
                    ? Image.network(
                        widget.sitio.imagenes.first,
                        height: 350,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 350,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      )
                    : Container(
                        height: 350,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 50),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: EcoTheme.forestGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.sitio.tipoAlojamiento,
                      style: const TextStyle(
                        color: EcoTheme.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '5.0',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Descripción del Destino',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: EcoTheme.darkForest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.sitio.descripcion,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Servicios Ecológicos Incluidos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: EcoTheme.darkForest,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildPillServicio(Icons.wb_sunny_outlined, 'Energía Solar'),
                  _buildPillServicio(
                    Icons.water_drop_outlined,
                    'Agua de Manantial',
                  ),
                  if (widget.sitio.tieneTransporte)
                    _buildPillServicio(
                      Icons.directions_bus,
                      'EcoTransporte Incluido',
                    ),
                ],
              ),
            ],
          ),
        ),

        // Corregido: Limpieza de código residual de depuración que rompía en web
        SizedBox(
          width: esWeb
              ? MediaQuery.of(context).size.width * 0.35
              : double.infinity,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${widget.sitio.costoMaximo.toInt()} USD',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: EcoTheme.forestGreen,
                  ),
                ),
                const Text(
                  'por noche / por persona',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Divider(height: 30),

                const Text(
                  'Fechas de Estadía',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: EcoTheme.forestGreen,
                  ),
                  label: Text(
                    _fechasSeleccionadas == null
                        ? 'Seleccionar rango'
                        : '${_fechasSeleccionadas!.start.day}/${_fechasSeleccionadas!.start.month} al ${_fechasSeleccionadas!.end.day}/${_fechasSeleccionadas!.end.month}',
                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  onPressed: () => _seleccionarFechas(context),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Cantidad de Viajeros',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Corregido: Condicional de paréntesis arreglado para que no rompa el árbol de compilación
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _personas > 1
                            ? () => setState(() => _personas--)
                            : null,
                      ),
                      Text(
                        '$_personas',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => _personas++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_fechasSeleccionadas != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${widget.sitio.costoMaximo.toInt()} x ${_fechasSeleccionadas!.duration.inDays == 0 ? 1 : _fechasSeleccionadas!.duration.inDays} noches x $_personas pers.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '\$${widget.sitio.costoMaximo * (_fechasSeleccionadas!.duration.inDays == 0 ? 1 : _fechasSeleccionadas!.duration.inDays) * _personas} USD',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                ],

                if (_rolUsuarioActual == 'operador') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Modo Vista Previa: Los operadores no pueden solicitar reservas de hospedajes.',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EcoTheme.forestGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _crearSolicitudDeReserva,
                    child: const Text(
                      'SOLICITAR RESERVA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
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
