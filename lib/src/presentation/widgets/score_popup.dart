import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';

/// A floating "+N" or "Combo xN" that rises, holds, then fades.
/// The parent adds entries and removes them via [onDone].
class ScorePopup extends StatefulWidget {
  const ScorePopup({
    super.key,
    required this.text,
    required this.onDone,
    this.color = BloxColors.ink,
    this.fontSize = 34,
  });

  final String text;
  final VoidCallback onDone;
  final Color color;
  final double fontSize;

  @override
  State<ScorePopup> createState() => _ScorePopupState();
}

class _ScorePopupState extends State<ScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: BloxMotion.float,
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Rise fast, drift up slowly, fade at the end.
        final rise = Curves.easeOut.transform(t.clamp(0.0, 0.6) / 0.6) * 44;
        final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);
        final scale = t < 0.2 ? Curves.easeOutBack.transform(t / 0.2) : 1.0;
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, -rise),
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Text(
        widget.text,
        style: BloxText.display(widget.fontSize, color: widget.color).copyWith(
          shadows: [
            Shadow(
              color: widget.color.withValues(alpha: 0.5),
              blurRadius: 12,
            ),
            const Shadow(color: Color(0x80000000), offset: Offset(0, 3)),
          ],
        ),
      ),
    );
  }
}
