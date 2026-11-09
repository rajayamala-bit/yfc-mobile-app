import 'dart:math';
import 'package:flutter/material.dart';

class BubbleParticle {
  double x;
  double y;
  double radius;
  double speed;
  double theta;
  double oscillationSpeed;
  Color color;

  BubbleParticle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.theta,
    required this.oscillationSpeed,
    required this.color,
  });
}

class FloatingBubblesBackground extends StatefulWidget {
  final Widget? child;

  const FloatingBubblesBackground({super.key, this.child});

  @override
  State<FloatingBubblesBackground> createState() => _FloatingBubblesBackgroundState();
}

class _FloatingBubblesBackgroundState extends State<FloatingBubblesBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<BubbleParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 15 Floating translucent rose-pink and gold orbs
    final colors = [
      const Color(0xFFFFD1DC).withValues(alpha: 0.28), // Soft Light Pink
      const Color(0xFFFFC0CB).withValues(alpha: 0.25), // Rose Pink
      const Color(0xFFFFB6C1).withValues(alpha: 0.22), // Light Rose
      const Color(0xFFFFE4E1).withValues(alpha: 0.30), // Misty Rose
      const Color(0xFFD4AF37).withValues(alpha: 0.16), // Translucent Metallic Gold
    ];

    for (int i = 0; i < 15; i++) {
      _particles.add(
        BubbleParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          radius: 15 + _random.nextDouble() * 35, // 15px - 50px
          speed: 0.0003 + _random.nextDouble() * 0.0007,
          theta: _random.nextDouble() * 2 * pi,
          oscillationSpeed: 0.02 + _random.nextDouble() * 0.03,
          color: colors[i % colors.length],
        ),
      );
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.y -= p.speed;
            p.theta += p.oscillationSpeed;
            p.x += sin(p.theta) * 0.0008;

            // Reset when drifting past top of screen
            if (p.y < -0.1) {
              p.y = 1.1;
              p.x = _random.nextDouble();
            }
          }
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B0E14) : const Color(0xFFFFFDFD);

    return Stack(
      children: [
        // Backdrop & Particle Layer
        Container(
          color: bgColor,
          child: CustomPaint(
            painter: _BubblesPainter(_particles),
            child: const SizedBox.expand(),
          ),
        ),

        // Scrollable Card & Content Layer
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final List<BubbleParticle> particles;

  _BubblesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final center = Offset(p.x * size.width, p.y * size.height);
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(center, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) => true;
}
