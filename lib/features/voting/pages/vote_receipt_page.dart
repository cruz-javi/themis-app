import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/vote_receipt.dart';

class VoteReceiptPage extends StatelessWidget {
  const VoteReceiptPage({super.key, required this.receipt});

  final VoteReceipt receipt;

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$label copiado al portapapeles',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Constancia de Votación'),
        automaticallyImplyLeading: false,
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
              // 1. Cabecera limpia de éxito sin logos repetidos
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: AppColors.successLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 30,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '¡Voto Emitido con Éxito!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tu participación ha sido registrada de forma segura y secreta.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 2. Tarjeta de Constancia Oficial de Participación
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CONSTANCIA DE PARTICIPACIÓN',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1, color: AppColors.borderSubtle),
                    const SizedBox(height: AppSpacing.md),

                    _ReceiptField(
                      label: 'Código de Confirmación',
                      value: receipt.txHash,
                      canCopy: true,
                      onCopy: () => _copyToClipboard(
                        context,
                        receipt.txHash,
                        'Código de confirmación',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _ReceiptField(
                      label: 'Identificador de Verificación',
                      value: receipt.nullifier,
                      canCopy: true,
                      onCopy: () => _copyToClipboard(
                        context,
                        receipt.nullifier,
                        'Identificador',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _ReceiptField(
                      label: 'Fecha y Hora',
                      value: receipt.createdAt.toUtc().toIso8601String(),
                      canCopy: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // 3. Tarjeta informativa amigable
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.accentStrong,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Este comprobante certifica que tu voto fue recibido y contabilizado sin vincular tu nombre con tu elección.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkSoft,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 4. Botón de Finalización
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptField extends StatelessWidget {
  const _ReceiptField({
    required this.label,
    required this.value,
    required this.canCopy,
    this.onCopy,
  });

  final String label;
  final String value;
  final bool canCopy;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (canCopy && onCopy != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  color: AppColors.inkSoft,
                  onPressed: onCopy,
                  tooltip: 'Copiar',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
