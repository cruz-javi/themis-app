import '../../core/network/api_client.dart';
import '../../domain/entities/public_election.dart';
import '../../domain/entities/semaphore_proof.dart';

abstract class VoteRepository {
  /// Elecciones publicas (CU-10 app / CU-11 web / CU-15 auditor), sin auth.
  /// [estado] filtra por estado (ej. 'VOTACION_ABIERTA'); sin filtro trae
  /// todas menos BORRADOR.
  Future<List<PublicElection>> fetchPublicElections({String? estado});

  /// Datos publicos para que /prove reconstruya el Group de Semaphore y
  /// genere la prueba -- ver VoteProofBridge.
  Future<void> submitVote(String electionId, SemaphoreProof proof);
}

class HttpVoteRepository implements VoteRepository {
  HttpVoteRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<PublicElection>> fetchPublicElections({String? estado}) async {
    final path = estado == null ? '/elections/public' : '/elections/public?estado=$estado';
    final json = await _client.getJsonList(path);
    return json
        .map((item) => PublicElection.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> submitVote(String electionId, SemaphoreProof proof) async {
    await _client.postJson('/elections/$electionId/votes', body: proof.toJson());
  }
}
