import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:blox/src/presentation/board_layout.dart';
import 'package:blox/src/presentation/painters/block_painter.dart';
import 'package:blox/src/presentation/widgets/piece_view.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';

/// A live drag hovering over the board: which piece, where it would land,
/// and the lines that drop would complete.
final class DragPreview {
  const DragPreview({
    required this.piece,
    required this.anchor,
    required this.clearingRows,
    required this.clearingColumns,
  });

  final Piece piece;
  final CellPos anchor;
  final List<int> clearingRows;
  final List<int> clearingColumns;

  bool get wouldClear => clearingRows.isNotEmpty || clearingColumns.isNotEmpty;
}

/// Cells mid-clear animation, with the colors they had before the wipe.
final class ClearAnimation {
  const ClearAnimation({required this.cells, required this.progress});

  /// Cell position -> the color index it had before clearing.
  final Map<CellPos, int> cells;

  /// 0 -> flash to white, 1 -> fully shrunk away.
  final double progress;
}

/// The 8x8 board: well, cells, placed blocks, drag ghost and clear effects.
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.boardPx,
    this.drag,
    this.clearing,
    this.popCells = const {},
    this.popProgress = 1,
  });

  final Board board;
  final double boardPx;
  final DragPreview? drag;
  final ClearAnimation? clearing;
  final Set<CellPos> popCells;
  final double popProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: boardPx,
      child: CustomPaint(
        painter: _BoardPainter(
          board: board,
          layout: BoardLayout(boardPx: boardPx, cells: board.size),
          drag: drag,
          clearing: clearing,
          popCells: popCells,
          popProgress: popProgress,
        ),
      ),
    );
  }
}

final class _BoardPainter extends CustomPainter {
  const _BoardPainter({
    required this.board,
    required this.layout,
    required this.drag,
    required this.clearing,
    required this.popCells,
    required this.popProgress,
  });

  final Board board;
  final BoardLayout layout;
  final DragPreview? drag;
  final ClearAnimation? clearing;
  final Set<CellPos> popCells;
  final double popProgress;

  @override
  void paint(Canvas canvas, Size size) {
    _paintWell(canvas, size);
    _paintCells(canvas);
    _paintPlaced(canvas);
    _paintGhost(canvas);
    _paintClearing(canvas);
  }

  void _paintWell(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(BloxMetrics.boardRadius),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [BloxColors.boardWell, BloxColors.boardEdge],
        ).createShader(rect),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = BloxColors.ink.withValues(alpha: 0.05),
    );
  }

  void _paintCells(Canvas canvas) {
    final paint = Paint();
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        final rect = layout.cellRect(r, c).deflate(layout.gap / 2);
        paint.color = (r + c).isEven ? BloxColors.cell : BloxColors.cellAlt;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            const Radius.circular(BloxMetrics.cellRadius),
          ),
          paint,
        );
      }
    }
  }

  void _paintPlaced(Canvas canvas) {
    for (var r = 0; r < board.size; r++) {
      for (var c = 0; c < board.size; c++) {
        final colorIndex = board.colorAt(r, c);
        if (colorIndex == null) continue;
        var rect = layout.cellRect(r, c).deflate(layout.gap / 2);
        final pos = (row: r, col: c);
        if (popCells.contains(pos)) {
          // Newly placed blocks overshoot once, like a satisfying snap-in.
          final s = 1 + (1 - popProgress) * 0.18;
          rect = _scaled(rect, s);
        }
        BlockPainter.paint(
          canvas,
          rect,
          PieceView.colorOf(colorIndex),
        );
      }
    }
  }

  void _paintGhost(Canvas canvas) {
    final d = drag;
    if (d == null) return;
    final color = PieceView.colorOf(d.piece.colorIndex);

    // Lines this drop would finish get a warm-up glow.
    if (d.wouldClear) {
      for (final r in d.clearingRows) {
        for (var c = 0; c < board.size; c++) {
          BlockPainter.paintGlow(
            canvas,
            layout.cellRect(r, c).deflate(layout.gap / 2),
            BloxColors.glow,
          );
        }
      }
      for (final c in d.clearingColumns) {
        for (var r = 0; r < board.size; r++) {
          BlockPainter.paintGlow(
            canvas,
            layout.cellRect(r, c).deflate(layout.gap / 2),
            BloxColors.glow,
          );
        }
      }
    }

    for (final cell in d.piece.shape.cells) {
      final r = d.anchor.row + cell.row;
      final c = d.anchor.col + cell.col;
      if (r < 0 || c < 0 || r >= board.size || c >= board.size) continue;
      final rect = layout.cellRect(r, c).deflate(layout.gap / 2);
      BlockPainter.paint(canvas, rect, color, ghost: true);
    }
  }

  void _paintClearing(Canvas canvas) {
    final anim = clearing;
    if (anim == null) return;
    for (final entry in anim.cells.entries) {
      final pos = entry.key;
      final color = PieceView.colorOf(entry.value);
      var rect = layout.cellRect(pos.row, pos.col).deflate(layout.gap / 2);

      // Stagger: cells nearer the middle of the clear go first.
      final center = _clearCenter(anim.cells.keys);
      final dist = (pos.row - center.row).abs() + (pos.col - center.col).abs();
      final t = (anim.progress * 1.6 - dist * 0.08).clamp(0.0, 1.0);

      const flashWindow = 0.35;
      if (t < flashWindow) {
        BlockPainter.paint(canvas, rect, color, flash: t / flashWindow);
      } else {
        final out = (t - flashWindow) / (1 - flashWindow);
        rect = _scaled(rect, 1 - out * 0.9);
        BlockPainter.paint(canvas, rect, color, opacity: 1 - out);
      }
    }
  }

  CellPos _clearCenter(Iterable<CellPos> cells) {
    var rs = 0, cs = 0, n = 0;
    for (final c in cells) {
      rs += c.row;
      cs += c.col;
      n++;
    }
    if (n == 0) {
      // coverage:ignore-start
      return (row: board.size ~/ 2, col: board.size ~/ 2);
      // coverage:ignore-end
    }
    return (row: rs ~/ n, col: cs ~/ n);
  }

  Rect _scaled(Rect rect, double s) {
    final center = rect.center;
    final w = rect.width * s;
    final h = rect.height * s;
    return Rect.fromCenter(center: center, width: w, height: h);
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.board != board ||
      old.drag != drag ||
      old.clearing != clearing ||
      old.popCells != popCells ||
      old.popProgress != popProgress;
}
