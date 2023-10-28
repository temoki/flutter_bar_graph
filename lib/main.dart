import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bar Graph',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomeState();
}

class _HomeState extends State<_HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _Painter(
            values: [1500, 700, 900, 1300, 400, 1200, 1300, 450],
            animationValue: _animation.value,
          ),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  const _Painter({
    required this.values,
    required this.animationValue,
  });

  final List<int> values;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.reduce(math.max);
    final unitWidth = size.width / values.length;

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final barWidth = unitWidth * 0.25;
      final barHeight = (value / maxValue) * size.height * animationValue;
      canvas.save();
      canvas.translate(i * unitWidth + unitWidth * 0.5, 0);

      canvas.drawRect(
        Rect.fromLTWH(
            -barWidth * 0.5, size.height - barHeight, barWidth, barHeight),
        Paint()
          ..color = const Color(0xFF5599A1)
          ..style = PaintingStyle.fill,
      );

      if (i != values.length - 1) {
        drawDashedVerticalLine(
          canvas,
          unitWidth * 0.5,
          size.height,
          0,
          Paint()
            ..color = Colors.grey
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
          2,
          2,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void drawDashedVerticalLine(
    Canvas canvas,
    double x,
    double y1,
    double y2,
    Paint paint,
    double dashLength,
    double spaceLength,
  ) {
    final totalLength = dashLength + spaceLength;
    var y = math.min(y1, y2);
    var ymax = math.max(y1, y2);
    while (y < ymax) {
      canvas.drawLine(
          Offset(x, y), Offset(x, math.min(y + dashLength, ymax)), paint);
      y += totalLength;
    }
  }
}
