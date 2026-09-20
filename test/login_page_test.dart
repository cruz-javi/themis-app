import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:themis_app/data/repositories/mock_sso_repository.dart';
import 'package:themis_app/domain/entities/login_result.dart';
import 'package:themis_app/features/auth/login_page.dart';
import 'package:themis_app/features/auth/login_result_page.dart';

class _FakeMockSsoRepository implements MockSsoRepository {
  _FakeMockSsoRepository({this.dioError});

  final DioException? dioError;

  static String buildAssertion({bool habilitado = true}) {
    final payload = {
      'sub': 'user-1',
      'facultad': 'FICCT',
      'tipoUsuario': 'ESTUDIANTE',
      'habilitado': habilitado,
      'iat': 0,
      'exp': 9999999999,
    };
    final payloadB64 = base64Url.encode(utf8.encode(jsonEncode(payload)));
    return '$payloadB64.fakehmac';
  }

  @override
  Future<String> login({
    required String codigoInstitucional,
    required String password,
  }) async {
    if (dioError != null) throw dioError!;
    return buildAssertion();
  }
}

Widget _wrap(MockSsoRepository repository) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(repository: repository),
      ),
      GoRoute(
        path: '/login/resultado',
        builder: (context, state) => LoginResultPage(
          result: state.extra as LoginResult,
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('login exitoso navega al resultado y muestra habilitado', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeMockSsoRepository()));

    await tester.enterText(find.byType(TextFormField).at(0), '220999999');
    await tester.enterText(find.byType(TextFormField).at(1), '123123');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Habilitado'), findsWidgets);
  });

  testWidgets('credenciales invalidas muestra el mensaje de error 401', (
    tester,
  ) async {
    final error = DioException(
      requestOptions: RequestOptions(path: '/mock-sso/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/mock-sso/login'),
        statusCode: 401,
      ),
    );

    await tester.pumpWidget(_wrap(_FakeMockSsoRepository(dioError: error)));

    await tester.enterText(find.byType(TextFormField).at(0), '000000000');
    await tester.enterText(find.byType(TextFormField).at(1), 'incorrecta');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('incorrectos'),
      findsOneWidget,
    );
  });

  testWidgets('error de red muestra el mensaje generico', (tester) async {
    final error = DioException(
      requestOptions: RequestOptions(path: '/mock-sso/login'),
      type: DioExceptionType.connectionError,
    );

    await tester.pumpWidget(_wrap(_FakeMockSsoRepository(dioError: error)));

    await tester.enterText(find.byType(TextFormField).at(0), '220999999');
    await tester.enterText(find.byType(TextFormField).at(1), '123123');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo conectar con el servidor'), findsOneWidget);
  });
}
