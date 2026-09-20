import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/login_result.dart';

class LoginResultPage extends StatelessWidget {
  const LoginResultPage({super.key, required this.result});

  final LoginResult result;

  @override
  Widget build(BuildContext context) {
    final payload = result.payload;
    final textTheme = Theme.of(context).textTheme;
    final statusColor = payload.habilitado
        ? AppColors.accentStrong
        : AppColors.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Sesion iniciada')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.card + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              payload.habilitado
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              payload.habilitado
                                  ? 'Habilitado para votar'
                                  : 'No habilitado para votar',
                              style: textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _StatPill(label: 'Facultad', value: payload.facultad),
                          const SizedBox(width: 8),
                          _StatPill(
                            label: 'Tipo',
                            value: payload.tipoUsuario,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (payload.habilitado) ...[
                const SizedBox(height: AppSpacing.stack),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    // La eleccion se elige en /registro/elegir (CU-05); la
                    // assertion viaja como `extra` hasta que ese selector
                    // arme RegistrationRouteArgs con el id real elegido.
                    onPressed: () => context.push(
                      '/registro/elegir',
                      extra: result.assertion,
                    ),
                    child: const Text('Continuar al registro'),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.stack),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  // CU-10 no requiere sesion (regla 1 del CLAUDE.md raiz):
                  // votar no depende de este login ni de la assertion.
                  onPressed: () => context.push('/votar'),
                  child: const Text('Ir a votar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.onInk.withValues(alpha: 0.6)),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
