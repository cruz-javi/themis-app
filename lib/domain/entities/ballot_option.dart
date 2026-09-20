class BallotOption {
  const BallotOption({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.onChainIndex,
  });

  final String id;
  final String nombre;
  final String? descripcion;
  final int? onChainIndex;

  factory BallotOption.fromJson(Map<String, dynamic> json) {
    return BallotOption(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      onChainIndex: json['onChainIndex'] as int?,
    );
  }
}
