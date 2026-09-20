class MerkleTreeData {
  const MerkleTreeData({
    required this.electionId,
    this.onChainGroupId,
    this.merkleRoot,
    required this.members,
    required this.depth,
  });

  final String electionId;
  final String? onChainGroupId;
  final String? merkleRoot;
  final List<String> members;
  final int depth;

  factory MerkleTreeData.fromJson(Map<String, dynamic> json) {
    return MerkleTreeData(
      electionId: json['electionId'] as String,
      onChainGroupId: json['onChainGroupId'] as String?,
      merkleRoot: json['merkleRoot'] as String?,
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      depth: (json['depth'] as num?)?.toInt() ?? 16,
    );
  }
}
