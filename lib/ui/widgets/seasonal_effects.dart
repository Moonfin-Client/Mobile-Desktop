import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class SeasonalEffects extends StatefulWidget {
  final String effect;

  const SeasonalEffects({super.key, required this.effect});

  @override
  State<SeasonalEffects> createState() => _SeasonalEffectsState();
}

class _SeasonalEffectsState extends State<SeasonalEffects>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _particles = <_Particle>[];
  final _random = Random();
  Timer? _spawnTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _controller.addListener(_updateParticles);

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_particles.length < 60) {
        _spawnParticle();
      }
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _controller.removeListener(_updateParticles);
    _controller.dispose();
    super.dispose();
  }

  void _spawnParticle() {
    final config = _configFor(widget.effect);
    if (config == null) return;

    _particles.add(_Particle(
      x: _random.nextDouble(),
      y: config.spawnFromTop ? -0.05 : _random.nextDouble(),
      dx: (_random.nextDouble() - 0.5) * config.horizontalSpeed,
      dy: config.fallSpeed + _random.nextDouble() * config.fallSpeedVariance,
      size: config.minSize + _random.nextDouble() * (config.maxSize - config.minSize),
      rotation: _random.nextDouble() * 2 * pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * config.rotationSpeed,
      opacity: 0.4 + _random.nextDouble() * 0.6,
      color: config.colors[_random.nextInt(config.colors.length)],
      symbol: config.symbols.isNotEmpty
          ? config.symbols[_random.nextInt(config.symbols.length)]
          : null,
    ));
  }

  void _updateParticles() {
    if (!mounted) return;
    const dt = 0.016;
    _particles.removeWhere((p) => p.y > 1.1 || p.x < -0.1 || p.x > 1.1);
    for (final p in _particles) {
      p.x += p.dx * dt;
      p.y += p.dy * dt;
      p.rotation += p.rotationSpeed * dt;
    }
    setState(() {});
  }

  _EffectConfig? _configFor(String effect) {
    return switch (effect) {
      'snow' => _EffectConfig(
          colors: [Colors.white, Colors.white70, Colors.lightBlue.shade100],
          symbols: ['❄', '❅', '❆', '•'],
          fallSpeed: 0.08,
          fallSpeedVariance: 0.04,
          horizontalSpeed: 0.02,
          rotationSpeed: 1.0,
          minSize: 8,
          maxSize: 18,
          spawnFromTop: true,
        ),
      'fireworks' => _EffectConfig(
          colors: [
            Colors.red, Colors.yellow, Colors.orange,
            Colors.blue, Colors.green, Colors.purple,
          ],
          symbols: ['✦', '✧', '★', '◆', '●'],
          fallSpeed: -0.15,
          fallSpeedVariance: 0.2,
          horizontalSpeed: 0.15,
          rotationSpeed: 3.0,
          minSize: 6,
          maxSize: 14,
          spawnFromTop: false,
        ),
      'confetti' => _EffectConfig(
          colors: [
            Colors.red, Colors.blue, Colors.green, Colors.yellow,
            Colors.pink, Colors.orange, Colors.purple, Colors.cyan,
          ],
          symbols: ['■', '●', '▲', '◆'],
          fallSpeed: 0.12,
          fallSpeedVariance: 0.06,
          horizontalSpeed: 0.08,
          rotationSpeed: 4.0,
          minSize: 6,
          maxSize: 12,
          spawnFromTop: true,
        ),
      'leaves' => _EffectConfig(
          colors: [
            const Color(0xFFD2691E), const Color(0xFF8B4513),
            const Color(0xFFFF8C00), const Color(0xFFDAA520),
            const Color(0xFF228B22),
          ],
          symbols: ['🍂', '🍁', '🍃'],
          fallSpeed: 0.06,
          fallSpeedVariance: 0.03,
          horizontalSpeed: 0.04,
          rotationSpeed: 1.5,
          minSize: 14,
          maxSize: 22,
          spawnFromTop: true,
        ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  double x, y, dx, dy;
  double size;
  double rotation, rotationSpeed;
  double opacity;
  Color color;
  String? symbol;

  _Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
    required this.color,
    this.symbol,
  });
}

class _EffectConfig {
  final List<Color> colors;
  final List<String> symbols;
  final double fallSpeed;
  final double fallSpeedVariance;
  final double horizontalSpeed;
  final double rotationSpeed;
  final double minSize;
  final double maxSize;
  final bool spawnFromTop;

  const _EffectConfig({
    required this.colors,
    required this.symbols,
    required this.fallSpeed,
    required this.fallSpeedVariance,
    required this.horizontalSpeed,
    required this.rotationSpeed,
    required this.minSize,
    required this.maxSize,
    required this.spawnFromTop,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final offset = Offset(p.x * size.width, p.y * size.height);

      if (p.symbol != null && p.symbol!.length <= 2) {
        final tp = TextPainter(
          text: TextSpan(
            text: p.symbol,
            style: TextStyle(
              fontSize: p.size,
              color: p.color.withValues(alpha: p.opacity),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(offset.dx, offset.dy);
        canvas.rotate(p.rotation);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      } else {
        final paint = Paint()
          ..color = p.color.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, p.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
