import 'dart:async';

import 'package:flutter/material.dart';

import 'core/config/env.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/scheduling/credential_presentation_checker.dart';
import 'core/storage/secure_identity_store.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/demo_repository.dart';
import 'data/repositories/mock_sso_repository.dart';
import 'data/repositories/registration_repository.dart';
import 'data/repositories/vote_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  final client = ApiClient();
  final repository = HttpDemoRepository(client);
  final mockSsoRepository = HttpMockSsoRepository(client);
  final registrationRepository = HttpRegistrationRepository(client);
  final voteRepository = HttpVoteRepository(client);
  final secureIdentityStore = SecureIdentityStore();

  runApp(
    ThemisApp(
      repository: repository,
      mockSsoRepository: mockSsoRepository,
      registrationRepository: registrationRepository,
      voteRepository: voteRepository,
      secureIdentityStore: secureIdentityStore,
    ),
  );
}

class ThemisApp extends StatefulWidget {
  const ThemisApp({
    super.key,
    required this.repository,
    required this.mockSsoRepository,
    required this.registrationRepository,
    required this.voteRepository,
    required this.secureIdentityStore,
  });

  final DemoRepository repository;
  final MockSsoRepository mockSsoRepository;
  final RegistrationRepository registrationRepository;
  final VoteRepository voteRepository;
  final SecureIdentityStore secureIdentityStore;

  @override
  State<ThemisApp> createState() => _ThemisAppState();
}

class _ThemisAppState extends State<ThemisApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPendingPresentation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Chequeo oportunista, no un job en background real - ver
    // registration/README.md (themis-core) y credential_presentation_checker.dart.
    if (state == AppLifecycleState.resumed) {
      _checkPendingPresentation();
    }
  }

  void _checkPendingPresentation() {
    unawaited(
      maybePresentPendingCredential(
        secureIdentityStore: widget.secureIdentityStore,
        repository: widget.registrationRepository,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Themis',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: buildRouter(
        widget.repository,
        widget.mockSsoRepository,
        widget.registrationRepository,
        widget.voteRepository,
        widget.secureIdentityStore,
      ),
    );
  }
}
