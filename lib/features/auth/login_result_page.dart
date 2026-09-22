import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/crypto/identity_seed.dart';
import '../../core/storage/secure_identity_store.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/voting_repository.dart';
import '../../domain/entities/ballot_election.dart';
import '../../domain/entities/ballot_route_args.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/entities/registration_route_args.dart';
import '../../domain/entities/vote_receipt.dart';

class LoginResultPage extends StatefulWidget {
  const LoginResultPage({
    super.key,
    required this.result,
    this.votingRepository,
    this.secureIdentityStore,
  });

  final LoginResult result;
  final VotingRepository? votingRepository;
  final SecureIdentityStore? secureIdentityStore;

  @override
  State<LoginResultPage> createState() => _LoginResultPageState();
}

class _LoginResultPageState extends State<LoginResultPage> {
  bool _loadingElections = false;
  bool _isVoteEnabledLocally = false;
  bool _hasVotedInCurrentElection = false;
  VoteReceipt? _currentElectionVoteReceipt;
  List<BallotElection> _activeElections = [];
  BallotElection? _selectedElection;

  bool _isCheckingStatus = false;

  /// El servidor dice que esta registrado pero el dispositivo no tiene la
  /// identidad: hay que restaurarla con la frase de 12 palabras. Antes esto se
  /// resolvia derivando la identidad del `sub`, lo que permitia al servidor
  /// recalcularla y asociar cada voto con su votante.
  bool _needsIdentityRestore = false;

  /// Etiqueta de la cuenta logueada. Si el dispositivo tiene guardada la
  /// identidad de otra cuenta, su estado local (recibo de voto, marca de
  /// registro) no aplica a esta sesion.
  String get _accountTag => accountTagFromSub(widget.result.payload.sub);

  @override
  void initState() {
    super.initState();
    _fetchActiveElections();
  }

  Future<void> _checkLocalIdentity() async {
    if (widget.secureIdentityStore == null) return;
    try {
      final currentId = _currentElectionId ??
          (_activeElections.isNotEmpty ? _activeElections.first.id : null);
      if (currentId == null) {
        if (!mounted) return;
        setState(() {
          _isVoteEnabledLocally = false;
          _hasVotedInCurrentElection = false;
          _currentElectionVoteReceipt = null;
          _isCheckingStatus = false;
        });
        return;
      }

      // El dispositivo guarda la identidad de un solo votante a la vez. Si lo
      // guardado es de otra cuenta, su recibo y su marca de registro no aplican
      // a esta sesion: mostrarlos diria "ya votaste" a alguien que no voto.
      final savedTag = await widget.secureIdentityStore!.readAccountTag();
      final sameAccount = savedTag == null || savedTag == _accountTag;

      // 1. VERIFICACIÓN LOCAL INMEDIATA (0 ms)
      // Si el elector ya votó en este dispositivo, actualizamos al instante
      // sin esperar la respuesta de la red para evitar parpadeos o doble clic.
      String? identity = sameAccount ? await widget.secureIdentityStore!.read() : null;
      final localReceipt =
          sameAccount ? await widget.secureIdentityStore!.getVoteReceipt(currentId) : null;
      final localHasVoted = localReceipt != null;
      final localIsRegistered = sameAccount &&
          await widget.secureIdentityStore!.isElectionRegistered(currentId);

      if (!mounted) return;
      setState(() {
        if (localHasVoted) {
          _hasVotedInCurrentElection = true;
          _isVoteEnabledLocally = false;
          _currentElectionVoteReceipt = localReceipt;
        }
        _isCheckingStatus = true;
      });

      // 2. VERIFICACIÓN EN PADRÓN ELECTORAL (Servidor)
      bool serverIsRegistered = false;
      if (widget.votingRepository != null && widget.result.assertion.isNotEmpty) {
        try {
          final status = await widget.votingRepository!.fetchVoterStatus(
            electionId: currentId,
            assertion: widget.result.assertion,
          );
          serverIsRegistered = status.isRegistered;
          debugPrint(
            '[voter-status] Servidor ($currentId): isRegistered=${status.isRegistered}',
          );
        } catch (e) {
          debugPrint('[voter-status] Error al consultar servidor: $e');
        }
      }

      // `hasVoted` sale solo del recibo local: el servidor ya no lo informa,
      // porque para hacerlo tenia que guardar quien voto y cuando, y eso
      // permitia cruzar por hora la persona con su opcion. El doble voto lo
      // sigue frenando el nullifier on-chain (409 DUPLICATE_VOTE).
      final hasVoted = localHasVoted;
      final isRegistered = serverIsRegistered || localIsRegistered;

      if (isRegistered) {
        await widget.secureIdentityStore!.markElectionRegistered(currentId);
      }

      final hasSecret = identity != null && identity.isNotEmpty;

      if (!mounted) return;
      setState(() {
        _hasVotedInCurrentElection = hasVoted;
        _isVoteEnabledLocally = hasSecret && isRegistered && !hasVoted;
        // Registrado en el padron pero sin identidad en este dispositivo:
        // solo la frase de recuperacion puede devolverla.
        _needsIdentityRestore = isRegistered && !hasSecret && !hasVoted && sameAccount;
        _currentElectionVoteReceipt = localReceipt;
        _isCheckingStatus = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _fetchActiveElections() async {
    if (widget.votingRepository == null) return;
    setState(() => _loadingElections = true);
    try {
      final list = await widget.votingRepository!.fetchActiveElections();
      if (!mounted) return;
      setState(() {
        _activeElections = list;
        if (list.isNotEmpty) {
          final current = _selectedElection;
          if (current != null && list.any((e) => e.id == current.id)) {
            _selectedElection = list.firstWhere((e) => e.id == current.id);
          } else {
            _selectedElection = list.first;
          }
        } else {
          _selectedElection = null;
        }
        _loadingElections = false;
      });
      await _checkLocalIdentity();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingElections = false);
    }
  }

  String? get _currentElectionId => _selectedElection?.id;

  void _confirmLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          '¿Deseas salir del sistema de votación?',
          style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.inkSoft)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await widget.secureIdentityStore?.clear();
              if (mounted) {
                context.go('/login');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.result.payload;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Panel de Votación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.inkSoft),
            tooltip: 'Cerrar Sesión',
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accentStrong,
          onRefresh: _fetchActiveElections,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.page,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Tarjeta de Credencial Digital del Votante
                _buildDigitalCredentialCard(payload, theme),

                const SizedBox(height: AppSpacing.lg),

                // 2. Sección de Elecciones Universitarias
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Elección Universitaria',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_loadingElections)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentStrong,
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        color: AppColors.inkSoft,
                        tooltip: 'Actualizar elecciones',
                        onPressed: _fetchActiveElections,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                _buildElectionsSection(theme, payload.habilitado),

                const SizedBox(height: AppSpacing.lg),

                // 3. Nota amigable sobre el secreto y anonimato del voto
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.privacy_tip_outlined,
                        color: AppColors.accentStrong,
                        size: 22,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tu voto es 100% secreto',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'El sistema separa por completo tu identidad institucional de tu boleta electoral. Nadie en la universidad ni en el sistema puede saber por quién votaste.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.inkSoft,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalCredentialCard(dynamic payload, ThemeData theme) {
    final bool isHabilitado = payload.habilitado as bool;

    return Container(
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isHabilitado
                      ? AppColors.successLight
                      : AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isHabilitado
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: isHabilitado ? AppColors.success : AppColors.error,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.result.codigoInstitucional != null &&
                              widget.result.codigoInstitucional!.isNotEmpty
                          ? 'Estudiante: ${widget.result.codigoInstitucional}'
                          : 'Estudiante Universitario',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHabilitado
                          ? (_hasVotedInCurrentElection
                              ? 'Voto emitido con éxito'
                              : (_isVoteEnabledLocally
                                  ? 'Habilitado y listo para votar'
                                  : 'Habilitado en el Padrón Electoral'))
                          : 'No Habilitado para Votar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isHabilitado
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
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

          // Metadatos de la credencial con espacio adaptativo
          Row(
            children: [
              Expanded(
                child: _CredentialField(
                  label: 'Facultad',
                  value: payload.facultad as String,
                  icon: Icons.account_balance_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _CredentialField(
                  label: 'Estamento',
                  value: payload.tipoUsuario as String,
                  icon: Icons.school_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElectionsSection(ThemeData theme, bool habilitado) {
    if (_loadingElections && _activeElections.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.accentStrong),
              SizedBox(height: AppSpacing.md),
              Text(
                'Cargando elecciones disponibles...',
                style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeElections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy_rounded,
              size: 40,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No hay elecciones activas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No hay procesos de votación abiertos en este momento.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: _fetchActiveElections,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      );
    }

    final election = _selectedElection ?? _activeElections.first;
    final isVotingOpen = election.estado == 'VOTACION_ABIERTA';

    return Container(
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
          // Selector si hay más de 1 elección
          if (_activeElections.length > 1) ...[
            DropdownButtonFormField<BallotElection>(
              initialValue: _selectedElection,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Elección',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              items: _activeElections.map((e) {
                return DropdownMenuItem(
                  value: e,
                  child: Text(
                    e.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedElection = val);
                  _checkLocalIdentity();
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Estado y cantidad de candidaturas
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isVotingOpen ? AppColors.successLight : AppColors.infoLight,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: isVotingOpen
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isVotingOpen ? 'Votación Abierta' : 'Registro de Votantes',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isVotingOpen ? AppColors.success : AppColors.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${election.opciones.length} Candidaturas',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Título de la elección
          Text(
            election.nombre,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          if (election.descripcion != null &&
              election.descripcion!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              election.descripcion!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.inkSoft,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          // Botón único e inteligente según estado de votación y habilitación
          if (habilitado) ...[
            if (_hasVotedInCurrentElection) ...[
              // YA VOTÓ EN ESTA ELECCIÓN: Se muestra estado completado y botón para ver constancia
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Ya emitiste tu voto!',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tu participación fue registrada y contabilizada de manera anónima en esta elección.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_currentElectionVoteReceipt != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await context.push(
                              '/voto/recibo',
                              extra: _currentElectionVoteReceipt,
                            );
                            _checkLocalIdentity();
                          },
                          icon: const Icon(Icons.receipt_long_rounded, size: 18),
                          label: const Text(
                            'Ver constancia de voto',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.borderMedium),
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
            ] else if (_isVoteEnabledLocally) ...[
              // Ya está habilitado para votar: Sale ÚNICAMENTE ingresar a votar
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _currentElectionId != null && isVotingOpen && !_isCheckingStatus
                      ? () async {
                          await context.push(
                            '/votar',
                            extra: BallotRouteArgs(
                              electionId: _currentElectionId!,
                            ),
                          );
                          await _checkLocalIdentity();
                        }
                      : null,
                  icon: _isCheckingStatus
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.how_to_vote_rounded, size: 20),
                  label: Text(
                    _isCheckingStatus
                        ? 'Verificando estado...'
                        : (isVotingOpen ? 'Ingresar a votar' : 'Votación no iniciada aún'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    backgroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ] else if (_needsIdentityRestore) ...[
              // Registrado en el padrón, pero este dispositivo no tiene la
              // identidad. Solo la frase de 12 palabras puede devolverla: el
              // servidor no la conoce, y que no la conozca es justamente lo
              // que impide asociar un voto con su votante.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border:
                      Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Ya estás habilitado en el padrón, pero este dispositivo no '
                  'tiene tu identidad de voto. Restaurala con las 12 palabras '
                  'que anotaste al registrarte.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCheckingStatus
                      ? null
                      : () async {
                          await context.push('/identidad/restaurar');
                          await _checkLocalIdentity();
                        },
                  icon: const Icon(Icons.key_rounded, size: 20),
                  label: const Text('Restaurar con mis 12 palabras'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Aún no está habilitado: Sale ÚNICAMENTE habilitar mi voto
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _currentElectionId != null && !_isCheckingStatus
                      ? () async {
                          await context.push(
                            '/registro',
                            extra: RegistrationRouteArgs(
                              electionId: _currentElectionId!,
                              assertion: widget.result.assertion,
                              accountTag: _accountTag,
                            ),
                          );
                          await _checkLocalIdentity();
                        }
                      : null,
                  icon: _isCheckingStatus
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.how_to_reg_rounded, size: 20),
                  label: Text(
                    _isCheckingStatus ? 'Verificando padrón...' : 'Habilitar mi voto',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    backgroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'No te encuentras habilitado en el padrón de esta elección.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CredentialField extends StatelessWidget {
  const _CredentialField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.inkMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
