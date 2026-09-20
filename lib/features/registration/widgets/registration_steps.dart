import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum StepState { pending, active, done }

class RegistrationStepInfo {
  const RegistrationStepInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

/// Pasos claros, sencillos y humanos para el votante común.
const List<RegistrationStepInfo> registrationSteps = [
  RegistrationStepInfo(
    icon: Icons.shield_outlined,
    title: 'Protegiendo tu privacidad',
    subtitle: 'Generando tu clave secreta personal de votación.',
  ),
  RegistrationStepInfo(
    icon: Icons.lock_outline,
    title: 'Guardando en tu teléfono',
    subtitle: 'Tu clave se almacena de forma segura y nunca sale de tu dispositivo.',
  ),
  RegistrationStepInfo(
    icon: Icons.badge_outlined,
    title: 'Verificando con el padrón',
    subtitle: 'Comprobando tu registro oficial de estudiante en la FICCT.',
  ),
  RegistrationStepInfo(
    icon: Icons.verified_outlined,
    title: 'Certificando tu habilitación',
    subtitle: 'Recibiendo la autorización oficial para poder participar.',
  ),
  RegistrationStepInfo(
    icon: Icons.how_to_vote_outlined,
    title: '¡Listo para votar!',
    subtitle: 'Ya puedes ingresar a la cabina y emitir tu voto.',
  ),
];

class RegistrationSteps extends StatelessWidget {
  const RegistrationSteps({
    super.key,
    required this.currentIndex,
    required this.allDone,
  });

  final int currentIndex;
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (var i = 0; i < registrationSteps.length; i++)
          _StepRow(
            info: registrationSteps[i],
            state: allDone || i < currentIndex
                ? StepState.done
                : i == currentIndex
                    ? StepState.active
                    : StepState.pending,
            isLast: i == registrationSteps.length - 1,
            textTheme: theme.textTheme,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.info,
    required this.state,
    required this.isLast,
    required this.textTheme,
  });

  final RegistrationStepInfo info;
  final StepState state;
  final bool isLast;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final circleColor = switch (state) {
      StepState.done => AppColors.success,
      StepState.active => AppColors.ink,
      StepState.pending => AppColors.surfaceVariant,
    };
    final iconColor = state == StepState.pending ? AppColors.inkMuted : AppColors.onInk;
    final titleColor = state == StepState.pending ? AppColors.inkMuted : AppColors.ink;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: Center(
                  child: state == StepState.active
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          state == StepState.done ? Icons.check_rounded : info.icon,
                          size: 16,
                          color: iconColor,
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: state == StepState.done
                        ? AppColors.success
                        : AppColors.borderSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
