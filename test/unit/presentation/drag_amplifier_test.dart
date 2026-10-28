import 'package:blox/src/presentation/drag_amplifier.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leaves the pickup point where the finger went down', () {
    const amp = DragAmplifier(Offset(10, 20), gain: 2);
    expect(amp.resolve(const Offset(10, 20)), const Offset(10, 20));
  });

  test('multiplies finger travel by the gain', () {
    const amp = DragAmplifier(Offset(10, 20), gain: 4);
    expect(amp.resolve(const Offset(15, 12)), const Offset(30, -12));
  });

  test('defaults to the theme gain', () {
    const amp = DragAmplifier(Offset.zero);
    expect(amp.gain, BloxMotion.dragGain);
  });
}
