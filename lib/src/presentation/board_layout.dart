import 'dart:ui';

import 'package:blox/src/game/piece_shape.dart';
import 'package:blox/src/theme/blox_theme.dart';

/// Pixel math for the board. Given the painted square size, derives cell
/// rects, and converts between board pixels and cell coordinates.
final class BoardLayout {
  const BoardLayout({
    required this.boardPx,
    this.cells = BloxMetrics.boardSize,
    this.padding = BloxMetrics.boardPadding,
    this.gap = BloxMetrics.cellGap,
  });

  final double boardPx;
  final int cells;
  final double padding;
  final double gap;

  double get innerPx => boardPx - padding * 2;

  double get cellPx => (innerPx - (cells - 1) * gap) / cells;

  /// Top-left offset of a cell inside the board's paint area.
  Offset cellOrigin(int row, int col) => Offset(
        padding + col * (cellPx + gap),
        padding + row * (cellPx + gap),
      );

  Rect cellRect(int row, int col) =>
      cellOrigin(row, col) & Size.square(cellPx);

  /// Nearest anchor for a piece whose top-left sits at [pieceTopLeft] in
  /// board coordinates. May be out of range; the engine decides legality.
  CellPos anchorFor(Offset pieceTopLeft) {
    final col = ((pieceTopLeft.dx - padding) / (cellPx + gap)).round();
    final row = ((pieceTopLeft.dy - padding) / (cellPx + gap)).round();
    return (row: row, col: col);
  }
}
