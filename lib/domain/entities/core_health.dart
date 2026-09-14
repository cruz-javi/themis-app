class CoreHealth {
  const CoreHealth({
    required this.status,
    required this.databaseReachable,
    required this.chainConnected,
    required this.aiReachable,
    this.contractVersion,
  });

  final String status;
  final bool databaseReachable;
  final bool chainConnected;
  final bool aiReachable;
  final String? contractVersion;

  factory CoreHealth.fromJson(Map<String, dynamic> json) {
    final dependencies = json['dependencies'] as Map<String, dynamic>? ?? {};
    final database = dependencies['database'] as Map<String, dynamic>? ?? {};
    final chain = dependencies['chain'] as Map<String, dynamic>? ?? {};
    final ai = dependencies['ai'] as Map<String, dynamic>? ?? {};

    return CoreHealth(
      status: json['status'] as String? ?? 'desconocido',
      databaseReachable: database['reachable'] as bool? ?? false,
      chainConnected: chain['connected'] as bool? ?? false,
      aiReachable: ai['reachable'] as bool? ?? false,
      contractVersion: chain['contractVersion'] as String?,
    );
  }
}
