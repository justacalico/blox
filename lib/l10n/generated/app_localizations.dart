import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The name of the app, shown on the menu screen.
  ///
  /// In en, this message translates to:
  /// **'Blox'**
  String get appTitle;

  /// Short tagline under the title on the menu screen.
  ///
  /// In en, this message translates to:
  /// **'Fill rows. Clear the board.'**
  String get tagline;

  /// Button that starts a new run.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Label for the current score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// Label for the all time best score.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get best;

  /// Shown when the player beats their best score.
  ///
  /// In en, this message translates to:
  /// **'New best!'**
  String get newBest;

  /// Title of the game over screen.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOver;

  /// Subtitle on the game over screen.
  ///
  /// In en, this message translates to:
  /// **'No moves left'**
  String get noMoves;

  /// Button that restarts the run from the game over screen.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// Button that returns to the menu screen.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get backToMenu;

  /// Button that pauses the game.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Button that resumes a paused game.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Button that abandons the current run and starts a new one.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// Button that opens the settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Toggle label for vibration feedback.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get haptics;

  /// Toggle label for sound effects.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// One line tutorial hint under the piece tray.
  ///
  /// In en, this message translates to:
  /// **'Drag a piece onto the board'**
  String get dragHint;

  /// Popup shown when the player clears lines on consecutive placements.
  ///
  /// In en, this message translates to:
  /// **'Combo x{count}'**
  String combo(int count);

  /// Floating popup that shows points earned by a clear.
  ///
  /// In en, this message translates to:
  /// **'+{points}'**
  String pointsEarned(int points);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
