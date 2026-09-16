/// A board position in row/column space.
typedef CellPos = ({int row, int col});

/// A polyomino shape expressed as normalized cell offsets.
///
/// Offsets are anchored so the minimum row and column are both zero, which
/// makes [width] and [height] the tight bounding box of the piece.
final class PieceShape {
  const PieceShape._(this.id, this.cells, this.width, this.height);

  factory PieceShape(String id, List<CellPos> cells) {
    var maxRow = 0;
    var maxCol = 0;
    for (final c in cells) {
      if (c.row > maxRow) maxRow = c.row;
      if (c.col > maxCol) maxCol = c.col;
    }
    return PieceShape._(id, List.unmodifiable(cells), maxCol + 1, maxRow + 1);
  }

  /// Stable identifier, used by tests and debugging.
  final String id;

  /// Occupied offsets relative to the piece's top-left corner.
  final List<CellPos> cells;

  final int width;
  final int height;

  int get size => cells.length;
}
