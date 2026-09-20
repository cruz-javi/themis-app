import 'ballot_option.dart';

class BallotElection {
  const BallotElection({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.estado,
    required this.votacionInicio,
    required this.votacionFin,
    this.onChainGroupId,
    this.merkleRoot,
    required this.opciones,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final String estado;
  final DateTime votacionInicio;
  final DateTime votacionFin;
  final String? onChainGroupId;
  final String? merkleRoot;
  final List<BallotOption> opciones;

  factory BallotElection.fromJson(Map<String, dynamic> json) {
    return BallotElection(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      estado: json['estado'] as String,
      votacionInicio: DateTime.parse(json['votacionInicio'] as String),
      votacionFin: DateTime.parse(json['votacionFin'] as String),
      onChainGroupId: json['onChainGroupId'] as String?,
      merkleRoot: json['merkleRoot'] as String?,
      opciones: (json['opciones'] as List<dynamic>?)
              ?.map((e) => BallotOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BallotElection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
