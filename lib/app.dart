import 'package:blox/l10n/generated/app_localizations.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/material.dart';

class BloxApp extends StatelessWidget {
  const BloxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: BloxTheme.material(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(),
    );
  }
}
