import 'package:blox/src/game/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scoring', () {
    test('placement scores one point per cell', () {
      expect(Scoring.forPlacement(1), 1);
      expect(Scoring.forPlacement(5), 5);
    });

    test('single line clear scores per cell', () {
      expect(
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 1),
        80,
      );
    });

    test('multi-line clears earn a bonus', () {
      expect(
        Scoring.forClear(clearedCells: 16, lines: 2, combo: 1),
        200,
      );
    });

    test('combo multiplies the whole clear', () {
      expect(
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 3),
        240,
      );
    });

    test('degenerate inputs score zero', () {
      expect(Scoring.forClear(clearedCells: 0, lines: 0, combo: 1), 0);
      expect(Scoring.forClear(clearedCells: 5, lines: 0, combo: 1), 0);
      expect(Scoring.forClear(clearedCells: 0, lines: 2, combo: 1), 0);
    });
  });
}
