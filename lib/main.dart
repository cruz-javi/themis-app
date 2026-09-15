import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'data/repositories/demo_repository.dart';
import 'data/repositories/mock_sso_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  final client = ApiClient();
  final repository = HttpDemoRepository(client);
  final mockSsoRepository = HttpMockSsoRepository(client);

  runApp(
    ThemisApp(repository: repository, mockSsoRepository: mockSsoRepository),
  );
}

class ThemisApp extends StatelessWidget {
  const ThemisApp({
    super.key,
    required this.repository,
    required this.mockSsoRepository,
  });

  final DemoRepository repository;
  final MockSsoRepository mockSsoRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Themis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      routerConfig: buildRouter(repository, mockSsoRepository),
    );
  }
}
