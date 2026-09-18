import 'package:blox/src/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads defaults when nothing is stored', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsStore.loadPersisted();
    expect(s.haptics, isTrue);
    expect(s.sound, isTrue);
    expect(s.cheats, isFalse);
    expect(s.load(), 0);
  });

  test('loads stored values', () async {
    SharedPreferences.setMockInitialValues({
      'haptics_enabled': false,
      'sound_enabled': false,
      'cheats_enabled': true,
      'best_score': 42,
    });
    final s = await SettingsStore.loadPersisted();
    expect(s.haptics, isFalse);
    expect(s.sound, isFalse);
    expect(s.cheats, isTrue);
    expect(s.load(), 42);
  });

  test('writes changes back to preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await SettingsStore.loadPersisted();
    s.haptics = false;
    s.sound = false;
    s.cheats = true;
    s.save(77);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('haptics_enabled'), isFalse);
    expect(prefs.getBool('sound_enabled'), isFalse);
    expect(prefs.getBool('cheats_enabled'), isTrue);
    expect(prefs.getInt('best_score'), 77);
  });

  test('memory store notifies only on real changes', () {
    final s = SettingsStore.memory(best: 5);
    var notifications = 0;
    s.addListener(() => notifications++);
    s.haptics = false;
    s.haptics = false;
    s.sound = false;
    s.sound = false;
    s.cheats = true;
    s.cheats = true;
    expect(notifications, 3);
    expect(s.load(), 5);
  });
}
