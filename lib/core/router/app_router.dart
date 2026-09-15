import 'package:go_router/go_router.dart';

import '../../data/repositories/demo_repository.dart';
import '../../data/repositories/mock_sso_repository.dart';
import '../../domain/entities/mock_sso_assertion.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/login_result_page.dart';
import '../../features/demo/demo_page.dart';

GoRouter buildRouter(
  DemoRepository repository,
  MockSsoRepository mockSsoRepository,
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
          payload: state.extra as MockSsoAssertionPayload,
        ),
      ),
      GoRoute(
        path: '/demo',
        builder: (context, state) => DemoPage(repository: repository),
      ),
    ],
  );
}
