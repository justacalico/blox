import 'dart:math';

import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_catalog.dart';
import 'package:blox/src/game/piece_generator.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:flutter_test/flutter_test.dart';

PieceShape dot() => PieceShape('dot', const [(row: 0, col: 0)]);

/// Always rolls the top of the range, so draws land on the last catalog shape.
final class _MaxRandom implements Random {
  @override
  int nextInt(int max) => max - 1;
  @override
  double nextDouble() => 0.9999;
  @override
  bool nextBool() => true;
}

/// Mirrors the generator's bone check: true when [shape] has a placement
/// that completes a line on [board].
bool canClear(Board board, PieceShape shape) {
  for (var r = 0; r <= board.size - shape.height; r++) {
    for (var c = 0; c <= board.size - shape.width; c++) {
      final p = board.previewClears(shape, r, c);
      if (p.rows.isNotEmpty || p.cols.isNotEmpty) return true;
    }
  }
  return false;
}

void main() {
  group('PieceGenerator', () {
    test('is deterministic for a given seed', () {
      final a = PieceGenerator(random: Random(42));
      final b = PieceGenerator(random: Random(42));
      final board = Board();
      final handA = a.deal(board);
      final handB = b.deal(board);
      for (var i = 0; i < 3; i++) {
        expect(handA[i].shape.id, handB[i].shape.id);
        expect(handA[i].colorIndex, handB[i].colorIndex);
      }
    });

    test('deals three pieces within the color range', () {
      final g = PieceGenerator(random: Random(7));
      final hand = g.deal(Board());
      expect(hand.length, 3);
      for (final p in hand) {
        expect(p.colorIndex, inInclusiveRange(0, kBlockColorCount - 1));
      }
    });

    test('rescue path guarantees a placeable piece when the board has room',
        () {
      // Board with a single empty cell: only the dot fits.
      final b = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (r != 0 || c != 0) b.place(dot(), r, c, 0);
        }
      }
      // Seeded or not, the fallback must include the dot.
      for (var seed = 0; seed < 40; seed++) {
        final hand = PieceGenerator(random: Random(seed)).deal(b);
        expect(
          hand.any((p) => b.hasAnyPlacement(p.shape)),
          isTrue,
          reason: 'seed $seed dealt a fully dead hand',
        );
      }
    });

    test('draws the last catalog shape when the roll lands at the tail', () {
      final hand = PieceGenerator(random: _MaxRandom()).deal(Board());
      expect(hand.first.shape.id, PieceCatalog.all.last.id);
    });

    test('exhausted retries fall back to a hand-picked fitting piece', () {
      // One free cell: only the dot fits, but _MaxRandom always draws the
      // largest catalog piece, so every retry hand is dead.
      final b = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (r != 0 || c != 0) b.place(dot(), r, c, 0);
        }
      }
      final hand = PieceGenerator(random: _MaxRandom()).deal(b);
      expect(hand.length, 3);
      expect(hand.first.shape.id, 'dot');
      expect(b.hasAnyPlacement(hand.first.shape), isTrue);
    });

    test('still deals three pieces on a full board', () {
      final b = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          b.place(dot(), r, c, 0);
        }
      }
      final hand = PieceGenerator(random: Random(1)).deal(b);
      expect(hand.length, 3);
    });

    test('assist 1 guarantees a piece that completes a line', () {
      // Row 3 misses a single cell; a handful of shapes can finish it.
      final b = Board();
      for (var c = 0; c < 7; c++) {
        b.place(dot(), 3, c, 0);
      }
      for (var seed = 0; seed < 40; seed++) {
        final hand = PieceGenerator(random: Random(seed)).deal(b, assist: 1);
        expect(
          hand.any((p) => canClear(b, p.shape)),
          isTrue,
          reason: 'seed $seed dealt a hand with no bone',
        );
      }
    });

    test('assist 1 injects a bone when the drawn hand lacks one', () {
      // _MaxRandom always draws the catalog's last shape, which cannot clear
      // here, so the generator must swap one slot for a bone.
      final b = Board();
      for (var c = 0; c < 7; c++) {
        b.place(dot(), 3, c, 0);
      }
      final hand = PieceGenerator(random: _MaxRandom()).deal(b, assist: 1);
      expect(hand.any((p) => canClear(b, p.shape)), isTrue);
    });

    test('assist 1 leaves the hand alone when it already has a bone', () {
      // Everything filled except a plus-shaped hole: the catalog's last
      // shape (plus) fits and clears both lines, so no injection happens.
      const hole = {
        (row: 3, col: 2),
        (row: 3, col: 3),
        (row: 3, col: 4),
        (row: 2, col: 3),
        (row: 4, col: 3),
      };
      final b = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (!hole.contains((row: r, col: c))) b.fill(r, c, 0);
        }
      }
      final lastId = PieceCatalog.all.last.id;
      final hand = PieceGenerator(random: _MaxRandom()).deal(b, assist: 1);
      expect(hand.every((p) => p.shape.id == lastId), isTrue);
      expect(canClear(b, hand.first.shape), isTrue);
    });

    test('assist 1 on a boneless board still deals a playable hand', () {
      // Checkerboard: no single placement completes a line.
      final b = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if ((r + c) % 2 == 0) b.fill(r, c, 0);
        }
      }
      final hand = PieceGenerator(random: Random(3)).deal(b, assist: 1);
      expect(hand.any((p) => b.hasAnyPlacement(p.shape)), isTrue);
    });

    test('assist 2 deals only pieces that fit', () {
      // Checkerboard holes are never adjacent, so only the dot fits.
      final b = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if ((r + c) % 2 == 0) b.fill(r, c, 0);
        }
      }
      for (var seed = 0; seed < 30; seed++) {
        final hand = PieceGenerator(random: Random(seed)).deal(b, assist: 2);
        for (final p in hand) {
          expect(
            b.hasAnyPlacement(p.shape),
            isTrue,
            reason: 'seed $seed dealt a dead piece',
          );
        }
      }
    });

    test('assist 2 on a full board still deals three pieces', () {
      final b = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          b.fill(r, c, 0);
        }
      }
      final hand = PieceGenerator(random: Random(1)).deal(b, assist: 2);
      expect(hand.length, 3);
    });
  });
}
