import 'dart:ui';

import 'package:blox/src/theme/blox_theme.dart';

/// Turns raw pointer travel into amplified board travel.
///
/// The piece follows an exaggerated copy of the finger, so a short wrist
/// move near the tray steers it anywhere on the grid instead of shadowing
/// the finger pixel-for-pixel across the screen.
final class DragAmplifier {
  const DragAmplifier(this.origin, {this.gain = BloxMotion.dragGain});

  /// Where the finger went down.
  final Offset origin;

  /// How far the piece travels per pixel of finger travel.
  final double gain;

  /// The amplified pointer position the piece steers toward.
  Offset resolve(Offset pointer) => origin + (pointer - origin) * gain;
}
