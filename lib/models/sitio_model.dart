class SitioTuristico {
  final String id;
  final String nombre;
  final String descripcion;
  final double costoMaximo;
  final String tipoAlojamiento;
  final bool tieneTransporte;
  final String idOperador;
  final List<String> imagenes;

  SitioTuristico({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.costoMaximo,
    required this.tipoAlojamiento,
    required this.tieneTransporte,
    required this.idOperador,
    required this.imagenes,
  });

  factory SitioTuristico.fromFirestore(Map<String, dynamic> data, String id) {
    return SitioTuristico(
      id: id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      costoMaximo: (data['costo_maximo'] ?? 0.0).toDouble(),
      tipoAlojamiento: data['tipo_alojamiento'] ?? 'Posada',
      tieneTransporte: data['tiene_transporte'] ?? false,
      idOperador: data['id_operador'] ?? '',
      imagenes: List<String>.from(data['imagenes'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'costo_maximo': costoMaximo,
      'tipo_alojamiento': tipoAlojamiento,
      'tiene_transporte': tieneTransporte,
      'id_operador': idOperador,
      'imagenes': imagenes,
    };
  }
}