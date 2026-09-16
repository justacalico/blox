import 'dart:math';

import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_catalog.dart';

/// Source of new hands for the tray. Lets tests script exact deals.
abstract interface class PieceDealer {
  /// Returns a fresh hand for [board]. May return fewer than three pieces.
  List<Piece> deal(Board board);
}

/// Deals pieces from [PieceCatalog].
///
/// Smaller pieces are dealt a little more often, which keeps runs alive
/// longer without feeling rigged. [deal] also prefers deals where at least
/// one piece fits the current board, so most deaths are the player's fault,
/// not the dealer's.
final class PieceGenerator implements PieceDealer {
  PieceGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const int _maxRetries = 24;

  static int _weightOf(int size) => switch (size) {
        <= 3 => 3,
        4 => 2,
        _ => 1,
      };

  Piece _draw() {
    final catalog = PieceCatalog.all;
    var total = 0;
    for (final s in catalog) {
      total += _weightOf(s.size);
    }
    var roll = _random.nextInt(total);
    for (final s in catalog) {
      roll -= _weightOf(s.size);
      if (roll < 0) {
        return Piece(s, _random.nextInt(kBlockColorCount));
      }
    }
    final last = catalog.last;
    return Piece(last, _random.nextInt(kBlockColorCount));
  }

  /// Returns a fresh hand of three pieces for [board].
  @override
  List<Piece> deal(Board board) {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final hand = [_draw(), _draw(), _draw()];
      if (hand.any((p) => board.hasAnyPlacement(p.shape))) {
        return hand;
      }
    }
    // Fallback: hand-pick anything that still fits, so the player is never
    // dealt three dead pieces while the board has room.
    final fitting = PieceCatalog.all.where(board.hasAnyPlacement).toList();
    if (fitting.isEmpty) {
      return [_draw(), _draw(), _draw()];
    }
    final rescue = Piece(
      fitting[_random.nextInt(fitting.length)],
      _random.nextInt(kBlockColorCount),
    );
    return [rescue, _draw(), _draw()];
  }
}
