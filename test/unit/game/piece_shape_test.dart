import 'package:blox/src/game/piece_catalog.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieceShape', () {
    test('computes tight bounding box', () {
      final s = PieceShape('x', const [(row: 0, col: 0), (row: 2, col: 1)]);
      expect(s.width, 2);
      expect(s.height, 3);
      expect(s.size, 2);
    });
  });

  group('PieceCatalog', () {
    test('has a varied roster', () {
      expect(PieceCatalog.all.length, greaterThanOrEqualTo(30));
    });

    test('ids are unique', () {
      final ids = PieceCatalog.all.map((s) => s.id).toSet();
      expect(ids.length, PieceCatalog.all.length);
    });

    test('cells stay inside their bounding box with no duplicates', () {
      for (final s in PieceCatalog.all) {
        final seen = <String>{};
        var maxRow = -1;
        var maxCol = -1;
        for (final c in s.cells) {
          expect(c.row, greaterThanOrEqualTo(0), reason: s.id);
          expect(c.col, greaterThanOrEqualTo(0), reason: s.id);
          maxRow = c.row > maxRow ? c.row : maxRow;
          maxCol = c.col > maxCol ? c.col : maxCol;
          expect(seen.add('${c.row},${c.col}'), isTrue, reason: s.id);
        }
        expect(s.height, maxRow + 1, reason: s.id);
        expect(s.width, maxCol + 1, reason: s.id);
      }
    });

    test('every shape fits on an empty board', () {
      for (final s in PieceCatalog.all) {
        expect(s.width, lessThanOrEqualTo(8), reason: s.id);
        expect(s.height, lessThanOrEqualTo(8), reason: s.id);
      }
    });
  });
}
