class PublicOption {
  const PublicOption({required this.id, required this.nombre, this.descripcion});

  factory PublicOption.fromJson(Map<String, dynamic> json) => PublicOption(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
  );

  final String id;
  final String nombre;
  final String? descripcion;
}

/// Espejo de PublicElectionResponseDto (themis-core, GET /elections/public):
/// sin metadata de auditoria ni elegibilidad SSO.
class PublicElection {
  const PublicElection({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.votacionInicio,
    required this.votacionFin,
    required this.estado,
    required this.opciones,
  });

  factory PublicElection.fromJson(Map<String, dynamic> json) => PublicElection(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    descripcion: json['descripcion'] as String?,
    votacionInicio: DateTime.parse(json['votacionInicio'] as String),
    votacionFin: DateTime.parse(json['votacionFin'] as String),
    estado: json['estado'] as String,
    opciones: (json['opciones'] as List<dynamic>)
        .map((option) => PublicOption.fromJson(option as Map<String, dynamic>))
        .toList(),
  );

  final String id;
  final String nombre;
  final String? descripcion;
  final DateTime votacionInicio;
  final DateTime votacionFin;
  final String estado;
  final List<PublicOption> opciones;
}
