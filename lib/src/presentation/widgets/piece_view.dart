import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:blox/src/presentation/painters/block_painter.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';

/// Renders a piece as a tight grid of glossy blocks.
class PieceView extends StatelessWidget {
  const PieceView({
    super.key,
    required this.piece,
    required this.cellPx,
    this.dimmed = false,
    this.ghost = false,
  });

  final Piece piece;
  final double cellPx;
  final bool dimmed;
  final bool ghost;

  static Color colorOf(int colorIndex) =>
      BloxColors.blocks[colorIndex % BloxColors.blocks.length];

  @override
  Widget build(BuildContext context) {
    final shape = piece.shape;
    return SizedBox(
      width: shape.width * cellPx,
      height: shape.height * cellPx,
      child: CustomPaint(
        painter: _PiecePainter(
          shape: shape,
          color: colorOf(piece.colorIndex),
          cellPx: cellPx,
          dimmed: dimmed,
          ghost: ghost,
        ),
      ),
    );
  }
}

final class _PiecePainter extends CustomPainter {
  const _PiecePainter({
    required this.shape,
    required this.color,
    required this.cellPx,
    required this.dimmed,
    required this.ghost,
  });

  final PieceShape shape;
  final Color color;
  final double cellPx;
  final bool dimmed;
  final bool ghost;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = cellPx * 0.04;
    for (final c in shape.cells) {
      final rect = Rect.fromLTWH(
        c.col * cellPx + inset,
        c.row * cellPx + inset,
        cellPx - inset * 2,
        cellPx - inset * 2,
      );
      if (ghost) {
        BlockPainter.paint(canvas, rect, color, ghost: true);
      } else {
        BlockPainter.paint(
          canvas,
          rect,
          color,
          opacity: dimmed ? 0.25 : 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.shape != shape ||
      old.color != color ||
      old.cellPx != cellPx ||
      old.dimmed != dimmed ||
      old.ghost != ghost;
}
