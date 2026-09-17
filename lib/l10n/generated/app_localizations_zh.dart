// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Blox';

  @override
  String get tagline => '填满行列,消除方块。';

  @override
  String get play => '开始';

  @override
  String get score => '分数';

  @override
  String get best => '最高';

  @override
  String get newBest => '新纪录!';

  @override
  String get gameOver => '游戏结束';

  @override
  String get noMoves => '无处可放了';

  @override
  String get playAgain => '再来一局';

  @override
  String get backToMenu => '菜单';

  @override
  String get pause => '暂停';

  @override
  String get resume => '继续';

  @override
  String get restart => '重开';

  @override
  String get settings => '设置';

  @override
  String get haptics => '震动';

  @override
  String get sound => '音效';

  @override
  String get dragHint => '把方块拖到棋盘上';

  @override
  String combo(int count) {
    return '连击 x$count';
  }

  @override
  String pointsEarned(int points) {
    return '+$points';
  }
}
