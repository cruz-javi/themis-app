import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:themis_app/core/crypto/crypto_bridge_exception.dart';
import 'package:themis_app/core/crypto/vote_proof_generator.dart';
import 'package:themis_app/core/storage/secure_identity_store.dart';
import 'package:themis_app/data/repositories/vote_repository.dart';
import 'package:themis_app/domain/entities/public_election.dart';
import 'package:themis_app/domain/entities/semaphore_proof.dart';
import 'package:themis_app/features/voting/ballot_page.dart';

// La generacion real de la prueba (dentro del WebView, snarkjs real via
// /prove) solo se puede validar manualmente en dispositivo/Chrome -- igual
// limitacion ya documentada para CU-05 (CryptoBridge). Este test cubre el
// flujo de la pantalla con un VoteProofGenerator fake.
class _FakeVoteProofGenerator implements VoteProofGenerator {
  _FakeVoteProofGenerator({this.error});

  final Object? error;
  String? lastIdentityPrivateKey;

  @override
  Future<SemaphoreProof> generateProof({
    required String identityPrivateKey,
    required String electionId,
    required String optionId,
    required String apiBaseUrl,
  }) async {
    lastIdentityPrivateKey = identityPrivateKey;
    if (error != null) throw error!;
    return const SemaphoreProof(
      merkleTreeDepth: 1,
      merkleTreeRoot: '111',
      nullifier: 'n1',
      message: '0',
      scope: '7',
      points: ['1', '2', '3', '4', '5', '6', '7', '8'],
    );
  }

  @override
  Widget get widget => const SizedBox.shrink();
}

class _FakeVoteRepository implements VoteRepository {
  _FakeVoteRepository({this.error});

  final DioException? error;
  String? lastElectionId;
  SemaphoreProof? lastProof;

  @override
  Future<List<PublicElection>> fetchPublicElections({String? estado}) async => const [];

  @override
  Future<void> submitVote(String electionId, SemaphoreProof proof) async {
    if (error != null) throw error!;
    lastElectionId = electionId;
    lastProof = proof;
  }
}

// Fake de la plataforma de flutter_secure_storage: sin esto, SecureIdentityStore
// intenta hablar por platform channel y el widget test falla.
class _FakeSecureStoragePlatform extends FlutterSecureStoragePlatform
    with MockPlatformInterfaceMixin {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key, required Map<String, String> options}) async =>
      _store[key];

  @override
  Future<bool> containsKey({required String key, required Map<String, String> options}) async =>
      _store.containsKey(key);

  @override
  Future<void> delete({required String key, required Map<String, String> options}) async {
    _store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({required Map<String, String> options}) async =>
      Map.of(_store);

  @override
  Future<void> deleteAll({required Map<String, String> options}) async => _store.clear();
}

PublicElection _election() => PublicElection(
  id: 'e1',
  nombre: 'Representante FICCT',
  descripcion: null,
  opciones: const [
    PublicOption(id: 'opt-a', nombre: 'Candidata A'),
    PublicOption(id: 'opt-b', nombre: 'Candidato B'),
  ],
  votacionInicio: DateTime(2026, 1, 1),
  votacionFin: DateTime(2026, 1, 2),
  estado: 'VOTACION_ABIERTA',
);

Widget _wrap({
  required VoteRepository voteRepository,
  required SecureIdentityStore secureIdentityStore,
  required VoteProofGenerator proofGenerator,
}) {
  return MaterialApp(
    home: BallotPage(
      election: _election(),
      voteRepository: voteRepository,
      secureIdentityStore: secureIdentityStore,
      proofGenerator: proofGenerator,
      apiBaseUrl: 'http://api.test',
    ),
  );
}

void main() {
  late SecureIdentityStore secureIdentityStore;

  setUp(() {
    FlutterSecureStoragePlatform.instance = _FakeSecureStoragePlatform();
    secureIdentityStore = SecureIdentityStore();
  });

  testWidgets('elige una opcion, emite el voto y muestra confirmacion', (tester) async {
    await secureIdentityStore.write('identity-secret-1');
    final proofGenerator = _FakeVoteProofGenerator();
    final voteRepository = _FakeVoteRepository();

    await tester.pumpWidget(
      _wrap(
        voteRepository: voteRepository,
        secureIdentityStore: secureIdentityStore,
        proofGenerator: proofGenerator,
      ),
    );

    await tester.tap(find.text('Candidata A'));
    await tester.pump();
    await tester.tap(find.text('Emitir voto'));
    await tester.pumpAndSettle();

    expect(find.text('Voto emitido'), findsOneWidget);
    expect(proofGenerator.lastIdentityPrivateKey, 'identity-secret-1');
    expect(voteRepository.lastElectionId, 'e1');
    expect(voteRepository.lastProof?.nullifier, 'n1');
  });

  testWidgets('sin identidad guardada, muestra el error sin llamar al generador de pruebas', (
    tester,
  ) async {
    final proofGenerator = _FakeVoteProofGenerator();
    final voteRepository = _FakeVoteRepository();

    await tester.pumpWidget(
      _wrap(
        voteRepository: voteRepository,
        secureIdentityStore: secureIdentityStore,
        proofGenerator: proofGenerator,
      ),
    );

    await tester.tap(find.text('Candidata A'));
    await tester.pump();
    await tester.tap(find.text('Emitir voto'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se encontró tu identidad en este dispositivo. Registrate primero.'),
      findsOneWidget,
    );
    expect(proofGenerator.lastIdentityPrivateKey, isNull);
  });

  testWidgets('VOTE_ALREADY_CAST del backend se muestra como mensaje claro', (tester) async {
    await secureIdentityStore.write('identity-secret-1');
    final proofGenerator = _FakeVoteProofGenerator();
    final voteRepository = _FakeVoteRepository(
      error: DioException(
        requestOptions: RequestOptions(path: '/elections/e1/votes'),
        response: Response(
          requestOptions: RequestOptions(path: '/elections/e1/votes'),
          statusCode: 409,
          data: {'code': 'VOTE_ALREADY_CAST'},
        ),
      ),
    );

    await tester.pumpWidget(
      _wrap(
        voteRepository: voteRepository,
        secureIdentityStore: secureIdentityStore,
        proofGenerator: proofGenerator,
      ),
    );

    await tester.tap(find.text('Candidata A'));
    await tester.pump();
    await tester.tap(find.text('Emitir voto'));
    await tester.pumpAndSettle();

    expect(find.text('Ya emitiste tu voto en esta elección.'), findsOneWidget);
  });

  testWidgets('si /prove falla (timeout o error del WebView), muestra el mensaje sin enviar el voto', (
    tester,
  ) async {
    await secureIdentityStore.write('identity-secret-1');
    final proofGenerator = _FakeVoteProofGenerator(
      error: const CryptoBridgeException('Tiempo de espera agotado generando la prueba de voto'),
    );
    final voteRepository = _FakeVoteRepository();

    await tester.pumpWidget(
      _wrap(
        voteRepository: voteRepository,
        secureIdentityStore: secureIdentityStore,
        proofGenerator: proofGenerator,
      ),
    );

    await tester.tap(find.text('Candidata A'));
    await tester.pump();
    await tester.tap(find.text('Emitir voto'));
    await tester.pumpAndSettle();

    expect(find.text('Tiempo de espera agotado generando la prueba de voto'), findsOneWidget);
    expect(voteRepository.lastElectionId, isNull);
  });
}
