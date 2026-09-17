import 'dart:math';

import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_catalog.dart';
import 'package:blox/src/game/piece_shape.dart';

/// Source of new hands for the tray. Lets tests script exact deals.
abstract interface class PieceDealer {
  /// Returns a fresh hand for [board]. May return fewer than three pieces.
  ///
  /// [assist] is the engine's read on how much the player is struggling:
  /// 0 deals normally, higher values nudge the hand toward pieces that get
  /// the player unstuck.
  List<Piece> deal(Board board, {int assist = 0});
}

/// Deals pieces from [PieceCatalog].
///
/// Smaller pieces are dealt a little more often, which keeps runs alive
/// longer without feeling rigged. [deal] also prefers deals where at least
/// one piece fits the current board, so most deaths are the player's fault,
/// not the dealer's.
///
/// With `assist` the dealer throws the player a bone: level 1 makes sure the
/// hand contains a piece that completes a line right now when the board has
/// one, and level 2 additionally draws every other slot from only the shapes
/// that still fit.
final class PieceGenerator implements PieceDealer {
  PieceGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const int _maxRetries = 24;

  static int _weightOf(int size) => switch (size) {
        <= 3 => 3,
        4 => 2,
        _ => 1,
      };

  Piece _draw() => _drawFrom(PieceCatalog.all);

  Piece _drawFrom(List<PieceShape> shapes) {
    var total = 0;
    for (final s in shapes) {
      total += _weightOf(s.size);
    }
    var roll = _random.nextInt(total);
    for (final s in shapes.sublist(0, shapes.length - 1)) {
      roll -= _weightOf(s.size);
      if (roll < 0) {
        return Piece(s, _random.nextInt(kBlockColorCount));
      }
    }
    return Piece(shapes.last, _random.nextInt(kBlockColorCount));
  }

  /// True when [shape] has at least one legal placement that finishes a row
  /// or column.
  bool _canClear(Board board, PieceShape shape) {
    for (var r = 0; r <= board.size - shape.height; r++) {
      for (var c = 0; c <= board.size - shape.width; c++) {
        final p = board.previewClears(shape, r, c);
        if (p.rows.isNotEmpty || p.cols.isNotEmpty) return true;
      }
    }
    return false;
  }

  /// Shapes that can complete a line on the current board.
  List<PieceShape> _bones(Board board) =>
      [for (final s in PieceCatalog.all) if (_canClear(board, s)) s];

  /// Returns a fresh hand of three pieces for [board].
  @override
  List<Piece> deal(Board board, {int assist = 0}) {
    final hand = _playableHand(board);
    if (assist <= 0) return hand;

    final bones = _bones(board);
    if (bones.isNotEmpty && !hand.any((p) => bones.contains(p.shape))) {
      hand[_random.nextInt(hand.length)] = Piece(
        bones[_random.nextInt(bones.length)],
        _random.nextInt(kBlockColorCount),
      );
    }
    if (assist >= 2) {
      final fitting = PieceCatalog.all.where(board.hasAnyPlacement).toList();
      if (fitting.isNotEmpty) {
        for (var i = 0; i < hand.length; i++) {
          if (bones.contains(hand[i].shape)) continue;
          hand[i] = _drawFrom(fitting);
        }
      }
    }
    return hand;
  }

  /// Three random pieces, retried until at least one fits. Falls back to a
  /// hand-picked fit so the player is never dealt three dead pieces while
  /// the board has room.
  List<Piece> _playableHand(Board board) {
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      final hand = [_draw(), _draw(), _draw()];
      if (hand.any((p) => board.hasAnyPlacement(p.shape))) {
        return hand;
      }
    }
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
