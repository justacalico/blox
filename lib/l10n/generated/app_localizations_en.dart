// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Blox';

  @override
  String get tagline => 'Fill rows. Clear the board.';

  @override
  String get play => 'Play';

  @override
  String get score => 'Score';

  @override
  String get best => 'Best';

  @override
  String get newBest => 'New best!';

  @override
  String get gameOver => 'Game over';

  @override
  String get noMoves => 'No moves left';

  @override
  String get playAgain => 'Play again';

  @override
  String get backToMenu => 'Menu';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get restart => 'Restart';

  @override
  String get settings => 'Settings';

  @override
  String get haptics => 'Haptics';

  @override
  String get sound => 'Sound';

  @override
  String get dragHint => 'Drag a piece onto the board';

  @override
  String combo(int count) {
    return 'Combo x$count';
  }

  @override
  String pointsEarned(int points) {
    return '+$points';
  }

  @override
  String get cheats => 'Cheats';

  @override
  String cheatScore(int points) {
    return '+$points score';
  }

  @override
  String get cheatWipe => 'Clear board';

  @override
  String get cheatReroll => 'Reroll pieces';

  @override
  String get cheatFitting => 'All fitting';

  @override
  String get cheatPrime => 'Prime a line';

  @override
  String get cheatRevive => 'Revive';

  @override
  String get cheatGodMode => 'God mode';
}
