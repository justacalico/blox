import 'dart:math';

import 'package:flutter/widgets.dart';

/// One confetti-style burst particle.
final class _Particle {
  _Particle({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    required this.spin,
  });

  final Offset origin;
  final Offset velocity;
  final Color color;
  final double size;
  final double spin;
}

/// Square spark particles that burst when lines clear. Driven by an
/// [AnimationController] owned by the parent so tests can pump exact frames.
class ParticleLayer extends StatefulWidget {
  const ParticleLayer({super.key, this.random});

  final Random? random;

  @override
  State<ParticleLayer> createState() => ParticleLayerState();
}

class ParticleLayerState extends State<ParticleLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Random _random;
  final List<_Particle> _particles = [];
  double _t = 0;

  @override
  void initState() {
    super.initState();
    _random = widget.random ?? Random();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(_tick);
  }

  /// Spawns [count] sparks around [origin] in [color].
  void burst(Offset origin, Color color, {int count = 10}) {
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * pi * 2;
      final speed = 60 + _random.nextDouble() * 160;
      _particles.add(
        _Particle(
          origin: origin,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed - 40),
          color: color,
          size: 3 + _random.nextDouble() * 5,
          spin: _random.nextDouble() * pi,
        ),
      );
    }
    _t = 0;
    _controller.forward(from: 0);
  }

  bool get isActive => _controller.isAnimating || _particles.isNotEmpty;

  void _tick() {
    setState(() => _t = _controller.value);
    if (_controller.isCompleted) {
      _particles.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(_particles, _t),
        size: Size.infinite,
      ),
    );
  }
}

final class _ParticlePainter extends CustomPainter {
  const _ParticlePainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const life = 0.6; // seconds
    final elapsed = t * life;
    final paint = Paint();
    for (final p in particles) {
      final dx = p.origin.dx + p.velocity.dx * elapsed;
      final dy =
          p.origin.dy + p.velocity.dy * elapsed + 240 * elapsed * elapsed;
      final fade = (1 - t).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: fade * 0.9);
      final s = p.size * (1 - t * 0.5);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.spin + t * 3);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: s, height: s),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.t != t || old.particles != particles;
}
