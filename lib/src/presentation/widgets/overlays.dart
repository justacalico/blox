import 'package:blox/l10n/generated/app_localizations.dart';
import 'package:blox/src/settings.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';

/// Dimmed backdrop with a rounded panel that pops in.
class OverlayPanel extends StatelessWidget {
  const OverlayPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xB3181B34),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: BloxMotion.pop,
          curve: BloxMotion.popCurve,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            decoration: BoxDecoration(
              color: BloxColors.panel,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: BloxColors.ink.withValues(alpha: 0.08),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Full-width chunky button for overlay panels.
class BloxRowButton extends StatelessWidget {
  const BloxRowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = BloxColors.ctaOrange,
    this.deepColor = BloxColors.ctaOrangeDeep,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color deepColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border(bottom: BorderSide(color: deepColor, width: 5)),
        ),
        child: Center(
          child: Text(label, style: BloxText.display(20)),
        ),
      ),
    );
  }
}

/// Haptics + sound switches. Shared by the pause panel and the menu.
class SettingsToggles extends StatelessWidget {
  const SettingsToggles({super.key, required this.settings});

  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ToggleRow(
              label: l10n.haptics,
              value: settings.haptics,
              onChanged: (v) => settings.haptics = v,
            ),
            ToggleRow(
              label: l10n.sound,
              value: settings.sound,
              onChanged: (v) => settings.sound = v,
            ),
            ToggleRow(
              label: l10n.cheats,
              value: settings.cheats,
              onChanged: (v) => settings.cheats = v,
            ),
          ],
        );
      },
    );
  }
}

/// A label next to a pill switch. Used by [SettingsToggles] and the cheat
/// menu.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: BloxText.label(16)),
            ),
            AnimatedContainer(
              duration: BloxMotion.snap,
              width: 52,
              height: 30,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? BloxColors.ctaTeal : BloxColors.panelDeep,
                borderRadius: BorderRadius.circular(15),
              ),
              child: AnimatedAlign(
                duration: BloxMotion.snap,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: BloxColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
