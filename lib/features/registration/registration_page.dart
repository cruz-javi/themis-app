import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/credential_presentation_config.dart';
import '../../core/crypto/crypto_bridge.dart';
import '../../core/crypto/crypto_bridge_exception.dart';
import '../../core/storage/secure_identity_store.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/registration_repository.dart';
import '../../domain/entities/ballot_route_args.dart';
import 'widgets/registration_steps.dart';

enum _Outcome { working, done, error, notice }

Duration _randomPresentationDelay() {
  final minMs = CredentialPresentationConfig.minDelay.inMilliseconds;
  final maxMs = CredentialPresentationConfig.maxDelay.inMilliseconds;
  final offset = Random().nextInt(maxMs - minMs + 1);
  return Duration(milliseconds: minMs + offset);
}

class _BackendNotice {
  const _BackendNotice({required this.message, required this.isInfo});

  final String message;
  final bool isInfo;
}

_BackendNotice _mapDioError(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code'] as String? : null;

  switch (code) {
    case 'REGISTRATION_ALREADY_REGISTERED':
      return const _BackendNotice(
        message: 'Ya estás registrado en esta elección.',
        isInfo: true,
      );
    case 'REGISTRATION_WINDOW_CLOSED':
      return const _BackendNotice(
        message: 'El registro para esta elección no está abierto.',
        isInfo: false,
      );
    case 'REGISTRATION_NOT_ELIGIBLE':
      return const _BackendNotice(
        message: 'No estás habilitado para registrarte en esta elección.',
        isInfo: false,
      );
    case 'REGISTRATION_INVALID_ASSERTION':
      return const _BackendNotice(
        message: 'Tu sesión expiró. Inicia sesión nuevamente.',
        isInfo: false,
      );
    case 'ELECTION_NOT_FOUND':
      return const _BackendNotice(message: 'La elección no existe.', isInfo: false);
    default:
      return const _BackendNotice(
        message: 'No se pudo conectar con el servidor institucional.',
        isInfo: false,
      );
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({
    super.key,
    required this.repository,
    required this.secureIdentityStore,
    required this.electionId,
    required this.assertion,
    this.sub,
  });

  final RegistrationRepository repository;
  final SecureIdentityStore secureIdentityStore;
  final String electionId;
  final String assertion;
  final String? sub;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  late final CryptoBridge _bridge;
  _Outcome _outcome = _Outcome.working;

  int _stepIndex = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    _bridge = CryptoBridge();
    _run();
  }

  Future<void> _run() async {
    try {
      final seed = widget.sub != null && widget.sub!.isNotEmpty
          ? 'themis:voter:${widget.sub}'
          : null;
      final identity = await _bridge.generateIdentity(seed: seed);
      if (!mounted) return;
      setState(() => _stepIndex = 1);
      await widget.secureIdentityStore.write(identity.privateKey);

      if (!mounted) return;
      setState(() => _stepIndex = 2);
      final publicKeyJwk = await widget.repository.fetchPublicKey();
      final blinded = await _bridge.blindCommitment(
        publicKeyJwk: publicKeyJwk,
        commitment: identity.commitment,
      );

      if (!mounted) return;
      setState(() => _stepIndex = 3);
      final blindSignature = await widget.repository.submit(
        electionId: widget.electionId,
        assertion: widget.assertion,
        blindedMessage: blinded.blindedMessage,
      );

      if (!mounted) return;
      setState(() => _stepIndex = 4);
      final signature = await _bridge.finalizeCredential(
        publicKeyJwk: publicKeyJwk,
        preparedMessage: blinded.preparedMessage,
        blindSignature: blindSignature,
        inv: blinded.inv,
      );
      await widget.secureIdentityStore.writeCredential(
        preparedMessage: blinded.preparedMessage,
        signature: signature,
      );
      await widget.secureIdentityStore.writePresentationSchedule(
        electionId: widget.electionId,
        presentAt: DateTime.now().toUtc().add(_randomPresentationDelay()),
      );

      // Presentar oportunamente
      try {
        await widget.repository.presentCredential(
          electionId: widget.electionId,
          preparedMessage: blinded.preparedMessage,
          signature: signature,
        );
        await widget.secureIdentityStore.markPresentationDone();
      } catch (_) {}

      await widget.secureIdentityStore.markElectionRegistered(widget.electionId);

      if (!mounted) return;
      setState(() => _outcome = _Outcome.done);
    } on DioException catch (error) {
      if (!mounted) return;
      final notice = _mapDioError(error);
      if (notice.isInfo) {
        await widget.secureIdentityStore.markElectionRegistered(widget.electionId);
      }
      setState(() {
        _outcome = notice.isInfo ? _Outcome.notice : _Outcome.error;
        _message = notice.message;
      });
    } on CryptoBridgeException catch (error) {
      if (!mounted) return;
      setState(() {
        _outcome = _Outcome.error;
        _message = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _outcome = _Outcome.error;
        _message = 'No se pudo completar el registro: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Habilitación de Voto'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _bridge.widget,

              // Tarjeta explicativa inicial
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderSubtle),
                  boxShadow: AppShadows.card,
                ),
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.accentLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: AppColors.accentStrong,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preparando tu voto',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Tu voto será 100% anónimo y seguro',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: AppSpacing.md),
                    RegistrationSteps(
                      currentIndex: _stepIndex,
                      allDone: _outcome == _Outcome.done,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              if (_outcome == _Outcome.error) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _message!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_outcome == _Outcome.notice) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.accentStrong,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _message!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => context.pushReplacement(
                      '/votar',
                      extra: BallotRouteArgs(
                        electionId: widget.electionId,
                        assertion: widget.assertion,
                      ),
                    ),
                    icon: const Icon(Icons.how_to_vote_rounded),
                    label: const Text('Ir a la Cabina de Votación'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
              ],

              if (_outcome == _Outcome.done) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '¡Habilitación completada con éxito!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => context.pushReplacement(
                      '/votar',
                      extra: BallotRouteArgs(
                        electionId: widget.electionId,
                        assertion: widget.assertion,
                      ),
                    ),
                    icon: const Icon(Icons.how_to_vote_rounded),
                    label: const Text('Ingresar a votar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
