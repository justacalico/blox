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
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 1, totalCleared: 0),
        80,
      );
    });

    test('multi-line clears earn a bonus', () {
      expect(
        Scoring.forClear(clearedCells: 16, lines: 2, combo: 1, totalCleared: 0),
        200,
      );
    });

    test('combo multiplies the whole clear', () {
      expect(
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 3, totalCleared: 0),
        240,
      );
    });

    test('clears pay more once more blocks have broken', () {
      expect(
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 1, totalCleared: 63),
        80,
        reason: 'ramp kicks in at one full board cleared',
      );
      expect(
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 1, totalCleared: 64),
        160,
      );
      expect(
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 1, totalCleared: 128),
        240,
      );
      expect(
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 2, totalCleared: 64),
        320,
        reason: 'ramp stacks with combo',
      );
      expect(
        Scoring.forClear(clearedCells: 8, lines: 1, combo: 1, totalCleared: -5),
        80,
        reason: 'negative history clamps to the base rate',
      );
    });

    test('degenerate inputs score zero', () {
      expect(
        Scoring.forClear(clearedCells: 0, lines: 0, combo: 1, totalCleared: 0),
        0,
      );
      expect(
        Scoring.forClear(clearedCells: 5, lines: 0, combo: 1, totalCleared: 0),
        0,
      );
      expect(
        Scoring.forClear(
          clearedCells: 0,
          lines: 2,
          combo: 1,
          totalCleared: 200,
        ),
        0,
      );
    });
  });
}
