import 'package:blox/src/presentation/screens/menu_screen.dart';
import 'package:blox/src/presentation/widgets/board_view.dart';
import 'package:blox/src/settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadTestFonts);

  testWidgets('gear opens settings, toggles flip, backdrop dismisses',
      (tester) async {
    final settings = SettingsStore.memory();
    await tester.pumpWidget(testApp(MenuScreen(settings: settings)));
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Sound'));
    await tester.pump();
    expect(settings.sound, isFalse);
    await tester.tap(find.text('Haptics'));
    await tester.pump();
    expect(settings.haptics, isFalse);

    // Taps inside the panel are swallowed and keep it open.
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Settings'), findsOneWidget);

    // Tap the dimmed backdrop outside the panel.
    await tester.tapAt(const Offset(20, 20));
    await tester.pump();
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('play pushes the game and back-to-menu returns', (tester) async {
    await tester.pumpWidget(
      testApp(MenuScreen(settings: SettingsStore.memory())),
    );
    await tester.pump();

    await tester.tap(find.text('Play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BoardView), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Pause'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Play'), findsOneWidget);
  });
}
