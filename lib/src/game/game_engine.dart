import 'dart:math';

import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_generator.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:blox/src/game/score_store.dart';
import 'package:blox/src/game/scoring.dart';
import 'package:flutter/foundation.dart';

/// Outcome of one call to [GameEngine.place].
final class PlacementResult {
  const PlacementResult({
    required this.placedCells,
    required this.clearedRows,
    required this.clearedColumns,
    required this.clearedCells,
    required this.placementPoints,
    required this.clearPoints,
    required this.combo,
    required this.trayRefilled,
    required this.gameOver,
    required this.newBest,
  });

  /// Board cells the piece occupied.
  final List<CellPos> placedCells;
  final List<int> clearedRows;
  final List<int> clearedColumns;

  /// Board cells emptied by the clear (union of rows and columns).
  final List<CellPos> clearedCells;
  final int placementPoints;
  final int clearPoints;

  /// Streak multiplier that applied to this move's clear points.
  final int combo;
  final bool trayRefilled;
  final bool gameOver;
  final bool newBest;

  int get totalPoints => placementPoints + clearPoints;

  bool get clearedAnything => clearedCells.isNotEmpty;
}

/// The rules machine. Owns the board, the tray, the score and the combo
/// streak. Pure Dart plus [ChangeNotifier]; the UI layer only reads state
/// and calls [place].
final class GameEngine extends ChangeNotifier {
  GameEngine({
    PieceDealer? dealer,
    ScoreStore? scoreStore,
    int boardSize = Board.defaultSize,
  })  : _dealer = dealer ?? PieceGenerator(random: Random()),
        _scoreStore = scoreStore ?? MemoryScoreStore(),
        board = Board(size: boardSize) {
    best = _scoreStore.load();
    _refillTray();
    _updateGameOver();
  }

  /// Deterministic engine for tests and replays.
  GameEngine.seeded(
    int seed, {
    ScoreStore? scoreStore,
    int boardSize = Board.defaultSize,
  }) : this(
          dealer: PieceGenerator(random: Random(seed)),
          scoreStore: scoreStore,
          boardSize: boardSize,
        );

  static const int traySize = 3;

  final PieceDealer _dealer;
  final ScoreStore _scoreStore;

  final Board board;

  final List<Piece?> _tray = List.filled(traySize, null);
  int score = 0;
  int best = 0;
  int combo = 0;
  bool isGameOver = false;

  /// The current hand. Empty slots are null.
  List<Piece?> get tray => List.unmodifiable(_tray);

  /// Which tray slots can still be played somewhere on the board.
  /// Dead slots are drawn dimmed in the UI.
  List<bool> get trayPlaceability => [
        for (final p in _tray)
          p != null && board.hasAnyPlacement(p.shape),
      ];

  /// Whether the piece in [trayIndex] fits at [row]/[col].
  bool canPlaceAt(int trayIndex, int row, int col) {
    final piece = _tray[trayIndex];
    return piece != null && board.canPlace(piece.shape, row, col);
  }

  /// All legal placements for the piece in [trayIndex], top-left anchored.
  List<CellPos> placementsFor(int trayIndex) {
    final piece = _tray[trayIndex];
    if (piece == null) return const [];
    final out = <CellPos>[];
    for (var r = 0; r <= board.size - piece.shape.height; r++) {
      for (var c = 0; c <= board.size - piece.shape.width; c++) {
        if (board.canPlace(piece.shape, r, c)) out.add((row: r, col: c));
      }
    }
    return out;
  }

  /// Attempts to place tray piece [trayIndex] anchored at [row]/[col].
  ///
  /// Returns null when the move is illegal. Otherwise applies the move,
  /// resolves clears, updates score/combo/best, refills the tray when empty,
  /// re-evaluates game over, and returns the full result for the UI to
  /// animate.
  PlacementResult? place(int trayIndex, int row, int col) {
    if (isGameOver || trayIndex < 0 || trayIndex >= traySize) return null;
    final piece = _tray[trayIndex];
    if (piece == null || !board.canPlace(piece.shape, row, col)) return null;

    board.place(piece.shape, row, col, piece.colorIndex);
    _tray[trayIndex] = null;

    final placedCells = [
      for (final c in piece.shape.cells) (row: row + c.row, col: col + c.col),
    ];
    final placementPoints = Scoring.forPlacement(placedCells.length);

    final rows = board.fullRows();
    final cols = board.fullColumns();
    List<CellPos> clearedCells = const [];
    var clearPoints = 0;
    if (rows.isNotEmpty || cols.isNotEmpty) {
      combo += 1;
      clearedCells = board.clear(rows, cols);
      clearPoints = Scoring.forClear(
        clearedCells: clearedCells.length,
        lines: rows.length + cols.length,
        combo: combo,
      );
    } else {
      combo = 0;
    }

    score += placementPoints + clearPoints;
    var newBest = false;
    if (score > best) {
      best = score;
      newBest = true;
      _scoreStore.save(best);
    }

    var refilled = false;
    if (_tray.every((p) => p == null)) {
      _refillTray();
      refilled = true;
    }

    _updateGameOver();
    notifyListeners();

    return PlacementResult(
      placedCells: placedCells,
      clearedRows: rows,
      clearedColumns: cols,
      clearedCells: clearedCells,
      placementPoints: placementPoints,
      clearPoints: clearPoints,
      combo: combo,
      trayRefilled: refilled,
      gameOver: isGameOver,
      newBest: newBest,
    );
  }

  /// Starts a fresh run, keeping the recorded best.
  void newGame() {
    _clearBoard();
    score = 0;
    combo = 0;
    isGameOver = false;
    _refillTray();
    _updateGameOver();
    notifyListeners();
  }

  void _clearBoard() {
    board.clear(
      List.generate(board.size, (i) => i),
      List.generate(board.size, (i) => i),
    );
  }

  void _refillTray() {
    final hand = _dealer.deal(board);
    for (var i = 0; i < traySize; i++) {
      _tray[i] = i < hand.length ? hand[i] : null;
    }
  }

  void _updateGameOver() {
    isGameOver = !_tray.any(
      (p) => p != null && board.hasAnyPlacement(p.shape),
    );
  }
}
