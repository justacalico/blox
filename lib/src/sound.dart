import 'package:flutter/services.dart';

/// Thin wrapper over [SystemSound], switchable and mockable.
final class BloxSound {
  const BloxSound({this.enabled = true});

  final bool enabled;

  /// Piece picked up or snapped in.
  void click() {
    if (enabled) SystemSound.play(SystemSoundType.click);
  }
}
