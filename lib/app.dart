import 'package:blox/l10n/generated/app_localizations.dart';
import 'package:blox/src/presentation/screens/menu_screen.dart';
import 'package:blox/src/settings.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/material.dart';

class BloxApp extends StatelessWidget {
  const BloxApp({super.key, required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: BloxTheme.material(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MenuScreen(settings: settings),
    );
  }
}
