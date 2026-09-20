import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:themis_app/data/repositories/vote_repository.dart';
import 'package:themis_app/domain/entities/public_election.dart';
import 'package:themis_app/domain/entities/semaphore_proof.dart';
import 'package:themis_app/features/voting/election_select_page.dart';

class _FakeVoteRepository implements VoteRepository {
  _FakeVoteRepository({this.elections = const []});

  final List<PublicElection> elections;
  String? lastEstadoRequested;

  @override
  Future<List<PublicElection>> fetchPublicElections({String? estado}) async {
    lastEstadoRequested = estado;
    return elections;
  }

  @override
  Future<void> submitVote(String electionId, SemaphoreProof proof) async {}
}

PublicElection _election({String id = 'e1'}) => PublicElection(
  id: id,
  nombre: 'Representante FICCT',
  descripcion: 'Eleccion piloto',
  votacionInicio: DateTime(2026, 1, 1),
  votacionFin: DateTime(2026, 1, 2),
  estado: 'VOTACION_ABIERTA',
  opciones: const [],
);

void main() {
  testWidgets('lista las elecciones publicas filtradas por estado y navega al tocar una', (
    tester,
  ) async {
    final repository = _FakeVoteRepository(elections: [_election()]);
    PublicElection? selected;

    final router = GoRouter(
      initialLocation: '/votar',
      routes: [
        GoRoute(
          path: '/votar',
          builder: (context, state) => ElectionSelectPage(
            repository: repository,
            title: 'Elegí la elección',
            estado: 'VOTACION_ABIERTA',
            onSelect: (context, election) => selected = election,
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(repository.lastEstadoRequested, 'VOTACION_ABIERTA');
    expect(find.text('Representante FICCT'), findsOneWidget);

    await tester.tap(find.text('Representante FICCT'));
    await tester.pumpAndSettle();

    expect(selected?.id, 'e1');
  });

  testWidgets('sin elecciones, muestra un mensaje en vez de una lista vacia', (tester) async {
    final repository = _FakeVoteRepository();

    final router = GoRouter(
      initialLocation: '/votar',
      routes: [
        GoRoute(
          path: '/votar',
          builder: (context, state) => ElectionSelectPage(
            repository: repository,
            title: 'Elegí la elección',
            estado: 'VOTACION_ABIERTA',
            onSelect: (context, election) {},
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('No hay elecciones disponibles ahora mismo.'), findsOneWidget);
  });
}
