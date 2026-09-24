import 'package:flutter/services.dart';

/// Thin wrapper over [HapticFeedback] so every vibration in the game goes
/// through one switchable, mockable place.
final class BloxHaptics {
  const BloxHaptics({this.enabled = true});

  final bool enabled;

  /// Picking up or dropping a piece.
  void tap() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// The drag hover moved onto a new cell.
  void tick() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// A line (or more) just cleared. The long buzz.
  void clear() {
    if (enabled) HapticFeedback.vibrate();
  }

  /// Big moment: multi-line clear, high combo, new best.
  void thud() {
    if (enabled) {
      HapticFeedback.heavyImpact();
      HapticFeedback.vibrate();
    }
  }

  /// The run ended.
  void gameOver() {
    if (enabled) HapticFeedback.vibrate();
  }
}
