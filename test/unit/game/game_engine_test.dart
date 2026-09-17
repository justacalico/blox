import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/game_engine.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_generator.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:blox/src/game/score_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deals scripted hands so engine tests stay deterministic.
final class ScriptedDealer implements PieceDealer {
  ScriptedDealer(this.hands);

  final List<List<Piece>> hands;
  var _next = 0;

  @override
  List<Piece> deal(Board board) {
    if (_next >= hands.length) return const [];
    return hands[_next++];
  }
}

Piece dot([int color = 0]) =>
    Piece(PieceShape('dot', const [(row: 0, col: 0)]), color);

Piece line8v([int color = 0]) => Piece(
      PieceShape(
        'l8v',
        List.generate(8, (r) => (row: r, col: 0)),
      ),
      color,
    );

Piece line8h([int color = 0]) => Piece(
      PieceShape(
        'l8h',
        List.generate(8, (c) => (row: 0, col: c)),
      ),
      color,
    );

Piece dominoH([int color = 0]) => Piece(
      PieceShape('d2h', const [(row: 0, col: 0), (row: 0, col: 1)]),
      color,
    );

Piece square2([int color = 0]) => Piece(
      PieceShape('sq2', const [
        (row: 0, col: 0),
        (row: 0, col: 1),
        (row: 1, col: 0),
        (row: 1, col: 1),
      ]),
      color,
    );

void main() {
  test('default constructor deals a playable opening hand', () {
    final e = GameEngine();
    expect(e.tray.length, 3);
    expect(e.tray.any((p) => p != null), isTrue);
    expect(e.isGameOver, isFalse);
  });

  group('GameEngine', () {
    test('starts with a full tray and zero score', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), dot(), dot()],
        ]),
      );
      expect(e.tray.length, 3);
      expect(e.tray.every((p) => p != null), isTrue);
      expect(e.score, 0);
      expect(e.combo, 0);
      expect(e.isGameOver, isFalse);
    });

    test('place rejects illegal moves', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), dot(), dot()],
        ]),
      );
      expect(e.place(-1, 0, 0), isNull);
      expect(e.place(3, 0, 0), isNull);
      expect(e.place(0, 8, 0), isNull);
      expect(e.place(0, 0, 0), isNotNull);
      expect(e.place(0, 1, 1), isNull, reason: 'slot already used');
      expect(e.place(1, 0, 0), isNull, reason: 'cell occupied');
      expect(e.score, 1);
    });

    test('place scores cells and frees the tray slot', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dominoH(), dot(), dot()],
        ]),
      );
      final res = e.place(0, 4, 4)!;
      expect(res.placementPoints, 2);
      expect(res.clearPoints, 0);
      expect(res.placedCells.length, 2);
      expect(res.trayRefilled, isFalse);
      expect(e.tray[0], isNull);
      expect(e.score, 2);
    });

    test('completing a row clears it and scores the clear', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
        ]),
      );
      // Fill row 3 except column 7. Slots cycle 0,1,2 with auto refills.
      var slot = 0;
      for (var c = 0; c < 7; c++) {
        e.place(slot, 3, c);
        slot = (slot + 1) % 3;
      }
      final res = e.place(slot, 3, 7)!;
      expect(res.clearedRows, [3]);
      expect(res.clearedCells.length, 8);
      expect(res.clearPoints, 80);
      expect(res.combo, 1);
      expect(e.score, 1 + 80 + 7); // 7 placements of 1 + final dot + clear
      expect(e.board.isEmptyAt(3, 0), isTrue);
    });

    test('row and column clear together', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
        ]),
      );
      var slot = 0;
      int placeDot(int r, int c) {
        final res = e.place(slot, r, c)!;
        slot = (slot + 1) % 3;
        return res.totalPoints;
      }

      // Row 0 minus the corner, column 0 minus the corner.
      for (var c = 1; c < 8; c++) {
        placeDot(0, c);
      }
      for (var r = 1; r < 8; r++) {
        placeDot(r, 0);
      }
      // Corner completes both lines at once.
      final res = e.place(slot, 0, 0)!;
      expect(res.clearedRows, [0]);
      expect(res.clearedColumns, [0]);
      expect(res.clearedCells.length, 15);
      expect(res.clearPoints, 15 * 10 + 40);
      expect(e.board.isEmptyAt(0, 0), isTrue);
      expect(e.board.isEmptyAt(7, 0), isTrue);
      expect(e.board.isEmptyAt(0, 7), isTrue);
    });

    test('combo grows on consecutive clears and resets otherwise', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [line8h(), dot(), line8h()],
          [line8h(), dot(), dot()],
        ]),
      );
      final r1 = e.place(0, 0, 0)!;
      expect(r1.combo, 1);
      expect(r1.clearPoints, 80);
      final r2 = e.place(1, 7, 0)!; // no clear -> reset
      expect(r2.combo, 0);
      expect(r2.clearPoints, 0);
      final r3 = e.place(2, 1, 0)!;
      expect(r3.combo, 1);
      // Refilled hand: [line8h, dot, dot]
      final r4 = e.place(0, 2, 0)!;
      expect(r4.combo, 2, reason: 'back to back clears build the streak');
      expect(r4.clearPoints, 160);
    });

    test('tray refills when empty', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), dot(), dot()],
          [square2(), dot(), dominoH()],
        ]),
      );
      e.place(0, 0, 0);
      e.place(1, 0, 1);
      final res = e.place(2, 0, 2)!;
      expect(res.trayRefilled, isTrue);
      expect(e.tray[0]!.shape.id, 'sq2');
      expect(e.tray[1]!.shape.id, 'dot');
      expect(e.tray[2]!.shape.id, 'd2h');
    });

    test('game over when the dealer runs dry', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), dot(), dot()],
        ]),
      );
      e.place(0, 0, 0);
      e.place(1, 0, 1);
      final res = e.place(2, 0, 2)!;
      expect(res.trayRefilled, isTrue);
      expect(res.gameOver, isTrue, reason: 'empty hand means no moves');
      expect(e.isGameOver, isTrue);
      expect(e.place(0, 5, 5), isNull, reason: 'game is over');
    });

    test('game over is detected mid-run', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), square2(), square2()],
        ]),
      );
      // Checkerboard the board so no 2x2 fits but single cells do.
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if ((r + c) % 2 == 0) {
            e.board.fill(r, c, 1);
          }
        }
      }
      expect(e.trayPlaceability, [true, false, false]);
      final res = e.place(0, 1, 0)!;
      expect(res.gameOver, isTrue);
      expect(e.isGameOver, isTrue);
    });

    test('best score persists via the store and flags newBest', () {
      final store = MemoryScoreStore(100);
      final e = GameEngine(
        dealer: ScriptedDealer([
          [line8h(), dot(), dot()],
        ]),
        scoreStore: store,
      );
      expect(e.best, 100);
      final res = e.place(0, 0, 0)!;
      expect(res.newBest, isFalse); // 8 + 80 = 88 < 100
      expect(store.load(), 100);

      final e2 = GameEngine(
        dealer: ScriptedDealer([
          [line8h(), line8h(), line8h()],
          [line8h(), line8h(), line8h()],
          [line8h(), line8h(), line8h()],
        ]),
        scoreStore: store,
      );
      var sawBest = false;
      for (var r = 0; r < 8; r++) {
        final res2 = e2.place(r % 3, r, 0);
        if (res2 != null && res2.newBest) sawBest = true;
      }
      expect(sawBest, isTrue);
      expect(store.load(), e2.best);
      expect(e2.best, greaterThan(100));
    });

    test('newGame resets board, score and combo but keeps best', () {
      final store = MemoryScoreStore();
      final e = GameEngine(
        dealer: ScriptedDealer([
          [line8h(), dot(), dot()],
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
        ]),
        scoreStore: store,
      );
      e.place(0, 0, 0);
      e.place(1, 5, 5);
      expect(e.score, greaterThan(0));
      e.newGame();
      expect(e.score, 0);
      expect(e.combo, 0);
      expect(e.isGameOver, isFalse);
      expect(e.board.isEmpty, isTrue);
      expect(e.best, greaterThan(0));
      expect(e.tray.every((p) => p != null), isTrue);
    });

    test('placementsFor lists every legal anchor', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), dominoH(), square2()],
        ]),
      );
      expect(e.placementsFor(0).length, 64);
      expect(e.placementsFor(1).length, 8 * 7);
      expect(e.placementsFor(2).length, 7 * 7);
      e.place(0, 3, 3);
      expect(e.placementsFor(0), isEmpty, reason: 'slot consumed');
      expect(e.placementsFor(1).length, 8 * 7 - 2);
    });

    test('canPlaceAt mirrors board rules', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dominoH(), dot(), dot()],
        ]),
      );
      expect(e.canPlaceAt(0, 0, 6), isTrue);
      expect(e.canPlaceAt(0, 0, 7), isFalse);
      expect(e.canPlaceAt(1, 0, 0), isTrue);
      e.place(1, 0, 0);
      expect(e.canPlaceAt(2, 0, 0), isFalse);
    });

    test('notifies listeners on place and newGame', () {
      final e = GameEngine(
        dealer: ScriptedDealer([
          [dot(), dot(), dot()],
          [dot(), dot(), dot()],
        ]),
      );
      var notifications = 0;
      e.addListener(() => notifications++);
      e.place(0, 0, 0);
      e.newGame();
      expect(notifications, 2);
    });
  });
}
