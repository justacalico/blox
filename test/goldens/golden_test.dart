import 'package:blox/src/presentation/widgets/board_view.dart';
import 'package:blox/src/presentation/widgets/piece_view.dart';
import 'package:blox/src/presentation/screens/game_screen.dart';
import 'package:blox/src/presentation/screens/menu_screen.dart';
import 'package:blox/src/settings.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadTestFonts);

  group('goldens', () {
    testWidgets('block palette', (tester) async {
      await tester.pumpWidget(
        testApp(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < BloxColors.blocks.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: PieceView(
                      piece: dot(i),
                      cellPx: 40,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Row),
        matchesGoldenFile('block_palette.png'),
      );
    });

    testWidgets('empty board', (tester) async {
      final engine = scriptedEngine([]);
      await tester.pumpWidget(
        testApp(
          Center(child: BoardView(board: engine.board, boardPx: 360)),
        ),
      );
      await expectLater(
        find.byType(BoardView),
        matchesGoldenFile('board_empty.png'),
      );
    });

    testWidgets('board mid-game', (tester) async {
      final engine = scriptedEngine([], preset: (b) {
        b.fill(0, 3, 3); // orange
        b.fill(0, 4, 4); // blue
        b.fill(1, 1, 1); // red
        b.fill(2, 1, 3);
        b.fill(4, 0, 0);
        b.fill(5, 0, 0);
        for (var c = 3; c <= 6; c++) {
          b.fill(5, c, 0);
          b.fill(6, c, 0);
        }
        b.fill(7, 0, 5);
        b.fill(7, 1, 4);
        b.fill(7, 2, 0);
        b.fill(7, 3, 6);
        b.fill(7, 7, 3);
      });
      await tester.pumpWidget(
        testApp(
          Center(child: BoardView(board: engine.board, boardPx: 360)),
        ),
      );
      await expectLater(
        find.byType(BoardView),
        matchesGoldenFile('board_midgame.png'),
      );
    });

    testWidgets('drag ghost with clear preview', (tester) async {
      final engine = scriptedEngine([], preset: (b) {
        for (var c = 0; c < 7; c++) {
          b.fill(6, c, 0);
        }
      });
      final piece = dot(0);
      await tester.pumpWidget(
        testApp(
          Center(
            child: BoardView(
              board: engine.board,
              boardPx: 360,
              drag: DragPreview(
                piece: piece,
                anchor: (row: 6, col: 7),
                clearingRows: const [6],
                clearingColumns: const [],
              ),
            ),
          ),
        ),
      );
      await expectLater(
        find.byType(BoardView),
        matchesGoldenFile('board_ghost.png'),
      );
    });

    testWidgets('game screen', (tester) async {
      tester.view.physicalSize = const Size(420, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final engine = scriptedEngine([
        [line3v(0), corner3(0), square2(4)],
      ], preset: (b) {
        b.fill(0, 3, 3);
        b.fill(0, 4, 4);
        b.fill(1, 1, 1);
        b.fill(2, 1, 3);
        for (var c = 3; c <= 6; c++) {
          b.fill(5, c, 0);
          b.fill(6, c, 0);
        }
        b.fill(7, 0, 5);
        b.fill(7, 1, 4);
        b.fill(7, 3, 6);
        b.fill(7, 7, 3);
      });
      await tester.pumpWidget(
        testApp(
          GameScreen(settings: SettingsStore.memory(best: 66625), engine: engine),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(GameScreen),
        matchesGoldenFile('game_screen.png'),
      );
    });

    testWidgets('menu screen', (tester) async {
      tester.view.physicalSize = const Size(420, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        testApp(MenuScreen(settings: SettingsStore.memory(best: 66625))),
      );
      await tester.pump(const Duration(milliseconds: 1200));
      await expectLater(
        find.byType(MenuScreen),
        matchesGoldenFile('menu.png'),
      );
    });
  });
}
