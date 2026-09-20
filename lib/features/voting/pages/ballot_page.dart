import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/crypto/crypto_bridge_exception.dart';
import '../../../core/crypto/prover_bridge.dart';
import '../../../core/storage/secure_identity_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/voting_repository.dart';
import '../../../domain/entities/ballot_election.dart';
import '../../../domain/entities/ballot_option.dart';

class BallotPage extends StatefulWidget {
  const BallotPage({
    super.key,
    required this.votingRepository,
    required this.secureIdentityStore,
    this.electionId,
    this.assertion,
  });

  final VotingRepository votingRepository;
  final SecureIdentityStore secureIdentityStore;
  final String? electionId;
  final String? assertion;

  @override
  State<BallotPage> createState() => _BallotPageState();
}

class _BallotPageState extends State<BallotPage> {
  late final ProverBridge _proverBridge;

  bool _isLoading = true;
  String? _errorMessage;
  List<BallotElection> _activeElections = [];
  BallotElection? _selectedElection;
  BallotOption? _selectedOption;

  bool _isCastingVote = false;
  String _castingStatus = '';

  @override
  void initState() {
    super.initState();
    _proverBridge = ProverBridge();
    _loadElections();
  }

  Future<void> _loadElections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.electionId != null && widget.electionId!.isNotEmpty) {
        final election = await widget.votingRepository.fetchElectionDetails(
          widget.electionId!,
        );
        if (!mounted) return;
        setState(() {
          _selectedElection = election;
          _isLoading = false;
        });
      } else {
        final elections = await widget.votingRepository.fetchActiveElections();
        if (!mounted) return;
        setState(() {
          _activeElections = elections;
          if (elections.length == 1) {
            _selectedElection = elections.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudieron cargar las elecciones disponibles.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVoteConfirmation() async {
    if (_selectedElection == null || _selectedOption == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ConfirmationModal(
        electionName: _selectedElection!.nombre,
        optionName: _selectedOption!.nombre,
      ),
    );

    if (confirmed == true && mounted) {
      await _castVote();
    }
  }

  Future<void> _castVote() async {
    final election = _selectedElection!;
    final option = _selectedOption!;

    setState(() {
      _isCastingVote = true;
      _castingStatus = 'Verificando tu habilitación...';
    });

    try {
      final secret = await widget.secureIdentityStore.read();
      if (secret == null || secret.isEmpty) {
        throw const CryptoBridgeException(
          'No se encontró una identidad registrada en este dispositivo. Completa el registro previo.',
        );
      }

      if (!mounted) return;
      setState(() {
        _castingStatus = 'Consultando el padrón electoral...';
      });

      final merkleTree = await widget.votingRepository.fetchMerkleTree(
        election.id,
      );
      if (merkleTree.members.isEmpty) {
        throw const CryptoBridgeException(
          'El padrón electoral aún no contiene miembros aprobados.',
        );
      }

      if (!mounted) return;
      setState(() {
        _castingStatus = 'Cifrando tu voto de manera anónima...';
      });

      final message = option.onChainIndex?.toString() ?? '1';
      final scope = election.onChainGroupId ?? '1';

      final proof = await _proverBridge.generateProof(
        privateKey: secret,
        members: merkleTree.members,
        message: message,
        scope: scope,
      );

      if (!mounted) return;
      setState(() {
        _castingStatus = 'Registrando tu voto oficial...';
      });

      final receipt = await widget.votingRepository.castVote(
        electionId: election.id,
        optionId: option.id,
        proof: proof,
        assertion: widget.assertion,
      );

      await widget.secureIdentityStore.saveVoteReceipt(
        electionId: election.id,
        receipt: receipt,
      );

      if (!mounted) return;
      context.pushReplacement('/voto/recibo', extra: receipt);
    } on DioException catch (dioErr) {
      if (!mounted) return;
      final data = dioErr.response?.data;
      final code = data is Map ? data['code'] as String? : null;

      String msg = 'Ocurrió un error al enviar el voto al servidor.';
      if (code == 'DUPLICATE_VOTE') {
        msg = 'Tu voto ya fue registrado previamente para esta elección (intento de doble voto prevenido).';
      } else if (code == 'ELECTION_NOT_OPEN_FOR_VOTING') {
        msg = 'El periodo de votación para esta elección no está abierto.';
      } else if (code == 'INVALID_VOTE_PROOF') {
        msg = 'La prueba de conocimiento cero no pudo ser verificada.';
      }

      _showErrorDialog(msg);
    } on CryptoBridgeException catch (cbErr) {
      if (!mounted) return;
      _showErrorDialog(cbErr.message);
    } catch (err) {
      if (!mounted) return;
      _showErrorDialog('No se pudo completar la emisión del voto: $err');
    } finally {
      if (mounted) {
        setState(() {
          _isCastingVote = false;
          _castingStatus = '';
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text(
          'Atención',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.ink,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cabina de Votación'),
        leading: _selectedElection != null && _activeElections.length > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _selectedElection = null;
                  _selectedOption = null;
                }),
              )
            : null,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _proverBridge.widget,
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.accentStrong),
              )
            else if (_errorMessage != null)
              _buildErrorView(theme)
            else if (_selectedElection == null)
              _buildElectionSelector(theme)
            else
              _buildBallotContent(theme),
            if (_isCastingVote)
              _buildLoadingOverlay(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.inkSoft),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _loadElections,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElectionSelector(ThemeData theme) {
    if (_activeElections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.how_to_vote_outlined, size: 48, color: AppColors.inkSoft),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No hay elecciones abiertas para votación en este momento.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _loadElections,
                child: const Text('Actualizar'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.page),
      itemCount: _activeElections.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final election = _activeElections[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.card,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () => setState(() => _selectedElection = election),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'VOTACIÓN ABIERTA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    election.nombre,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (election.descripcion != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      election.descripcion!,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${election.opciones.length} candidaturas registradas',
                        style: theme.textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.inkSoft),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBallotContent(ThemeData theme) {
    final election = _selectedElection!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.page,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera de la boleta oficial
                Container(
                  width: double.infinity,
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
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accentLight,
                                borderRadius: BorderRadius.circular(AppRadius.chip),
                                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'BOLETA OFICIAL',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.accentStrong,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.lock_rounded, size: 16, color: AppColors.accentStrong),
                          const SizedBox(width: 4),
                          Text(
                            'Voto Secreto',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.accentStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        election.nombre,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (election.descripcion != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          election.descripcion!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Elige tu opción de voto',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Selecciona una sola candidatura para emitir tu voto anónimo.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Lista de Opciones de Votación
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: election.opciones.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final option = election.opciones[index];
                    final isSelected = _selectedOption?.id == option.id;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentLight.withValues(alpha: 0.5) : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isSelected ? AppColors.accentStrong : AppColors.borderSubtle,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? AppShadows.elevated : AppShadows.card,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        onTap: () => setState(() => _selectedOption = option),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Row(
                            children: [
                              // Número o Letra de Lista
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accentStrong : AppColors.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isSelected ? AppColors.onInk : AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),

                              // Nombre y descripción
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.nombre,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? AppColors.ink : AppColors.ink,
                                      ),
                                    ),
                                    if (option.descripcion != null &&
                                        option.descripcion!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        option.descripcion!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Radio selector animado
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.accentStrong : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppColors.accentStrong : AppColors.borderMedium,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),

        // Barra inferior de emisión de voto
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(
              top: BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
            boxShadow: AppShadows.card,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _selectedOption != null ? _handleVoteConfirmation : null,
              icon: const Icon(Icons.how_to_vote_rounded, size: 20),
              label: Text(
                _selectedOption != null
                    ? 'Confirmar voto'
                    : 'Selecciona una candidatura',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                disabledBackgroundColor: AppColors.borderMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay(ThemeData theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accentStrong,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Registrando tu voto...',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _castingStatus,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationModal extends StatelessWidget {
  const _ConfirmationModal({
    required this.electionName,
    required this.optionName,
  });

  final String electionName;
  final String optionName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      padding: const EdgeInsets.all(AppSpacing.page),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderMedium,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Confirmar tu voto',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Estás a punto de emitir tu voto por la candidatura:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.accentStrong, size: 22),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      optionName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Esta acción es definitiva. Tu voto es 100% secreto y no se puede modificar ni rastrear.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text('Volver'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: const Text('Confirmar mi voto'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
