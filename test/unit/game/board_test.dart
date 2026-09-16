import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:flutter_test/flutter_test.dart';

PieceShape dot() => PieceShape('dot', const [(row: 0, col: 0)]);

PieceShape dominoH() =>
    PieceShape('d2h', const [(row: 0, col: 0), (row: 0, col: 1)]);

PieceShape square2() => PieceShape(
      'sq2',
      const [
        (row: 0, col: 0),
        (row: 0, col: 1),
        (row: 1, col: 0),
        (row: 1, col: 1),
      ],
    );

void main() {
  group('Board', () {
    test('starts empty', () {
      final b = Board();
      expect(b.size, 8);
      expect(b.filledCount, 0);
      expect(b.isEmpty, isTrue);
      expect(b.colorAt(0, 0), isNull);
    });

    test('canPlace accepts a fitting piece', () {
      final b = Board();
      expect(b.canPlace(square2(), 0, 0), isTrue);
      expect(b.canPlace(square2(), 6, 6), isTrue);
    });

    test('canPlace rejects out of bounds', () {
      final b = Board();
      expect(b.canPlace(square2(), 7, 0), isFalse);
      expect(b.canPlace(square2(), 0, 7), isFalse);
      expect(b.canPlace(square2(), -1, 0), isFalse);
      expect(b.canPlace(square2(), 0, -1), isFalse);
    });

    test('canPlace rejects occupied cells', () {
      final b = Board()..place(dot(), 3, 3, 0);
      expect(b.canPlace(square2(), 2, 2), isFalse);
      expect(b.canPlace(square2(), 3, 3), isFalse);
      expect(b.canPlace(square2(), 4, 4), isTrue);
    });

    test('place writes color index and throws on illegal move', () {
      final b = Board();
      b.place(dominoH(), 0, 0, 4);
      expect(b.colorAt(0, 0), 4);
      expect(b.colorAt(0, 1), 4);
      expect(b.filledCount, 2);
      expect(() => b.place(dominoH(), 0, 0, 1), throwsArgumentError);
      expect(() => b.place(dominoH(), 0, 7, 1), throwsArgumentError);
    });

    test('fullRows and fullColumns detect completed lines', () {
      final b = Board();
      expect(b.fullRows(), isEmpty);
      expect(b.fullColumns(), isEmpty);

      for (var c = 0; c < 8; c++) {
        b.fill(2, c, 1);
      }
      for (var r = 0; r < 8; r++) {
        b.fill(r, 5, 2);
      }
      expect(b.fullRows(), [2]);
      expect(b.fullColumns(), [5]);
    });

    test('clear empties the union of rows and columns', () {
      final b = Board();
      for (var c = 0; c < 8; c++) {
        b.fill(0, c, 1);
      }
      for (var r = 0; r < 8; r++) {
        b.fill(r, 0, 1);
      }
      b.place(dot(), 4, 4, 3);

      final cleared = b.clear([0], [0]);
      // Row 0 has 8 cells, column 0 contributes 7 more (corner counted once).
      expect(cleared.length, 15);
      expect(b.isEmptyAt(0, 0), isTrue);
      expect(b.isEmptyAt(0, 7), isTrue);
      expect(b.isEmptyAt(7, 0), isTrue);
      expect(b.colorAt(4, 4), 3);
    });

    test('clear skips already empty cells', () {
      final b = Board();
      for (var c = 0; c < 8; c++) {
        if (c != 3) b.fill(1, c, 0);
      }
      for (var r = 0; r < 8; r++) {
        b.fill(r, 3, 0);
      }
      final cleared = b.clear([1], [3]);
      expect(cleared.length, 15);
    });

    test('hasAnyPlacement reflects board space', () {
      final b = Board();
      expect(b.hasAnyPlacement(square2()), isTrue);
      final full = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          full.fill(r, c, 0);
        }
      }
      expect(full.hasAnyPlacement(dot()), isFalse);
    });

    test('hasAnyPlacement finds the only remaining hole', () {
      final b = Board();
      for (var r = 0; r < 8; r++) {
        for (var c = 0; c < 8; c++) {
          if (r != 7 || c != 7) b.fill(r, c, 0);
        }
      }
      expect(b.hasAnyPlacement(dot()), isTrue);
      expect(b.hasAnyPlacement(dominoH()), isFalse);
    });

    test('copy is independent', () {
      final b = Board()..place(dot(), 1, 1, 5);
      final c = b.copy();
      c.place(dot(), 2, 2, 6);
      expect(b.isEmptyAt(2, 2), isTrue);
      expect(c.colorAt(1, 1), 5);
    });
  });
}
