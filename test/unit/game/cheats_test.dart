import 'dart:math';

import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/game_engine.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_generator.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:blox/src/game/score_store.dart';
import 'package:flutter_test/flutter_test.dart';

final class ScriptedDealer implements PieceDealer {
  ScriptedDealer(this.hands);

  final List<List<Piece>> hands;
  var _next = 0;

  @override
  List<Piece> deal(Board board, {int assist = 0}) =>
      _next >= hands.length ? const [] : hands[_next++];
}

Piece dot([int color = 0]) =>
    Piece(PieceShape('dot', const [(row: 0, col: 0)]), color);

Piece square2([int color = 0]) => Piece(
      PieceShape('sq2', const [
        (row: 0, col: 0),
        (row: 0, col: 1),
        (row: 1, col: 0),
        (row: 1, col: 1),
      ]),
      color,
    );

GameEngine scriptedEngine(
  List<List<Piece>> hands, {
  ScoreStore? store,
  void Function(Board)? preset,
}) {
  final e = GameEngine(dealer: ScriptedDealer(hands), scoreStore: store);
  preset?.call(e.board);
  return e;
}

void main() {
  group('cheats', () {
    test('grantScore adds points, updates best and persists it', () {
      final store = MemoryScoreStore(100);
      final e = scriptedEngine([
        [dot(), dot(), dot()],
      ], store: store);
      var notified = 0;
      e.addListener(() => notified++);

      e.grantScore(250);
      expect(e.score, 250);
      expect(e.best, 250);
      expect(store.load(), 250);
      expect(notified, 1);

      e.grantScore(-300);
      expect(e.score, -50);
      expect(e.best, 250, reason: 'best never drops');
      expect(notified, 2);
    });

    test('wipeBoard empties the board and clears game over', () {
      final e = scriptedEngine([
        [square2(), square2(), square2()],
        [square2(), square2(), square2()],
      ], preset: (b) {
        // Checkerboard: no 2x2 fits anywhere.
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            if ((r + c) % 2 == 0) b.fill(r, c, 1);
          }
        }
      });
      e.redealTray();
      expect(e.isGameOver, isTrue);
      e.wipeBoard();
      expect(e.board.isEmpty, isTrue);
      expect(e.isGameOver, isFalse);
    });

    test('redealTray swaps the hand for the next dealt one', () {
      final e = scriptedEngine([
        [dot(1), dot(1), dot(1)],
        [square2(2), dot(3), dot(4)],
      ]);
      e.place(0, 0, 0);
      e.redealTray();
      expect(e.tray[0]!.shape.id, 'sq2');
      expect(e.tray[1]!.shape.id, 'dot');
      expect(e.tray[2]!.shape.id, 'dot');
    });

    test('dealFittingTray deals only pieces that fit', () {
      final e = scriptedEngine([
        [square2(), square2(), square2()],
      ], preset: (b) {
        // Checkerboard again: only the dot fits.
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            if ((r + c) % 2 == 0) b.fill(r, c, 1);
          }
        }
      });
      e.dealFittingTray(random: Random(7));
      for (final p in e.tray) {
        expect(p!.shape.id, 'dot');
      }
      expect(e.isGameOver, isFalse);
    });

    test('dealFittingTray works without an injected random', () {
      final e = scriptedEngine([
        [square2(), square2(), square2()],
      ]);
      e.dealFittingTray();
      expect(e.tray.every((p) => p != null), isTrue);
    });

    test('dealFittingTray leaves the tray empty when nothing fits', () {
      final e = scriptedEngine([
        [dot(), dot(), dot()],
      ], preset: (b) {
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            b.fill(r, c, 0);
          }
        }
      });
      e.dealFittingTray(random: Random(1));
      expect(e.tray.every((p) => p == null), isTrue);
      expect(e.isGameOver, isTrue);
    });

    test('revive turns dead slots into dots and clears game over', () {
      final e = scriptedEngine([
        [square2(1), square2(2), square2(3)],
        [square2(1), square2(2), square2(3)],
      ], preset: (b) {
        // Checkerboard: nothing but single cells fit.
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            if ((r + c) % 2 == 0) b.fill(r, c, 1);
          }
        }
      });
      e.redealTray();
      expect(e.isGameOver, isTrue);
      e.revive();
      expect(e.isGameOver, isFalse);
      expect(e.tray.every((p) => p!.shape.id == 'dot'), isTrue);
      expect(e.place(0, 1, 0), isNotNull);
    });

    test('revive keeps slots that still have a move', () {
      final e = scriptedEngine([
        [dot(5), square2(), square2()],
      ], preset: (b) {
        // Only (0,0) and its neighbours stay empty: the dot fits, the
        // squares do not.
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            if (r > 1 || c > 1) b.fill(r, c, 1);
          }
        }
        b.fill(0, 1, 1);
        b.fill(1, 0, 1);
        b.fill(1, 1, 1);
      });
      e.revive();
      expect(e.tray[0]!.colorIndex, 5, reason: 'live dot stays put');
      expect(e.tray[1]!.shape.id, 'dot');
      expect(e.tray[2]!.shape.id, 'dot');
    });

    test('revive cannot save a completely full board', () {
      final e = scriptedEngine([
        [dot(), dot(), dot()],
      ], preset: (b) {
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            b.fill(r, c, 0);
          }
        }
      });
      e.revive();
      expect(e.isGameOver, isTrue);
    });

    test('neverGameOver keeps the run alive and toggles off again', () {
      final e = scriptedEngine([
        [square2(), square2(), square2()],
        [square2(), square2(), square2()],
      ]);
      var notified = 0;
      e.addListener(() => notified++);
      e.neverGameOver = true;
      expect(notified, 1);

      // Checkerboard: no 2x2 fits. The redeal would end the run without
      // god mode.
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if ((r + c) % 2 == 0) e.board.fill(r, c, 1);
        }
      }
      e.redealTray();
      expect(e.isGameOver, isFalse);
      expect(notified, 2);

      e.neverGameOver = true;
      expect(notified, 2, reason: 'same value is a no-op');

      e.neverGameOver = false;
      expect(e.isGameOver, isTrue);
      expect(notified, 3);
    });

    test('primeClear leaves exactly one hole in the fullest row', () {
      final e = scriptedEngine([
        [dot(), dot(), dot()],
      ], preset: (b) {
        // Row 3 has two holes, every other row has more.
        b.fill(3, 0, 2);
        b.fill(3, 1, 2);
        b.fill(3, 2, 2);
        b.fill(3, 3, 2);
        b.fill(3, 4, 2);
        b.fill(3, 5, 2);
      });
      e.primeClear();
      var empty = 0;
      var hole = -1;
      for (var c = 0; c < 8; c++) {
        if (e.board.isEmptyAt(3, c)) {
          empty++;
          hole = c;
        }
      }
      expect(empty, 1);
      expect(hole, 6, reason: 'first empty cell is the hole left behind');
      for (var r = 0; r < 8; r++) {
        if (r == 3) continue;
        for (var c = 0; c < 8; c++) {
          expect(e.board.isEmptyAt(r, c), isTrue);
        }
      }
    });

    test('primeClear on an empty board primes row zero', () {
      final e = scriptedEngine([
        [dot(), dot(), dot()],
      ]);
      e.primeClear();
      for (var c = 1; c < 8; c++) {
        expect(e.board.isEmptyAt(0, c), isFalse);
      }
      expect(e.board.isEmptyAt(0, 0), isTrue);
    });

    test('primeClear does nothing on a full board', () {
      final e = scriptedEngine([
        [dot(), dot(), dot()],
      ], preset: (b) {
        for (var r = 0; r < 8; r++) {
          for (var c = 0; c < 8; c++) {
            b.fill(r, c, 0);
          }
        }
      });
      var notified = 0;
      e.addListener(() => notified++);
      e.primeClear();
      expect(notified, 0);
      expect(e.board.filledCount, 64);
    });
  });
}
