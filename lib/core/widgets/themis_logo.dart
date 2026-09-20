import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renderizador vectorial de alta definición de la marca oficial Themis (docs/brand).
/// Dibuja el marco squircle, el arco de equilibrio superior y la barra esmeralda.
class ThemisMark extends StatelessWidget {
  const ThemisMark({
    super.key,
    this.size = 64.0,
    this.isDark = true,
    this.hasBackground = true,
  });

  final double size;
  final bool isDark;
  final bool hasBackground;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ThemisMarkPainter(
        isDark: isDark,
        hasBackground: hasBackground,
      ),
    );
  }
}

class _ThemisMarkPainter extends CustomPainter {
  const _ThemisMarkPainter({
    required this.isDark,
    required this.hasBackground,
  });

  final bool isDark;
  final bool hasBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // 1. Fondo squircle redondeado (si está habilitado)
    if (hasBackground) {
      final cornerRadius = s * 0.22;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s),
        Radius.circular(cornerRadius),
      );
      final bgPaint = Paint()
        ..color = isDark ? AppColors.ink : AppColors.background
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, bgPaint);
    }

    // 2. Arco superior (símbolo de equilibrio / Themis)
    // El trazo va de 292.04° con un barrido de 315.92° en sentido horario
    final strokeWidth = s * 0.11;
    final arcPaint = Paint()
      ..color = (isDark || hasBackground) ? AppColors.onInk : AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final radius = s * 0.355;
    final arcRect = Rect.fromCircle(
      center: Offset(s * 0.5, s * 0.5),
      radius: radius,
    );

    // Convertir a radianes
    const startAngle = 292.04 * (math.pi / 180.0);
    const sweepAngle = 315.92 * (math.pi / 180.0);

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

    // 3. Barra horizontal esmeralda (pill bar)
    final barX = s * 0.20;
    final barY = s * 0.445;
    final barW = s * 0.60;
    final barH = s * 0.11;
    final pillRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(barX, barY, barW, barH),
      Radius.circular(barH / 2),
    );

    final pillPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;

    canvas.drawRRect(pillRRect, pillPaint);
  }

  @override
  bool shouldRepaint(covariant _ThemisMarkPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.hasBackground != hasBackground;
  }
}

/// Cabecera de marca con logotipo, nombre institucional y subtítulo.
class ThemisBrandHeader extends StatelessWidget {
  const ThemisBrandHeader({
    super.key,
    this.title = 'Themis',
    this.subtitle = 'Sistema de Voto Seguro FICCT',
    this.logoSize = 56.0,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textAlign = TextAlign.center,
  });

  final String title;
  final String subtitle;
  final double logoSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        ThemisMark(size: logoSize),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: textAlign,
          style: theme.textTheme.displayMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          textAlign: textAlign,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
