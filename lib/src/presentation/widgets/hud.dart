import 'package:blox/l10n/generated/app_localizations.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';

/// Crown + best on the left, live score center, pause on the right.
class Hud extends StatelessWidget {
  const Hud({
    super.key,
    required this.score,
    required this.best,
    required this.onPause,
  });

  final int score;
  final int best;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BestChip(best: best, label: l10n.best),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: BloxMotion.snap,
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: child,
              ),
              child: Text(
                '$score',
                key: ValueKey(score),
                style: BloxText.display(52),
              ),
            ),
          ),
        ),
        _PauseButton(onPressed: onPause, tooltip: l10n.pause),
      ],
    );
  }
}

class _BestChip extends StatelessWidget {
  const _BestChip({required this.best, required this.label});

  final int best;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BloxColors.panelDeep,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Crown(size: 20),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: BloxText.label(10)),
              Text('$best', style: BloxText.display(16)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Little crown glyph drawn with paths, matching the screenshots' crown icon.
class _Crown extends StatelessWidget {
  const _Crown({this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CrownPainter(),
    );
  }
}

final class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = BloxColors.crown;
    final path = Path()
      ..moveTo(w * 0.08, h * 0.85)
      ..lineTo(w * 0.92, h * 0.85)
      ..lineTo(w * 0.86, h * 0.32)
      ..lineTo(w * 0.66, h * 0.55)
      ..lineTo(w * 0.5, h * 0.18)
      ..lineTo(w * 0.34, h * 0.55)
      ..lineTo(w * 0.14, h * 0.32)
      ..close();
    canvas.drawPath(path, paint);
    // Base band.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.85, w * 0.84, h * 0.12),
        Radius.circular(h * 0.05),
      ),
      paint,
    );
    // Tip dots.
    for (final dx in [0.14, 0.5, 0.86]) {
      canvas.drawCircle(
        Offset(w * dx, dx == 0.5 ? h * 0.16 : h * 0.3),
        w * 0.05,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CrownPainter old) => false;
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BloxColors.panelDeep,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: _PauseGlyph(),
          ),
        ),
      ),
    );
  }
}

class _PauseGlyph extends StatelessWidget {
  const _PauseGlyph();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 16,
          decoration: BoxDecoration(
            color: BloxColors.inkSoft,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 5,
          height: 16,
          decoration: BoxDecoration(
            color: BloxColors.inkSoft,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
