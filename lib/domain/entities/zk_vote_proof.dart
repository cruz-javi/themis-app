class ZkVoteProof {
  const ZkVoteProof({
    required this.merkleTreeDepth,
    required this.merkleTreeRoot,
    required this.nullifier,
    required this.message,
    required this.scope,
    required this.points,
  });

  final dynamic merkleTreeDepth;
  final String merkleTreeRoot;
  final String nullifier;
  final String message;
  final String scope;
  final List<String> points;

  factory ZkVoteProof.fromJson(Map<String, dynamic> json) {
    return ZkVoteProof(
      merkleTreeDepth: json['merkleTreeDepth'],
      merkleTreeRoot: json['merkleTreeRoot'] as String,
      nullifier: json['nullifier'] as String,
      message: json['message'] as String,
      scope: json['scope'] as String,
      points: (json['points'] as List<dynamic>).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'merkleTreeDepth': merkleTreeDepth,
        'merkleTreeRoot': merkleTreeRoot,
        'nullifier': nullifier,
        'message': message,
        'scope': scope,
        'points': points,
      };
}
