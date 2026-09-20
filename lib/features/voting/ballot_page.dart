import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/crypto/crypto_bridge_exception.dart';
import '../../core/crypto/vote_proof_generator.dart';
import '../../core/storage/secure_identity_store.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/vote_repository.dart';
import '../../domain/entities/public_election.dart';

enum _Outcome { choosing, submitting, done, error }

/// Traduce los `code` de negocio que devuelve el backend (ver voting.errors.ts
/// en themis-core) a un mensaje claro para el votante.
class _BackendNotice {
  const _BackendNotice(this.message);
  final String message;
}

_BackendNotice _mapVoteDioError(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code'] as String? : null;

  switch (code) {
    case 'VOTING_WINDOW_CLOSED':
      return const _BackendNotice('La votación para esta elección no está abierta.');
    case 'VOTING_GROUP_NOT_READY':
      return const _BackendNotice(
        'El padrón todavía no está listo para votar. Intentá más tarde.',
      );
    case 'VOTE_ALREADY_CAST':
      return const _BackendNotice('Ya emitiste tu voto en esta elección.');
    case 'VOTE_INVALID_PROOF':
      return const _BackendNotice('La prueba no fue válida (puede haber vencido). Reintentá.');
    case 'VOTE_OPTION_NOT_FOUND':
    case 'VOTE_SCOPE_MISMATCH':
      return const _BackendNotice('No se pudo validar tu voto. Reintentá.');
    case 'ELECTION_NOT_FOUND':
      return const _BackendNotice('La elección no existe.');
    default:
      return const _BackendNotice('No se pudo conectar con el servidor.');
  }
}

/// CU-10: genera la prueba ZK via VoteProofBridge (WebView interno contra
/// /prove de themis-web, ver ../../core/crypto/vote_proof_bridge.dart) y
/// envia el voto -- sin sesion (regla 1 del CLAUDE.md raiz), la identidad
/// nunca sale de este dispositivo mas que como entrada de la prueba.
class BallotPage extends StatefulWidget {
  const BallotPage({
    super.key,
    required this.election,
    required this.voteRepository,
    required this.secureIdentityStore,
    required this.proofGenerator,
    required this.apiBaseUrl,
  });

  final PublicElection election;
  final VoteRepository voteRepository;
  final SecureIdentityStore secureIdentityStore;
  final VoteProofGenerator proofGenerator;

  // Inyectado (en vez de leer Env.apiBaseUrl aca adentro) para que la
  // pantalla sea testeable sin inicializar flutter_dotenv.
  final String apiBaseUrl;

  @override
  State<BallotPage> createState() => _BallotPageState();
}

class _BallotPageState extends State<BallotPage> {
  _Outcome _outcome = _Outcome.choosing;
  String? _selectedOptionId;
  String? _message;

  Future<void> _submit() async {
    final optionId = _selectedOptionId;
    if (optionId == null) return;

    setState(() => _outcome = _Outcome.submitting);
    try {
      final identityPrivateKey = await widget.secureIdentityStore.read();
      if (identityPrivateKey == null) {
        throw const CryptoBridgeException(
          'No se encontró tu identidad en este dispositivo. Registrate primero.',
        );
      }

      final proof = await widget.proofGenerator.generateProof(
        identityPrivateKey: identityPrivateKey,
        electionId: widget.election.id,
        optionId: optionId,
        apiBaseUrl: widget.apiBaseUrl,
      );

      await widget.voteRepository.submitVote(widget.election.id, proof);

      if (!mounted) return;
      setState(() => _outcome = _Outcome.done);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _outcome = _Outcome.error;
        _message = _mapVoteDioError(error).message;
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
        _message = 'No se pudo emitir el voto: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.election.nombre)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.proofGenerator.widget,
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
                      const Icon(Icons.how_to_vote_rounded, color: AppColors.accentStrong),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Voto emitido',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text('Elegí una opción', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.stack),
                RadioGroup<String>(
                  groupValue: _selectedOptionId,
                  onChanged: _outcome == _Outcome.submitting
                      ? (_) {}
                      : (value) => setState(() => _selectedOptionId = value),
                  child: Column(
                    children: widget.election.opciones
                        .map(
                          (option) => RadioListTile<String>(
                            value: option.id,
                            title: Text(option.nombre),
                            subtitle: option.descripcion != null
                                ? Text(option.descripcion!)
                                : null,
                          ),
                        )
                        .toList(),
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
                  const SizedBox(height: AppSpacing.stack),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _selectedOptionId == null || _outcome == _Outcome.submitting
                        ? null
                        : _submit,
                    child: Text(_outcome == _Outcome.submitting ? 'Enviando…' : 'Emitir voto'),
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
