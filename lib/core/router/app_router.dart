import 'package:go_router/go_router.dart';

import '../../data/repositories/demo_repository.dart';
import '../../data/repositories/mock_sso_repository.dart';
import '../../data/repositories/registration_repository.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/entities/registration_route_args.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/login_result_page.dart';
import '../../features/demo/demo_page.dart';
import '../../features/registration/registration_page.dart';
import '../storage/secure_identity_store.dart';

GoRouter buildRouter(
  DemoRepository repository,
  MockSsoRepository mockSsoRepository,
  RegistrationRepository registrationRepository,
  SecureIdentityStore secureIdentityStore,
) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(repository: mockSsoRepository),
      ),
      GoRoute(
        path: '/login/resultado',
        builder: (context, state) => LoginResultPage(
          result: state.extra as LoginResult,
        ),
      ),
      GoRoute(
        path: '/registro',
        builder: (context, state) {
          final args = state.extra as RegistrationRouteArgs;
          return RegistrationPage(
            repository: registrationRepository,
            secureIdentityStore: secureIdentityStore,
            electionId: args.electionId,
            assertion: args.assertion,
          );
        },
      ),
      GoRoute(
        path: '/demo',
        builder: (context, state) => DemoPage(repository: repository),
      ),
    ],
  );
}
