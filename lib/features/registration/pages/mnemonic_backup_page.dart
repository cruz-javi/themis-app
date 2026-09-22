import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/secure_identity_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/ballot_route_args.dart';

/// Respaldo de la frase de recuperacion (12 palabras BIP-39).
///
/// Es el precio de haber quitado la derivacion determinista desde el `sub` del
/// SSO: ahora el servidor no puede recalcular la identidad del votante (que era
/// exactamente lo que permitia asociar voto con votante), y por eso tampoco
/// puede devolversela si la pierde. La frase es la unica copia.
class MnemonicBackupPage extends StatefulWidget {
  const MnemonicBackupPage({
    super.key,
    required this.mnemonic,
    required this.secureIdentityStore,
    required this.electionId,
  });

  final String mnemonic;
  final SecureIdentityStore secureIdentityStore;
  final String electionId;

  @override
  State<MnemonicBackupPage> createState() => _MnemonicBackupPageState();
}

class _MnemonicBackupPageState extends State<MnemonicBackupPage> {
  bool _confirmed = false;
  bool _revealed = false;

  List<String> get _words => widget.mnemonic.split(' ');

  Future<void> _continue() async {
    await widget.secureIdentityStore.markMnemonicBackedUp();
    if (!mounted) return;
    context.pushReplacement(
      '/votar',
      extra: BallotRouteArgs(electionId: widget.electionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Frase de recuperación')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.page,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                            Icons.key_rounded,
                            color: AppColors.accentStrong,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Anota estas 12 palabras en papel',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Son la única forma de recuperar tu voto si pierdes este '
                      'celular o borras la app. Nadie más las tiene: ni la '
                      'universidad, ni el servidor. Si las pierdes, pierdes tu voto.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: AppSpacing.md),
                    if (!_revealed)
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _revealed = true),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Mostrar mis 12 palabras'),
                        ),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (var i = 0; i < _words.length; i++)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.button),
                                border:
                                    Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Text(
                                '${i + 1}. ${_words[i]}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border:
                      Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'La frase recupera tu identidad, no tu credencial. Si tu '
                  'credencial ya fue aprobada por las autoridades, con la frase '
                  'podrás votar desde otro dispositivo.',
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: AppColors.ink),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: _confirmed,
                onChanged: _revealed
                    ? (value) => setState(() => _confirmed = value ?? false)
                    : null,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Ya las anoté en papel y las guardé en un lugar seguro',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _confirmed ? _continue : null,
                  icon: const Icon(Icons.how_to_vote_rounded),
                  label: const Text('Continuar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
