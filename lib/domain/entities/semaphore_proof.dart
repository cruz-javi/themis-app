/// Shape exacto de SemaphoreProof (ver @semaphore-protocol/proof
/// generateProof() en themis-web /prove) -- coincide 1:1 con SubmitVoteDto
/// de themis-core.
class SemaphoreProof {
  const SemaphoreProof({
    required this.merkleTreeDepth,
    required this.merkleTreeRoot,
    required this.nullifier,
    required this.message,
    required this.scope,
    required this.points,
  });

  factory SemaphoreProof.fromJson(Map<String, dynamic> json) {
    return SemaphoreProof(
      merkleTreeDepth: json['merkleTreeDepth'] as int,
      merkleTreeRoot: json['merkleTreeRoot'] as String,
      nullifier: json['nullifier'] as String,
      message: json['message'] as String,
      scope: json['scope'] as String,
      points: (json['points'] as List<dynamic>).cast<String>(),
    );
  }

  final int merkleTreeDepth;
  final String merkleTreeRoot;
  final String nullifier;
  final String message;
  final String scope;
  final List<String> points;

  Map<String, dynamic> toJson() => {
    'merkleTreeDepth': merkleTreeDepth,
    'merkleTreeRoot': merkleTreeRoot,
    'nullifier': nullifier,
    'message': message,
    'scope': scope,
    'points': points,
  };
}
