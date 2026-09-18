import 'dart:math';

import 'package:blox/l10n/generated/app_localizations.dart';
import 'package:blox/src/game/game_engine.dart';
import 'package:blox/src/presentation/widgets/overlays.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';

/// The cheat panel shown in the pause overlay once cheats are enabled in
/// settings. Every button maps to a [GameEngine] cheat method.
class CheatMenu extends StatelessWidget {
  const CheatMenu({super.key, required this.engine, this.random});

  final GameEngine engine;

  /// Seedable randomness for the dealt pieces. The game screen passes its
  /// own so tests stay deterministic.
  final Random? random;

  /// Points granted by the score cheat.
  static const int scoreBonus = 500;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.cheats,
          style: BloxText.display(18, color: BloxColors.crown),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _CheatButton(
              label: l10n.cheatScore(scoreBonus),
              onPressed: () => engine.grantScore(scoreBonus),
            ),
            _CheatButton(label: l10n.cheatWipe, onPressed: engine.wipeBoard),
            _CheatButton(label: l10n.cheatReroll, onPressed: engine.redealTray),
            _CheatButton(
              label: l10n.cheatFitting,
              onPressed: () => engine.dealFittingTray(random: random),
            ),
            _CheatButton(label: l10n.cheatPrime, onPressed: engine.primeClear),
            _CheatButton(label: l10n.cheatRevive, onPressed: engine.revive),
          ],
        ),
        const SizedBox(height: 6),
        ToggleRow(
          label: l10n.cheatGodMode,
          value: engine.neverGameOver,
          onChanged: (v) => engine.neverGameOver = v,
        ),
      ],
    );
  }
}

/// Small chip button for one cheat action.
class _CheatButton extends StatelessWidget {
  const _CheatButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: BloxColors.panelDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            bottom: BorderSide(color: BloxColors.boardEdge, width: 3),
          ),
        ),
        child: Text(label, style: BloxText.label(13, color: BloxColors.ink)),
      ),
    );
  }
}
