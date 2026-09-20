import '../../core/network/api_client.dart';
import '../../domain/entities/ballot_election.dart';
import '../../domain/entities/merkle_tree_data.dart';
import '../../domain/entities/vote_receipt.dart';
import '../../domain/entities/zk_vote_proof.dart';

abstract class VotingRepository {
  Future<List<BallotElection>> fetchActiveElections();
  Future<BallotElection> fetchElectionDetails(String electionId);
  Future<MerkleTreeData> fetchMerkleTree(String electionId);
  Future<VoteReceipt> castVote({
    required String electionId,
    required String optionId,
    required ZkVoteProof proof,
  });
}

class HttpVotingRepository implements VotingRepository {
  HttpVotingRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<BallotElection>> fetchActiveElections() async {
    final list = await _client.getJsonList('/elections/public/active');
    return list
        .map((e) => BallotElection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BallotElection> fetchElectionDetails(String electionId) async {
    final json = await _client.getJson('/elections/$electionId/public');
    return BallotElection.fromJson(json);
  }

  @override
  Future<MerkleTreeData> fetchMerkleTree(String electionId) async {
    final json = await _client.getJson('/elections/$electionId/merkle-tree');
    return MerkleTreeData.fromJson(json);
  }

  @override
  Future<VoteReceipt> castVote({
    required String electionId,
    required String optionId,
    required ZkVoteProof proof,
  }) async {
    final json = await _client.postJson(
      '/elections/$electionId/votes',
      body: {
        'optionId': optionId,
        'proof': proof.toJson(),
      },
    );
    return VoteReceipt.fromJson(json);
  }
}
