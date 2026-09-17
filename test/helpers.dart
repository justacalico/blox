import 'package:blox/l10n/generated/app_localizations.dart';
import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/game_engine.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_generator.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:blox/src/game/score_store.dart';
import 'package:blox/src/settings.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real Fredoka font so goldens render actual glyphs.
Future<void> loadTestFonts() async {
  final loader = FontLoader('Fredoka')
    ..addFont(rootBundle.load('assets/fonts/Fredoka.ttf'));
  await loader.load();
}

/// Wraps a widget in the app's real localization + theme shell.
Widget testApp(Widget child, {SettingsStore? settings}) {
  return MaterialApp(
    theme: BloxTheme.material(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

/// Deals scripted hands; same idea as the engine tests.
final class ScriptedDealer implements PieceDealer {
  ScriptedDealer(this.hands);

  final List<List<Piece>> hands;
  var _next = 0;

  @override
  List<Piece> deal(Board board) =>
      _next >= hands.length ? const [] : hands[_next++];
}

Piece dot([int color = 0]) =>
    Piece(PieceShape('dot', const [(row: 0, col: 0)]), color);

Piece line3v([int color = 0]) => Piece(
      PieceShape(
        'l3v',
        const [(row: 0, col: 0), (row: 1, col: 0), (row: 2, col: 0)],
      ),
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

Piece line2h([int color = 0]) => Piece(
      PieceShape(
        'l2h',
        const [(row: 0, col: 0), (row: 0, col: 1)],
      ),
      color,
    );

Piece corner3([int color = 0]) => Piece(
      PieceShape('c3', const [
        (row: 0, col: 0),
        (row: 1, col: 0),
        (row: 2, col: 0),
        (row: 2, col: 1),
        (row: 2, col: 2),
      ]),
      color,
    );

GameEngine scriptedEngine(
  List<List<Piece>> hands, {
  ScoreStore? store,
  void Function(Board)? preset,
}) {
  final e = GameEngine(dealer: ScriptedDealer(hands), scoreStore: store);
  preset?.call(e.board);
  return e;
}
