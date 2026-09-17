import 'dart:math' as math;

import 'package:blox/l10n/generated/app_localizations.dart';
import 'package:blox/src/presentation/screens/game_screen.dart';
import 'package:blox/src/presentation/widgets/blox_button.dart';
import 'package:blox/src/presentation/widgets/overlays.dart';
import 'package:blox/src/settings.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

/// Landing screen: logo, tagline, big play button, best score, settings.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob;

  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: BloxColors.backdropBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [BloxColors.backdropTop, BloxColors.backdropBottom],
          ),
        ),
        child: SafeArea(
        child: Stack(
          children: [
            const _DriftingBlocks(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BloxLogo(),
                  const SizedBox(height: 10),
                  Text(l10n.tagline, style: BloxText.label(15)),
                  const SizedBox(height: 42),
                  AnimatedBuilder(
                    animation: _bob,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, -6 * _bob.value),
                      child: child,
                    ),
                    child: BloxButton(
                      label: l10n.play,
                      fontSize: 26,
                      onPressed: () {
                        Navigator.of(context).push(
                          BloxPageRoute(
                            child: GameScreen(settings: widget.settings),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _BestPill(best: widget.settings.load(), label: l10n.best),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _GearButton(
                onPressed: () => setState(() => _showSettings = true),
                tooltip: l10n.settings,
              ),
            ),
            if (_showSettings)
              GestureDetector(
                onTap: () => setState(() => _showSettings = false),
                child: OverlayPanel(
                  child: GestureDetector(
                    onTap: () {}, // swallow taps inside the panel
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.settings, style: BloxText.display(30)),
                        const SizedBox(height: 16),
                        SettingsToggles(settings: widget.settings),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}

/// The wordmark: candy letters with a crown, like the reference art.
class BloxLogo extends StatelessWidget {
  const BloxLogo({super.key, this.fontSize = 84});

  final double fontSize;

  static const _letters = [
    ('B', BloxColors.orange),
    ('L', BloxColors.blue),
    ('O', BloxColors.red),
    ('X', BloxColors.purple),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (letter, color) in _letters)
              Transform.rotate(
                angle: letter == 'O' ? -0.04 : 0,
                child: Text(
                  letter,
                  style: BloxText.display(fontSize, color: color).copyWith(
                    letterSpacing: 2,
                    shadows: const [
                      Shadow(color: Color(0x66000000), offset: Offset(0, 6)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        Positioned(
          top: -fontSize * 0.34,
          left: fontSize * 1.38,
          child: Transform.rotate(
            angle: 0.18,
            child: CustomPaint(
              size: Size.square(fontSize * 0.55),
              painter: _LogoCrownPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

final class _LogoCrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = BloxColors.crown;
    final path = Path()
      ..moveTo(w * 0.05, h * 0.8)
      ..lineTo(w * 0.95, h * 0.8)
      ..lineTo(w * 0.9, h * 0.35)
      ..lineTo(w * 0.68, h * 0.55)
      ..lineTo(w * 0.5, h * 0.2)
      ..lineTo(w * 0.32, h * 0.55)
      ..lineTo(w * 0.1, h * 0.35)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.8, w * 0.9, h * 0.14),
        Radius.circular(h * 0.06),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LogoCrownPainter old) => false;
}

/// A couple of lone blocks drifting behind the menu for life.
class _DriftingBlocks extends StatefulWidget {
  const _DriftingBlocks();

  @override
  State<_DriftingBlocks> createState() => _DriftingBlocksState();
}

class _DriftingBlocksState extends State<_DriftingBlocks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
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
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          children: [
            for (final (dx, dy, size, color, phase) in _blocks)
              Positioned(
                left: dx,
                top: dy + 14 * math.sin(t + phase),
                child: Transform.rotate(
                  angle: 0.2 * math.sin(t + phase),
                  child: CustomPaint(
                    size: Size.square(size),
                    painter: _MiniBlockPainter(color),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static const _blocks = [
    (30.0, 120.0, 26.0, BloxColors.green, 0.0),
    (330.0, 200.0, 20.0, BloxColors.yellow, 1.3),
    (60.0, 560.0, 22.0, BloxColors.cyan, 2.6),
    (320.0, 620.0, 28.0, BloxColors.red, 3.9),
    (180.0, 700.0, 18.0, BloxColors.purple, 5.1),
  ];
}

final class _MiniBlockPainter extends CustomPainter {
  const _MiniBlockPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.22)),
      Paint()..color = color.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_MiniBlockPainter old) => old.color != color;
}

class _BestPill extends StatelessWidget {
  const _BestPill({required this.best, required this.label});

  final int best;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: BloxColors.panelDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: BloxText.label(14)),
          Text('$best', style: BloxText.display(18)),
        ],
      ),
    );
  }
}

class _GearButton extends StatelessWidget {
  const _GearButton({required this.onPressed, required this.tooltip});

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: BloxColors.panelDeep,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(child: _GearGlyph()),
        ),
      ),
    );
  }
}

class _GearGlyph extends StatelessWidget {
  const _GearGlyph();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size.square(20), painter: _GearPainter());
  }
}

final class _GearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()..color = BloxColors.inkSoft;
    for (var i = 0; i < 8; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * math.pi / 4);
      canvas.drawRect(
        Rect.fromLTWH(-r * 0.16, -r, r * 0.32, r * 0.36),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.62, paint);
    canvas.drawCircle(
      c,
      r * 0.3,
      Paint()..color = BloxColors.panelDeep,
    );
  }

  @override
  bool shouldRepaint(_GearPainter old) => false;
}

/// Slide-up transition used when pushing the game screen.
class BloxPageRoute extends PageRouteBuilder<void> {
  BloxPageRoute({required Widget child})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (context, _, _) => child,
          transitionsBuilder: (context, anim, _, child) {
            final curved = CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            );
            return SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
}
