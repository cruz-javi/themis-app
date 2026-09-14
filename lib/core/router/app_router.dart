import 'package:go_router/go_router.dart';

import '../../data/repositories/demo_repository.dart';
import '../../features/demo/demo_page.dart';

GoRouter buildRouter(DemoRepository repository) {
  return GoRouter(
    initialLocation: '/demo',
    routes: [
      GoRoute(
        path: '/demo',
        builder: (context, state) => DemoPage(repository: repository),
      ),
    ],
  );
}
