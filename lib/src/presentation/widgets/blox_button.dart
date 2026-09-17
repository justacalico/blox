import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';

/// The chunky pressable button used across menus: colored face, deep bottom
/// edge, presses down 3px when held.
class BloxButton extends StatefulWidget {
  const BloxButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = BloxColors.ctaOrange,
    this.deepColor = BloxColors.ctaOrangeDeep,
    this.icon,
    this.fontSize = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 44, vertical: 14),
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color deepColor;
  final Widget? icon;
  final double fontSize;
  final EdgeInsets padding;

  @override
  State<BloxButton> createState() => _BloxButtonState();
}

class _BloxButtonState extends State<BloxButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 5.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: BloxMotion.snap,
        transform: Matrix4.translationValues(0, _down ? depth : 0, 0),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: widget.deepColor,
                width: _down ? 1.5 : depth,
              ),
            ),
            boxShadow: _down
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: BloxText.display(
                  widget.fontSize,
                ).copyWith(letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
