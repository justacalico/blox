import 'package:blox/src/presentation/widgets/blox_button.dart';
import 'package:blox/src/presentation/widgets/piece_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadTestFonts);

  testWidgets('BloxButton taps and renders an icon', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      testApp(
        Center(
          child: BloxButton(
            label: 'Go',
            icon: const Icon(Icons.star),
            onPressed: () => taps++,
          ),
        ),
      ),
    );
    expect(find.byType(Icon), findsOneWidget);
    await tester.tap(find.byType(BloxButton));
    expect(taps, 1);
  });

  testWidgets('BloxButton press cancelled by a long move', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      testApp(
        Center(child: BloxButton(label: 'Go', onPressed: () => taps++)),
      ),
    );
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(BloxButton)));
    await gesture.moveBy(const Offset(0, 200));
    await gesture.up();
    expect(taps, 0);
  });

  testWidgets('PieceView paints ghost and dimmed variants', (tester) async {
    await tester.pumpWidget(
      testApp(
        Column(
          children: [
            PieceView(piece: dot(), cellPx: 24, ghost: true),
            PieceView(piece: square2(2), cellPx: 24, dimmed: true),
          ],
        ),
      ),
    );
    expect(find.byType(PieceView), findsNWidgets(2));
  });
}
