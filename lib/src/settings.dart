import 'package:blox/src/game/score_store.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing toggles plus the persisted best score.
///
/// Backed by [SharedPreferences] in the app and by an in-memory map in
/// tests via [SettingsStore.memory].
final class SettingsStore extends ChangeNotifier implements ScoreStore {
  SettingsStore._(this._haptics, this._sound, this._best, this._persist);

  static const _hapticsKey = 'haptics_enabled';
  static const _soundKey = 'sound_enabled';
  static const _bestKey = 'best_score';

  bool _haptics;
  bool _sound;
  int _best;
  final void Function(String key, Object value) _persist;

  /// Loads the real store. Call once before `runApp`.
  static Future<SettingsStore> loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    void persist(String key, Object value) {
      if (value is bool) prefs.setBool(key, value);
      if (value is int) prefs.setInt(key, value);
    }

    return SettingsStore._(
      prefs.getBool(_hapticsKey) ?? true,
      prefs.getBool(_soundKey) ?? true,
      prefs.getInt(_bestKey) ?? 0,
      persist,
    );
  }

  /// Volatile store for tests.
  factory SettingsStore.memory({int best = 0}) {
    return SettingsStore._(true, true, best, (_, _) {});
  }

  bool get haptics => _haptics;
  set haptics(bool value) {
    if (_haptics == value) return;
    _haptics = value;
    _persist(_hapticsKey, value);
    notifyListeners();
  }

  bool get sound => _sound;
  set sound(bool value) {
    if (_sound == value) return;
    _sound = value;
    _persist(_soundKey, value);
    notifyListeners();
  }

  @override
  int load() => _best;

  @override
  void save(int score) {
    _best = score;
    _persist(_bestKey, score);
  }
}
