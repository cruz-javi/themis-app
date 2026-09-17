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

/// Analogia del "sobre carbon" (docs/diseno-consolidado.md, seccion 2) llevada
/// a la UI: cada paso tecnico del registro (cegado RSA, firma ciega, etc.) se
/// explica en terminos de un sobre que se sella, se firma sin abrirlo, y se
/// abre en casa - sin jerga criptografica para el votante.
const List<RegistrationStepInfo> registrationSteps = [
  RegistrationStepInfo(
    icon: Icons.badge_outlined,
    title: 'Creamos tu identidad secreta',
    subtitle: 'Un papelito lacrado que solo vos podes abrir.',
  ),
  RegistrationStepInfo(
    icon: Icons.lock_outline,
    title: 'La guardamos en tu dispositivo',
    subtitle: 'Nunca sale de tu celular.',
  ),
  RegistrationStepInfo(
    icon: Icons.markunread_mailbox_outlined,
    title: 'La sellamos en un sobre carbon',
    subtitle: 'Nadie puede ver que hay adentro, ni la oficina de registro.',
  ),
  RegistrationStepInfo(
    icon: Icons.verified_outlined,
    title: 'La oficina de registro firma el sobre',
    subtitle: 'Confirma que estas habilitado, sin abrirlo ni ver tu papelito.',
  ),
  RegistrationStepInfo(
    icon: Icons.drafts_outlined,
    title: 'Abris el sobre en tu dispositivo',
    subtitle: 'Ahora tenes un papelito certificado.',
  ),
];

class RegistrationSteps extends StatelessWidget {
  const RegistrationSteps({super.key, required this.currentIndex, required this.allDone});

  /// Indice del paso en curso (0-based). Los anteriores se muestran como
  /// completados; los siguientes, como pendientes.
  final int currentIndex;

  /// true cuando ya se completo el ultimo paso (muestra todo en verde, sin
  /// spinner).
  final bool allDone;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            textTheme: textTheme,
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
      StepState.done => AppColors.accentStrong,
      StepState.active => AppColors.ink,
      StepState.pending => AppColors.borderSubtle,
    };
    final iconColor = state == StepState.pending ? AppColors.inkSoft : AppColors.onInk;
    final titleColor = state == StepState.pending ? AppColors.inkSoft : AppColors.ink;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
                child: Center(
                  child: state == StepState.active
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: iconColor,
                          ),
                        )
                      : Icon(
                          state == StepState.done ? Icons.check_rounded : info.icon,
                          size: 18,
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
                        ? AppColors.accentStrong
                        : AppColors.borderSubtle,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
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
                    style: textTheme.bodySmall?.copyWith(color: AppColors.inkSoft),
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
