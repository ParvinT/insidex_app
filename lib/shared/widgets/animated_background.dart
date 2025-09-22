// lib/shared/widgets/animated_background.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';

/// Reusable animated background widget for all screens
/// Supports different animation types and performance modes
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final AnimationType type;
  final double opacity;
  final Color? color;
  final int particleCount;
  final bool enableAnimation;
  final bool enableOnMobile;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.type = AnimationType.particles,
    this.opacity = 0.05,
    this.color,
    this.particleCount = 15,
    this.enableAnimation = true,
    this.enableOnMobile = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _secondaryController;
  late List<AnimatedParticle> particles;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
  }

  void _initializeAnimation() {
    // Main animation controller
    _animationController = AnimationController(
      duration: Duration(seconds: widget.type == AnimationType.waves ? 10 : 20),
      vsync: this,
    );

    // Secondary controller for complex animations
    _secondaryController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    // Initialize particles based on type
    particles = List.generate(
      widget.particleCount,
      (index) => AnimatedParticle.random(widget.type),
    );

    // Start animations if enabled
    if (widget.enableAnimation) {
      _animationController.repeat();
      _secondaryController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  bool get _shouldAnimate {
    if (!widget.enableAnimation) return false;

    // Check device type
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile && !widget.enableOnMobile) return false;

    // Check for reduced motion preference
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) return false;

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated background layer
        if (_shouldAnimate)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _animationController,
                  _secondaryController,
                ]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _getPainter(),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),

        // Content layer
        widget.child,
      ],
    );
  }

  CustomPainter _getPainter() {
    final color = widget.color ?? AppColors.primaryGold;

    switch (widget.type) {
      case AnimationType.particles:
        return ParticlesPainter(
          particles: particles,
          progress: _animationController.value,
          color: color.withOpacity(widget.opacity),
        );

      case AnimationType.waves:
        return WavesPainter(
          progress: _animationController.value,
          color: color.withOpacity(widget.opacity),
        );

      case AnimationType.gradient:
        return GradientPainter(
          progress: _animationController.value,
          rotation: _secondaryController.value,
          color: color.withOpacity(widget.opacity),
        );

      case AnimationType.bubbles:
        return BubblesPainter(
          bubbles: particles,
          progress: _animationController.value,
          color: color.withOpacity(widget.opacity),
        );

      case AnimationType.geometric:
        return GeometricPainter(
          progress: _animationController.value,
          rotation: _secondaryController.value,
          color: color.withOpacity(widget.opacity),
        );
    }
  }
}

// Animation Types
enum AnimationType {
  particles,
  waves,
  gradient,
  bubbles,
  geometric,
}

// Particle Model
class AnimatedParticle {
  Offset position;
  final double size;
  final double speed;
  final double amplitude;

  AnimatedParticle({
    required this.position,
    required this.size,
    required this.speed,
    this.amplitude = 10,
  });

  factory AnimatedParticle.random(AnimationType type) {
    final random = math.Random();
    return AnimatedParticle(
      position: Offset(
        random.nextDouble(),
        random.nextDouble(),
      ),
      size: type == AnimationType.bubbles
          ? random.nextDouble() * 15 + 5
          : random.nextDouble() * 4 + 2,
      speed: random.nextDouble() * 0.02 + 0.01,
      amplitude: random.nextDouble() * 20 + 10,
    );
  }

  void update(double progress) {
    position = Offset(
      position.dx,
      (position.dy + speed) % 1.0,
    );
  }
}

// ============= PAINTERS =============

// 1. Particles Painter
class ParticlesPainter extends CustomPainter {
  final List<AnimatedParticle> particles;
  final double progress;
  final Color color;

  ParticlesPainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Test kodlarını silin, gerçek particle kodu:

    final paint = Paint()
      ..color = color // Opacity zaten color'da var
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var particle in particles) {
      particle.update(progress);

      final x = particle.position.dx * size.width;
      final y = particle.position.dy * size.height;

      // Wave motion ekle
      final waveX =
          x + math.sin(progress * 2 * math.pi + y / 100) * particle.amplitude;

      // BOYUTU ARTIR - particle.size çok küçüktü
      canvas.drawCircle(
        Offset(waveX, y),
        particle.size * 5, // 5 ile çarp, daha büyük olsun
        paint,
      );
      canvas.drawCircle(Offset(waveX, y), particle.size * 5, borderPaint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

// 2. Waves Painter
class WavesPainter extends CustomPainter {
  final double progress;
  final Color color;

  WavesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = 50;
    final waveCount = 3;

    for (int i = 0; i < waveCount; i++) {
      path.reset();

      final phaseShift = i * math.pi / waveCount;
      final opacity = (1.0 - i / waveCount) * 0.3;
      paint.color = color.withOpacity(color.opacity * opacity);

      path.moveTo(0, size.height * 0.75);

      for (double x = 0; x <= size.width; x++) {
        final y = size.height * 0.75 +
            math.sin((x / size.width * 2 * math.pi) +
                    (progress * 2 * math.pi) +
                    phaseShift) *
                waveHeight;
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WavesPainter oldDelegate) => true;
}

// 3. Gradient Painter
class GradientPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final Color color;

  GradientPainter({
    required this.progress,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 300));

    // Draw multiple gradient circles
    for (int i = 0; i < 3; i++) {
      final angle = i * 2 * math.pi / 3;
      final offset = Offset(
        math.cos(angle) * 150,
        math.sin(angle) * 150,
      );
      canvas.drawCircle(offset, 200, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(GradientPainter oldDelegate) => true;
}

// 4. Bubbles Painter
class BubblesPainter extends CustomPainter {
  final List<AnimatedParticle> bubbles;
  final double progress;
  final Color color;

  BubblesPainter({
    required this.bubbles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      bubble.update(progress);

      final x = bubble.position.dx * size.width;
      final y = bubble.position.dy * size.height;

      // Bubble effect with gradient
      paint.shader = RadialGradient(
        colors: [
          color.withOpacity(color.opacity * 0.3),
          color.withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(x, y),
        radius: bubble.size,
      ));

      canvas.drawCircle(Offset(x, y), bubble.size, paint);

      // Inner highlight
      paint.shader = null;
      paint.color = Colors.white.withOpacity(0.2);
      canvas.drawCircle(
        Offset(x - bubble.size * 0.3, y - bubble.size * 0.3),
        bubble.size * 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BubblesPainter oldDelegate) => true;
}

// 5. Geometric Painter
class GeometricPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final Color color;

  GeometricPainter({
    required this.progress,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * 2 * math.pi);

    // Draw geometric patterns
    for (int i = 0; i < 6; i++) {
      final radius = 50.0 + i * 30;
      final opacity = (1.0 - i / 6) * 0.5;
      paint.color = color.withOpacity(color.opacity * opacity);

      // Hexagon
      final path = Path();
      for (int j = 0; j < 6; j++) {
        final angle = j * math.pi / 3;
        final point = Offset(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        );
        if (j == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(GeometricPainter oldDelegate) => true;
}
