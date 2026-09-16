/// Score formulas. Pure functions so tests can pin them exactly.
abstract final class Scoring {
  /// Points for simply placing a piece: one per cell.
  static int forPlacement(int cellsPlaced) => cellsPlaced;

  /// Points for a clear.
  ///
  /// [clearedCells] is the number of board cells emptied, [lines] the number
  /// of completed rows plus columns, and [combo] the current streak
  /// multiplier (1 on the first clear, 2 on the next placement that also
  /// clears, and so on).
  static int forClear({
    required int clearedCells,
    required int lines,
    required int combo,
  }) {
    if (lines <= 0 || clearedCells <= 0) return 0;
    const perCell = 10;
    const multiLineBonus = 40;
    final base = clearedCells * perCell + (lines - 1) * multiLineBonus;
    return base * combo;
  }
}
