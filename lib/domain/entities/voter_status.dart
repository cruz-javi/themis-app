class VoterStatus {
  const VoterStatus({
    required this.electionId,
    required this.isRegistered,
    required this.hasVoted,
    this.votedAt,
  });

  final String electionId;
  final bool isRegistered;
  final bool hasVoted;
  final DateTime? votedAt;

  factory VoterStatus.fromJson(Map<String, dynamic> json) {
    return VoterStatus(
      electionId: json['electionId'] as String? ?? '',
      isRegistered: json['isRegistered'] as bool? ?? false,
      hasVoted: json['hasVoted'] as bool? ?? false,
      votedAt: json['votedAt'] != null
          ? DateTime.tryParse(json['votedAt'] as String)
          : null,
    );
  }
}
