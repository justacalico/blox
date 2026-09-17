import 'package:blox/app.dart';
import 'package:blox/src/settings.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.loadPersisted();
  runApp(BloxApp(settings: settings));
}
