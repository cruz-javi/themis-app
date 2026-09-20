class VoteReceipt {
  const VoteReceipt({
    required this.id,
    required this.electionId,
    required this.optionId,
    required this.nullifier,
    required this.txHash,
    required this.createdAt,
  });

  final String id;
  final String electionId;
  final String optionId;
  final String nullifier;
  final String txHash;
  final DateTime createdAt;

  factory VoteReceipt.fromJson(Map<String, dynamic> json) {
    return VoteReceipt(
      id: json['id'] as String,
      electionId: json['electionId'] as String,
      optionId: json['optionId'] as String,
      nullifier: json['nullifier'] as String,
      txHash: json['txHash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
