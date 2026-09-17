import 'package:blox/src/game/piece_shape.dart';

/// The 8x8 playfield. Cells hold a block color index or are empty.
final class Board {
  Board({int size = defaultSize})
      : size = size,
        _cells = List<int?>.filled(size * size, null);

  Board._(this.size, this._cells);

  static const int defaultSize = 8;

  final int size;
  final List<int?> _cells;

  int? colorAt(int row, int col) => _cells[row * size + col];

  bool isEmptyAt(int row, int col) => colorAt(row, col) == null;

  int get filledCount => _cells.where((c) => c != null).length;

  bool get isEmpty => filledCount == 0;

  /// True when every cell of [shape] lands inside the grid on empty cells.
  bool canPlace(PieceShape shape, int row, int col) {
    for (final c in shape.cells) {
      final r = row + c.row;
      final cc = col + c.col;
      if (r < 0 || cc < 0 || r >= size || cc >= size) return false;
      if (!isEmptyAt(r, cc)) return false;
    }
    return true;
  }

  /// Writes [shape] at [row]/[col] with [colorIndex]. Caller must have
  /// checked [canPlace] first; out-of-grid or occupied writes throw.
  void place(PieceShape shape, int row, int col, int colorIndex) {
    if (!canPlace(shape, row, col)) {
      throw ArgumentError('Cannot place ${shape.id} at ($row, $col)');
    }
    for (final c in shape.cells) {
      _cells[(row + c.row) * size + (col + c.col)] = colorIndex;
    }
  }

  /// Writes [colorIndex] into a cell without placement rules. Used to set up
  /// preset boards and by tests.
  void fill(int row, int col, int colorIndex) {
    _cells[row * size + col] = colorIndex;
  }

  /// Indexes of every fully occupied row.
  List<int> fullRows() => [
        for (var r = 0; r < size; r++)
          if (_isRowFull(r)) r,
      ];

  /// Indexes of every fully occupied column.
  List<int> fullColumns() => [
        for (var c = 0; c < size; c++)
          if (_isColumnFull(c)) c,
      ];

  bool _isRowFull(int row) {
    for (var c = 0; c < size; c++) {
      if (isEmptyAt(row, c)) return false;
    }
    return true;
  }

  bool _isColumnFull(int col) {
    for (var r = 0; r < size; r++) {
      if (isEmptyAt(r, col)) return false;
    }
    return true;
  }

  /// Empties the given rows and columns. Returns the cleared positions.
  List<CellPos> clear(List<int> rows, List<int> cols) {
    final cleared = <CellPos>[];
    for (final r in rows) {
      for (var c = 0; c < size; c++) {
        if (_cells[r * size + c] != null) {
          cleared.add((row: r, col: c));
          _cells[r * size + c] = null;
        }
      }
    }
    for (final c in cols) {
      for (var r = 0; r < size; r++) {
        if (_cells[r * size + c] != null) {
          cleared.add((row: r, col: c));
          _cells[r * size + c] = null;
        }
      }
    }
    return cleared;
  }

  /// Which rows and columns a legal placement would complete, without
  /// mutating the board. Returns empty lists when the placement is illegal.
  ({List<int> rows, List<int> cols}) previewClears(
    PieceShape shape,
    int row,
    int col,
  ) {
    if (!canPlace(shape, row, col)) {
      return (rows: const [], cols: const []);
    }
    final copy = this.copy()..place(shape, row, col, 0);
    return (rows: copy.fullRows(), cols: copy.fullColumns());
  }

  /// True when [shape] can be placed anywhere on the board.
  bool hasAnyPlacement(PieceShape shape) {
    for (var r = 0; r <= size - shape.height; r++) {
      for (var c = 0; c <= size - shape.width; c++) {
        if (canPlace(shape, r, c)) return true;
      }
    }
    return false;
  }

  Board copy() => Board._(size, List.of(_cells));
}
