import 'package:blox/src/game/game_engine.dart';
import 'package:blox/src/game/score_store.dart';
import 'package:blox/src/presentation/board_layout.dart';
import 'package:blox/src/presentation/screens/game_screen.dart';
import 'package:blox/src/presentation/widgets/board_view.dart';
import 'package:blox/src/presentation/widgets/particle_layer.dart';
import 'package:blox/src/presentation/widgets/tray_view.dart';
import 'package:blox/src/settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Center of cell (row, col) in global coordinates.
Offset cellCenter(WidgetTester tester, int row, int col) {
  final boardRect = tester.getRect(find.byType(BoardView));
  final layout = BoardLayout(boardPx: boardRect.width);
  return boardRect.topLeft + layout.cellRect(row, col).center;
}

/// The position the pointer must reach for a w-by-h piece anchored at
/// (row, col): the piece floats above the finger by the lift distance.
Offset pointerFor(WidgetTester tester, int row, int col,
    {int w = 1, int h = 1}) {
  final boardRect = tester.getRect(find.byType(BoardView));
  final layout = BoardLayout(boardPx: boardRect.width);
  final lift = layout.cellPx * 1.7 + 12;
  final target = boardRect.topLeft +
      layout.cellOrigin(row, col) +
      Offset(w * layout.cellPx / 2, h * layout.cellPx / 2);
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

  testWidgets('grabs a piece from the padded edge of its slot', (tester) async {
    final engine = scriptedEngine([
      [dot(3), dot(1), dot(2)],
    ]);
    await pumpGame(tester, engine);

    final slot = find
        .descendant(of: find.byType(TrayView), matching: find.byType(Listener))
        .first;
    final zone = tester.getRect(slot);
    // Far left of the centered 96px piece box, but inside the slot's share
    // of the tray row.
    final gesture =
        await tester.startGesture(Offset(zone.left + 8, zone.center.dy));
    await gesture.moveTo(pointerFor(tester, 3, 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(engine.tray[0], isNull, reason: 'edge grab still dragged slot 0');
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

    // The dealer is dry, so the fresh game ends immediately too.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Game over'), findsOneWidget);
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
  });

  testWidgets('dropping on an occupied cell does not place', (tester) async {
    final engine = scriptedEngine([
      [dot(), dot(), dot()],
    ]);
    await pumpGame(tester, engine);

    Future<void> dragSlot(int slot, int row, int col) async {
      final target = find
          .descendant(
            of: find.byType(TrayView),
            matching: find.byType(Listener),
          )
          .at(slot);
      final gesture = await tester.startGesture(tester.getCenter(target));
      await gesture.moveTo(pointerFor(tester, row, col));
      await tester.pump();
      await gesture.up();
      await tester.pump();
    }

    await dragSlot(0, 2, 2);
    expect(engine.board.colorAt(2, 2), isNotNull);
    await dragSlot(1, 2, 2);
    // The second piece bounced off: slot 1 is still full, board unchanged.
    expect(engine.tray[1], isNotNull);
    expect(engine.board.colorAt(2, 2), isNotNull);
  });

  testWidgets('multi-line clears show combo popup and particles',
      (tester) async {
    final engine = scriptedEngine([
      [dot(), line2h(5), dot()],
    ], preset: (b) {
      // Row 4 and column 4 both miss only (4,4). Row 6 misses (6,4) and
      // (6,5); the column clear reopens (6,4), so a horizontal domino there
      // finishes the row.
      for (var i = 0; i < 8; i++) {
        if (i != 4) b.fill(4, i, 2);
        if (i != 4) b.fill(i, 4, 3);
        if (i != 5) b.fill(6, i, 1);
      }
    });
    final state = await pumpGame(tester, engine);

    Future<void> dragSlot(int slot, int row, int col,
        {int w = 1, int h = 1}) async {
      final target = find
          .descendant(
            of: find.byType(TrayView),
            matching: find.byType(Listener),
          )
          .at(slot);
      final gesture = await tester.startGesture(tester.getCenter(target));
      await gesture.moveTo(pointerFor(tester, row, col, w: w, h: h));
      await tester.pump();
      await gesture.up();
      await tester.pump();
    }

    await dragSlot(0, 4, 4);
    expect(state.engine.score, greaterThan(0));
    expect(
      tester
          .state<ParticleLayerState>(find.byType(ParticleLayer))
          .isActive,
      isTrue,
    );
    await tester.pumpAndSettle();

    await dragSlot(1, 6, 4, w: 2);
    expect(find.text('Combo x2'), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('pause panel restart resets the game', (tester) async {
    final engine = scriptedEngine([
      [dot(), dot(), dot()],
      [dot(), dot(), dot()],
    ]);
    await pumpGame(tester, engine);

    final slot = find
        .descendant(of: find.byType(TrayView), matching: find.byType(Listener))
        .first;
    final gesture = await tester.startGesture(tester.getCenter(slot));
    await gesture.moveTo(pointerFor(tester, 3, 3));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(engine.score, greaterThan(0));

    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();
    expect(engine.score, 0);
    expect(find.text('Resume'), findsNothing);
  });

  testWidgets('pause panel sound toggle and back-to-menu', (tester) async {
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
    expect(settings.sound, isTrue);
    await tester.tap(find.text('Sound'));
    await tester.pumpAndSettle();
    expect(settings.sound, isFalse);

    // The screen is the root route here, so maybePop has nowhere to go and
    // the panel stays up.
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('vibrates once per cell the drag passes over', (tester) async {
    var ticks = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.selectionClick') {
          ticks++;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await pumpGame(
      tester,
      scriptedEngine([
        [dot(), dot(), dot()],
      ]),
    );

    final slot = find
        .descendant(of: find.byType(TrayView), matching: find.byType(Listener))
        .first;
    final gesture = await tester.startGesture(tester.getCenter(slot));
    await tester.pump();
    expect(ticks, 0, reason: 'the pickup tap is not a cell tick');

    await gesture.moveTo(pointerFor(tester, 3, 3));
    await tester.pump();
    expect(ticks, 1);

    // Wiggling inside the same cell stays quiet.
    await gesture.moveBy(const Offset(2, 0));
    await tester.pump();
    expect(ticks, 1);

    await gesture.moveTo(pointerFor(tester, 3, 4));
    await tester.pump();
    expect(ticks, 2);

    // Leaving the board is quiet; coming back over a cell ticks again.
    final board = tester.getRect(find.byType(BoardView));
    await gesture.moveTo(
      Offset(board.left - 40, pointerFor(tester, 3, 4).dy),
    );
    await tester.pump();
    expect(ticks, 2);

    await gesture.moveTo(pointerFor(tester, 3, 4));
    await tester.pump();
    expect(ticks, 3);

    await gesture.up();
    await tester.pump();
    expect(ticks, 3, reason: 'the drop tap is not a cell tick');
  });

  testWidgets('cancelling a drag leaves the tray intact', (tester) async {
    final engine = scriptedEngine([
      [dot(), dot(), dot()],
    ]);
    await pumpGame(tester, engine);

    final slot = find
        .descendant(of: find.byType(TrayView), matching: find.byType(Listener))
        .first;
    final gesture = await tester.startGesture(tester.getCenter(slot));
    await gesture.moveTo(pointerFor(tester, 3, 3));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();
    expect(engine.tray[0], isNotNull);
    expect(engine.board.colorAt(3, 3), isNull);
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

  testWidgets('cheat menu stays hidden until enabled in settings',
      (tester) async {
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
    expect(find.text('Clear board'), findsNothing);

    await tester.tap(find.text('Cheats'));
    await tester.pumpAndSettle();
    expect(settings.cheats, isTrue);
    expect(find.text('Clear board'), findsOneWidget);
  });

  testWidgets('cheat menu buttons drive the engine', (tester) async {
    final settings = SettingsStore.memory(cheats: true);
    final engine = scriptedEngine([
      [square2(1), square2(2), square2(3)],
      [dot(1), dot(2), dot(3)],
    ], preset: (b) {
      b.fill(0, 0, 1);
      b.fill(0, 1, 1);
    });
    await pumpGame(tester, engine, settings: settings);
    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+500 score'));
    await tester.pump();
    expect(engine.score, 500);

    await tester.tap(find.text('Clear board'));
    await tester.pump();
    expect(engine.board.isEmpty, isTrue);

    await tester.tap(find.text('Reroll pieces'));
    await tester.pump();
    expect(engine.tray[0]!.shape.id, 'dot');

    await tester.tap(find.text('All fitting'));
    await tester.pump();
    expect(engine.tray.every((p) => p != null), isTrue);
    expect(engine.trayPlaceability.every((ok) => ok), isTrue);

    await tester.tap(find.text('Prime a line'));
    await tester.pump();
    expect(engine.board.isEmptyAt(0, 0), isTrue);
    expect(engine.board.isEmptyAt(0, 7), isFalse);

    await tester.tap(find.text('Revive'));
    await tester.pump();
    expect(engine.tray.every((p) => p != null), isTrue);

    await tester.tap(find.text('God mode'));
    await tester.pump();
    expect(engine.neverGameOver, isTrue);
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
