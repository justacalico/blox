import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/material.dart';

/// Draws the glossy, beveled blocks. Pure painting: takes a rect and a color,
/// so widgets, previews and golden tests all share the same look.
abstract final class BlockPainter {
  static Color lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Paints one block into [rect].
  ///
  /// [ghost] draws the translucent drop preview. [flash] fades the block to
  /// white for the start of a line clear. [opacity] scales everything.
  static void paint(
    Canvas canvas,
    Rect rect,
    Color color, {
    bool ghost = false,
    double flash = 0,
    double opacity = 1,
  }) {
    final base = flash > 0 ? Color.lerp(color, Colors.white, flash)! : color;
    final alpha = (ghost ? 0.45 : 1.0) * opacity;
    if (alpha <= 0) return;

    final radius = Radius.circular(
      rect.shortestSide * BloxMetrics.blockRadiusFactor,
    );
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final bevel = rect.shortestSide * 0.09;

    // Underside: the darker shell that forms the bottom bevel.
    canvas.drawRRect(
      rrect,
      Paint()..color = darken(base, 0.22).withValues(alpha: alpha),
    );

    // Face: inset everywhere, deeper at the bottom so the bevel reads as a
    // shadow under the block.
    final faceRect = Rect.fromLTRB(
      rect.left + bevel,
      rect.top + bevel,
      rect.right - bevel,
      rect.bottom - bevel * 1.9,
    );
    final faceRRect = RRect.fromRectAndRadius(
      faceRect,
      Radius.circular(
        (rect.shortestSide * BloxMetrics.blockRadiusFactor - bevel)
            .clamp(1.0, rect.shortestSide),
      ),
    );
    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lighten(base, 0.16).withValues(alpha: alpha),
            base.withValues(alpha: alpha),
            darken(base, 0.08).withValues(alpha: alpha),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(faceRect),
    );

    // Top edge light catch.
    final topEdge = Rect.fromLTRB(
      faceRect.left + bevel * 0.5,
      faceRect.top,
      faceRect.right - bevel * 0.5,
      faceRect.top + bevel * 0.9,
    );
    canvas.drawRect(
      topEdge,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lighten(base, 0.34).withValues(alpha: alpha * 0.9),
            lighten(base, 0.34).withValues(alpha: 0),
          ],
        ).createShader(topEdge),
    );

    // Glossy spec, top-left.
    final spec = Rect.fromLTWH(
      faceRect.left + faceRect.width * 0.12,
      faceRect.top + faceRect.height * 0.10,
      faceRect.width * 0.34,
      faceRect.height * 0.22,
    );
    canvas.drawOval(
      spec,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Fine outline to keep blocks crisp on the dark grid.
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = darken(base, 0.3).withValues(alpha: alpha * 0.5),
    );
  }

  /// Soft glow used under the drag ghost and over lines about to clear.
  static void paintGlow(Canvas canvas, Rect rect, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.2)),
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }
}
