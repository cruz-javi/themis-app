import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:themis_app/data/repositories/demo_repository.dart';
import 'package:themis_app/domain/entities/core_health.dart';
import 'package:themis_app/features/demo/demo_page.dart';

class _FakeRepository implements DemoRepository {
  _FakeRepository({required this.health, this.shouldFail = false});

  final CoreHealth health;
  final bool shouldFail;
  int pingCount = 0;

  @override
  Future<CoreHealth> fetchHealth() async {
    if (shouldFail) {
      throw Exception('sin conexion');
    }
    return health;
  }

  @override
  Future<void> sendPing(String note) async {
    pingCount += 1;
  }
}

const _healthyStub = CoreHealth(
  status: 'ok',
  databaseReachable: true,
  chainConnected: true,
  aiReachable: true,
  contractVersion: '0.1.0',
);

void main() {
  testWidgets('muestra el estado de las tres dependencias', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DemoPage(repository: _FakeRepository(health: _healthyStub))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Estado: ok'), findsOneWidget);
    expect(find.text('Neon: conectado'), findsOneWidget);
    expect(find.text('Blockchain: conectado'), findsOneWidget);
    expect(find.text('themis-ai: conectado'), findsOneWidget);
  });

  testWidgets('muestra el error cuando el core no responde', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DemoPage(
          repository: _FakeRepository(health: _healthyStub, shouldFail: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No se pudo contactar a themis-core'), findsOneWidget);
  });

  testWidgets('el boton envia un ping', (tester) async {
    final repository = _FakeRepository(health: _healthyStub);

    await tester.pumpWidget(MaterialApp(home: DemoPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Escribir ping en Neon'));
    await tester.pumpAndSettle();

    expect(repository.pingCount, 1);
  });
}
