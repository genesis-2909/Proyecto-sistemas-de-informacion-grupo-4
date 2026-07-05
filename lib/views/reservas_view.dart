import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/reserva_controller.dart';
import '../theme/eco_theme.dart';

class ReservasView extends StatefulWidget {
  const ReservasView({super.key});

  @override
  State<ReservasView> createState() => _ReservasViewState();
}

class _ReservasViewState extends State<ReservasView> {
  final ReservaController _reservaCtrl = ReservaController();
  final TextEditingController _emailSandboxController = TextEditingController();

  String? _reservaIdEnPago;
  bool _procesandoPago = false;

  @override
  void dispose() {
    _emailSandboxController.dispose();
    super.dispose();
  }

  // Helper para verificar dinámicamente si una reserva ya expiró (Disfrutado)
  bool _verificarSiYaExpiro(String fechaFinStr) {
    try {
      List<String> partes = fechaFinStr.split('/');
      if (partes.length != 3) return false;
      int dia = int.parse(partes[0]);
      int mes = int.parse(partes[1]);
      int anio = int.parse(partes[2]);

      DateTime fechaFin = DateTime(anio, mes, dia);
      DateTime hoy = DateTime.now();

      // Limpiamos horas para comparar solo días calendario
      DateTime fechaFinLimpia = DateTime(
        fechaFin.year,
        fechaFin.month,
        fechaFin.day,
      );
      DateTime hoyLimpia = DateTime(hoy.year, hoy.month, hoy.day);

      return hoyLimpia.isAfter(fechaFinLimpia);
    } catch (e) {
      return false;
    }
  }

  Color _obtenerColorEstado(String estado, bool yaExpiro) {
    if (estado == 'Pagado' && yaExpiro) return EcoTheme.darkForest;

    switch (estado) {
      case 'Solicitado':
        return Colors.orange.shade700;
      case 'Aprobado':
        return Colors.blue.shade700;
      case 'Rechazado':
        return Colors.red.shade700;
      case 'Pagado':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // 💳 Modal Pasarela EcoPay Sandbox Integrado
  void _mostrarPasarelaPago(String docId, double monto) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailSandboxController.text = user.email!;
    }
    _reservaIdEnPago = docId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: EcoTheme.pureWhite,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.credit_card_rounded,
                      color: Color(0xFF003087),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EcoPay Pasarela Sandbox'.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF003087),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (!_procesandoPago) ...[
                  const Text(
                    'Tu reserva ha sido aprobada por el operador. Procede a autorizar los fondos simulados para completar el pago de tu viaje.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monto a transferir:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '\$$monto USD',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF003087),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailSandboxController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Cuenta de Comprador Unimetano',
                      prefixIcon: Icon(
                        Icons.alternate_email_rounded,
                        color: Color(0xFF003087),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC439),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      setModalState(() => _procesandoPago = true);

                      // Simular tiempo de espera de procesamiento bancario seguro
                      await Future.delayed(const Duration(milliseconds: 2500));

                      // Invoca el controlador real que actualiza Firestore a 'Pagado'
                      bool exito = await _reservaCtrl.procesarPagoReal(
                        _reservaIdEnPago!,
                      );

                      if (mounted) {
                        Navigator.pop(
                          context,
                        ); // Cierra el bottomsheet de la pasarela

                        // Si la base de datos se actualizó correctamente, muestra la felicitación
                        if (exito) {
                          _mostrarMensajeExito();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Hubo un problema al procesar el pago. Inténtalo de nuevo.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }

                      setState(() {
                        _procesandoPago = false;
                        _reservaIdEnPago = null;
                      });
                    },
                    child: const Text(
                      'Autorizar Pago Inmediato',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF003087)),
                        SizedBox(height: 16),
                        Text(
                          'Autorizando Fondos Transaccionales...',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003087),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // 🎉 Diálogo interactivo de Felicitación post-pago
  void _mostrarMensajeExito() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EcoTheme.warmCream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Icon(
              Icons.celebration_rounded,
              color: EcoTheme.ecoGold,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Reserva Completada con Éxito!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: EcoTheme.darkForest,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu pago ha sido procesado de forma sustentable. ¡Esperamos que disfrutes mucho de tu próxima gran aventura ecoturística!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoTheme.forestGreen,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '¡Excelente!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: EcoTheme.warmCream,
      body: user == null
          ? const Center(
              child: Text(
                'Por favor, inicia sesión para verificar tus reservas.',
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              // Apunta directamente a la colección real unificada 'reservations'
              stream: FirebaseFirestore.instance
                  .collection('reservations')
                  .where('id_viajero', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: EcoTheme.forestGreen,
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 65,
                          color: EcoTheme.forestGreen,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No tienes reservas registradas actualmente.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: EcoTheme.darkForest,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '¡Explora destinos y solicita tu primer viaje!',
                          style: TextStyle(
                            color: EcoTheme.softGray,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final solicitudes = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 12,
                    right: 12,
                    bottom: 12,
                  ),
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    final resDoc = solicitudes[index];
                    final datos = resDoc.data() as Map<String, dynamic>;

                    final String destino =
                        datos['nombre_destino'] ?? 'Destino Desconocido';
                    final String fechaInicio =
                        datos['fecha_inicio'] ?? '--/--/----';
                    final String fechaFin = datos['fecha_fin'] ?? '--/--/----';
                    final double monto = (datos['monto_total'] ?? 0.0)
                        .toDouble();
                    String estado = datos['estado_actual'] ?? 'Solicitado';

                    // Evaluación de la regla de tiempo para mutar visualmente a 'Disfrutado'
                    final bool yaExpiro = _verificarSiYaExpiro(fechaFin);
                    if (estado == 'Pagado' && yaExpiro) {
                      estado = 'Disfrutado';
                    }

                    Color colorEstado = _obtenerColorEstado(estado, yaExpiro);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: EcoTheme.luxuryCard(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        destino,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: EcoTheme.darkForest,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Fechas: $fechaInicio al $fechaFin',
                                        style: const TextStyle(
                                          color: EcoTheme.softGray,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Monto Total: \$${monto.toInt()} USD',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          color: EcoTheme.forestGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorEstado.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    estado.toUpperCase(),
                                    style: TextStyle(
                                      color: colorEstado,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // 🔑 El Botón Condicional de Pago Sandbox: Habilitado SÓLO si el operador cambió el estado a "Aprobado"
                            if (estado == 'Aprobado') ...[
                              const SizedBox(height: 14),
                              const Divider(),
                              const SizedBox(height: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EcoTheme.forestGreen,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 42),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () =>
                                    _mostrarPasarelaPago(resDoc.id, monto),
                                icon: const Icon(
                                  Icons.payment_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Proceder al Pago Seguro',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
