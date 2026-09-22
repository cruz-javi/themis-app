import 'package:go_router/go_router.dart';

import '../../data/repositories/demo_repository.dart';
import '../../data/repositories/mock_sso_repository.dart';
import '../../data/repositories/registration_repository.dart';
import '../../data/repositories/voting_repository.dart';
import '../../domain/entities/ballot_route_args.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/entities/mnemonic_backup_route_args.dart';
import '../../domain/entities/registration_route_args.dart';
import '../../domain/entities/vote_receipt.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/login_result_page.dart';
import '../../features/demo/demo_page.dart';
import '../../features/recovery/pages/restore_identity_page.dart';
import '../../features/registration/pages/mnemonic_backup_page.dart';
import '../../features/registration/registration_page.dart';
import '../../features/voting/pages/ballot_page.dart';
import '../../features/voting/pages/vote_receipt_page.dart';
import '../storage/secure_identity_store.dart';

GoRouter buildRouter(
  DemoRepository repository,
  MockSsoRepository mockSsoRepository,
  RegistrationRepository registrationRepository,
  SecureIdentityStore secureIdentityStore,
  VotingRepository votingRepository,
) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          repository: mockSsoRepository,
        ),
      ),
      GoRoute(
        path: '/login/resultado',
        name: 'login_resultado',
        builder: (context, state) => LoginResultPage(
          result: state.extra as LoginResult,
          votingRepository: votingRepository,
          secureIdentityStore: secureIdentityStore,
        ),
      ),
      GoRoute(
        path: '/login/result',
        builder: (context, state) => LoginResultPage(
          result: state.extra as LoginResult,
          votingRepository: votingRepository,
          secureIdentityStore: secureIdentityStore,
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
        path: '/identidad/respaldo',
        builder: (context, state) {
          final args = state.extra as MnemonicBackupRouteArgs;
          return MnemonicBackupPage(
            mnemonic: args.mnemonic,
            secureIdentityStore: secureIdentityStore,
            electionId: args.electionId,
          );
        },
      ),
      GoRoute(
        path: '/identidad/restaurar',
        builder: (context, state) => RestoreIdentityPage(
          secureIdentityStore: secureIdentityStore,
        ),
      ),
      GoRoute(
        path: '/votar',
        builder: (context, state) {
          final extra = state.extra;
          String? electionId;
          if (extra is BallotRouteArgs) {
            electionId = extra.electionId;
          } else if (extra is String) {
            electionId = extra;
          } else {
            electionId = state.uri.queryParameters['electionId'];
          }
          return BallotPage(
            votingRepository: votingRepository,
            secureIdentityStore: secureIdentityStore,
            electionId: electionId,
          );
        },
      ),
      GoRoute(
        path: '/voto/recibo',
        builder: (context, state) => VoteReceiptPage(
          receipt: state.extra as VoteReceipt,
        ),
      ),
      GoRoute(
        path: '/demo',
        builder: (context, state) => DemoPage(repository: repository),
      ),
    ],
  );
}
