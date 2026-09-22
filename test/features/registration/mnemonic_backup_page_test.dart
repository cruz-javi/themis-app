import 'package:flutter/material.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:themis_app/core/crypto/identity_seed.dart';
import 'package:themis_app/core/storage/secure_identity_store.dart';
import 'package:themis_app/features/registration/pages/mnemonic_backup_page.dart';

/// Fake de la plataforma de flutter_secure_storage: sin esto
/// SecureIdentityStore intenta hablar por platform channel y el widget test
/// falla (mismo patron que test/login_page_test.dart).
class _FakeSecureStoragePlatform extends FlutterSecureStoragePlatform
    with MockPlatformInterfaceMixin {
  final Map<String, String> store = {};

  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    store[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async =>
      store[key];

  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async =>
      Map.of(store);

  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async =>
      store.containsKey(key);

  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    store.remove(key);
  }

  @override
  Future<void> deleteAll({required Map<String, String> options}) async {
    store.clear();
  }
}

void main() {
  late _FakeSecureStoragePlatform platform;
  late SecureIdentityStore store;
  const mnemonic =
      'legal winner thank year wave sausage worth useful legal winner thank yellow';

  setUp(() {
    platform = _FakeSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = platform;
    store = SecureIdentityStore();
  });

  Widget wrap() => MaterialApp(
        home: MnemonicBackupPage(
          mnemonic: mnemonic,
          secureIdentityStore: store,
          electionId: 'election-1',
        ),
      );

  testWidgets('no muestra las palabras hasta que el votante lo pide', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Mostrar mis 12 palabras'), findsOneWidget);
    expect(find.textContaining('1. legal'), findsNothing);
  });

  testWidgets('al revelar muestra las 12 palabras numeradas', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('Mostrar mis 12 palabras'));
    await tester.pumpAndSettle();

    expect(find.text('1. legal'), findsOneWidget);
    expect(find.text('12. yellow'), findsOneWidget);
  });

  // No se puede seguir sin confirmar el respaldo: si el votante pierde la
  // frase pierde el voto, porque el servidor no puede regenerar la identidad
  // (y que no pueda es lo que impide asociar un voto con su votante).
  testWidgets('el boton continuar esta deshabilitado hasta confirmar', (tester) async {
    await tester.pumpWidget(wrap());

    final continuar = find.widgetWithText(FilledButton, 'Continuar');
    expect(tester.widget<FilledButton>(continuar).onPressed, isNull);

    await tester.tap(find.text('Mostrar mis 12 palabras'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(continuar).onPressed, isNotNull);
  });

  testWidgets('la frase de prueba es una mnemonica BIP-39 valida', (tester) async {
    expect(isValidMnemonic(mnemonic), isTrue);
    expect(seedFromMnemonic(mnemonic), seedFromMnemonic(mnemonic));
  });
}
