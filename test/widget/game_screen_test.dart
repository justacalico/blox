import 'package:blox/src/game/game_engine.dart';
import 'package:blox/src/game/score_store.dart';
import 'package:blox/src/presentation/board_layout.dart';
import 'package:blox/src/presentation/screens/game_screen.dart';
import 'package:blox/src/presentation/widgets/board_view.dart';
import 'package:blox/src/presentation/widgets/tray_view.dart';
import 'package:blox/src/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Center of cell (row, col) in global coordinates.
Offset cellCenter(WidgetTester tester, int row, int col) {
  final boardRect = tester.getRect(find.byType(BoardView));
  final layout = BoardLayout(boardPx: boardRect.width);
  return boardRect.topLeft + layout.cellRect(row, col).center;
}

/// The position the pointer must reach for a 1x1-ish piece anchored at
/// (row, col): the piece floats above the finger by the lift distance.
Offset pointerFor(WidgetTester tester, int row, int col) {
  final boardRect = tester.getRect(find.byType(BoardView));
  final layout = BoardLayout(boardPx: boardRect.width);
  final lift = layout.cellPx * 1.7 + 12;
  final pieceHalf = layout.cellPx / 2;
  final target = boardRect.topLeft +
      layout.cellOrigin(row, col) +
      Offset(pieceHalf, pieceHalf);
  return target + Offset(0, lift);
}

Future<GameScreenState> pumpGame(
  WidgetTester tester,
  GameEngine engine, {
  SettingsStore? settings,
}) async {
  await tester.pumpWidget(
    testApp(GameScreen(settings: settings ?? SettingsStore.memory(), engine: engine)),
  );
  await tester.pumpAndSettle();
  return tester.state<GameScreenState>(find.byType(GameScreen));
}

void main() {
  setUpAll(loadTestFonts);

  testWidgets('renders hud, board and tray', (tester) async {
    await pumpGame(
      tester,
      scriptedEngine([
        [dot(), square2(1), corner3(2)],
      ]),
    );
    expect(find.byType(BoardView), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('dragging a piece onto the board places it', (tester) async {
    final engine = scriptedEngine([
      [dot(3), dot(1), dot(2)],
      [dot(), dot(), dot()],
    ]);
    await pumpGame(tester, engine);

    final trayY = tester.getCenter(find.descendant(of: find.byType(TrayView), matching: find.byType(Listener)).first);
    final gesture = await tester.startGesture(trayY);
    await gesture.moveTo(pointerFor(tester, 3, 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(engine.board.colorAt(3, 4), isNotNull);
    expect(engine.score, greaterThan(0));
  });

  testWidgets('clearing a line shows a score popup', (tester) async {
    final engine = scriptedEngine([
      [dot(), dot(), dot()],
      [dot(), dot(), dot()],
      [dot(), dot(), dot()],
    ], preset: (b) {
      for (var c = 0; c < 7; c++) {
        b.fill(4, c, 2);
      }
    });
    await pumpGame(tester, engine);

    final trayY = tester.getCenter(find.descendant(of: find.byType(TrayView), matching: find.byType(Listener)).first);
    final gesture = await tester.startGesture(trayY);
    await gesture.moveTo(pointerFor(tester, 4, 7));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(find.text('+81'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('pause opens and resumes', (tester) async {
    await pumpGame(
      tester,
      scriptedEngine([
        [dot(), dot(), dot()],
      ]),
    );
    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsNothing);
  });

  testWidgets('game over panel appears when no moves remain',
      (tester) async {
    final engine = scriptedEngine([
      [dot(), dot(), dot()],
    ]);
    await pumpGame(tester, engine);

    // Use the three dots, then the dealer runs dry.
    for (var i = 0; i < 3; i++) {
      final slot = find
          .descendant(
            of: find.byType(TrayView),
            matching: find.byType(Listener),
          )
          .at(i);
      final gesture = await tester.startGesture(tester.getCenter(slot));
      await gesture.moveTo(pointerFor(tester, 6, i));
      await tester.pump();
      await gesture.up();
      await tester.pump();
    }
    // The panel arrives after the clear delay timer.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Game over'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);

    await tester.tap(find.text('Play again'));
    await tester.pumpAndSettle();
    expect(find.text('Game over'), findsNothing);
  });

  testWidgets('haptics toggle flips in pause panel', (tester) async {
    final settings = SettingsStore.memory();
    await pumpGame(
      tester,
      scriptedEngine([
        [dot(), dot(), dot()],
      ]),
      settings: settings,
    );
    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pumpAndSettle();
    expect(settings.haptics, isTrue);
    await tester.tap(find.text('Haptics'));
    await tester.pumpAndSettle();
    expect(settings.haptics, isFalse);
  });

  testWidgets('random engine smoke', (tester) async {
    await pumpGame(
      tester,
      GameEngine.seeded(9, scoreStore: MemoryScoreStore()),
      settings: SettingsStore.memory(),
    );
    expect(find.byType(BoardView), findsOneWidget);
  });
}
