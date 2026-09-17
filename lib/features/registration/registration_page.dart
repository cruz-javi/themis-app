import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/config/credential_presentation_config.dart';
import '../../core/crypto/crypto_bridge.dart';
import '../../core/crypto/crypto_bridge_exception.dart';
import '../../core/storage/secure_identity_store.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/registration_repository.dart';
import 'widgets/registration_steps.dart';

enum _Outcome { working, done, error, notice }

Duration _randomPresentationDelay() {
  final minMs = CredentialPresentationConfig.minDelay.inMilliseconds;
  final maxMs = CredentialPresentationConfig.maxDelay.inMilliseconds;
  final offset = Random().nextInt(maxMs - minMs + 1);
  return Duration(milliseconds: minMs + offset);
}

/// Traduce los `code` de negocio que devuelve el backend (ver
/// registration.errors.ts en themis-core) a un mensaje claro para el
/// votante. [isInfo] separa "ya estabas registrado" (no es un error, es
/// informativo) del resto (errores reales).
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
        message: 'Tu sesión expiró. Volvé a iniciar sesión e intentá de nuevo.',
        isInfo: false,
      );
    case 'ELECTION_NOT_FOUND':
      return const _BackendNotice(message: 'La elección no existe.', isInfo: false);
    default:
      return const _BackendNotice(
        message: 'No se pudo conectar con el servidor.',
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
  });

  final RegistrationRepository repository;
  final SecureIdentityStore secureIdentityStore;

  // Todavia no existe una pantalla de seleccion de eleccion (fuera del
  // alcance de esta iteracion) - el id se recibe desde donde se navegue a
  // esta pagina.
  final String electionId;

  // Assertion de mock-sso obtenida en el login; el backend la vuelve a
  // verificar para autenticar el registro (regla 1 del CLAUDE.md raiz).
  final String assertion;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  late final CryptoBridge _bridge;
  _Outcome _outcome = _Outcome.working;

  // Indice sobre registrationSteps (widgets/registration_steps.dart) - cada
  // paso tecnico se muestra como un paso de la analogia del "sobre carbon".
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
      final identity = await _bridge.generateIdentity();
      if (!mounted) return;
      setState(() => _stepIndex = 1); // guardando el secreto
      await widget.secureIdentityStore.write(identity.privateKey);

      if (!mounted) return;
      setState(() => _stepIndex = 2); // sellando el sobre (cegado)
      final publicKeyJwk = await widget.repository.fetchPublicKey();
      final blinded = await _bridge.blindCommitment(
        publicKeyJwk: publicKeyJwk,
        commitment: identity.commitment,
      );

      if (!mounted) return;
      setState(() => _stepIndex = 3); // la oficina recibe y firma
      final blindSignature = await widget.repository.submit(
        electionId: widget.electionId,
        assertion: widget.assertion,
        blindedMessage: blinded.blindedMessage,
      );

      if (!mounted) return;
      setState(() => _stepIndex = 4); // abriendo el sobre en el dispositivo
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

      if (!mounted) return;
      setState(() => _outcome = _Outcome.done);
    } on DioException catch (error) {
      if (!mounted) return;
      final notice = _mapDioError(error);
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de votante')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bridge.widget,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.card + 4),
                  child: RegistrationSteps(
                    currentIndex: _stepIndex,
                    allDone: _outcome == _Outcome.done,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stack),
              if (_outcome == _Outcome.error) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.card),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _message!,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.error),
                  ),
                ),
              ],
              if (_outcome == _Outcome.notice) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.card),
                  decoration: BoxDecoration(
                    color: AppColors.accentStrong.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.accentStrong.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.accentStrong,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _message!,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_outcome == _Outcome.done) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.card),
                  decoration: BoxDecoration(
                    color: AppColors.accentStrong.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.accentStrong.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drafts_rounded, color: AppColors.accentStrong),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Credencial certificada lista',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
