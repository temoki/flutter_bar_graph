import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class BarGraphWidget extends StatefulWidget {
  const BarGraphWidget({super.key});

  @override
  State<BarGraphWidget> createState() => _BarGraphState();
}

class _BarGraphState extends State<BarGraphWidget>
    with SingleTickerProviderStateMixin {
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
            values: [1480, 700, 900, 1300, 400, 1200, 1300, 450],
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
    final barBottomY = size.height - 24.0;

    final maxValue = values.reduce(math.max);

    // 目盛り数字を描画する
    final yScaleInterval = _calcScaleInterval(maxValue) ?? maxValue;
    final yScaleCount = (maxValue / yScaleInterval).ceil();
    final yScaleLabelFormatter = intl.NumberFormat("#,###");
    var yRightOffset = 0.0;
    var yTopOffset = 0.0;
    for (var i = 0; i <= yScaleCount; i++) {
      final scaleLabelValue = yScaleInterval * i;
      final textPainter = TextPainter(
        text: TextSpan(
          text: yScaleLabelFormatter.format(scaleLabelValue),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      if (i == yScaleCount) {
        yTopOffset = math.max(yTopOffset, textPainter.height * 0.5);
      }
      yRightOffset = math.max(yRightOffset, textPainter.width);
      final x = size.width - textPainter.width;
      final y = barBottomY - (scaleLabelValue / maxValue) * barBottomY;
      textPainter.paint(
        canvas,
        Offset(x, y - textPainter.height * 0.5),
      );
    }

    final yScaleMax = yScaleInterval * yScaleCount;
    const yRightMargin = 6.0;
    final unitWidth =
        (size.width - (yRightMargin + yRightOffset)) / values.length;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final barWidth = unitWidth * 0.25;
      final barHeight =
          (value / yScaleMax) * (barBottomY - yTopOffset) * animationValue;
      canvas.save();
      canvas.translate(i * unitWidth + unitWidth * 0.5, 0);

      canvas.drawRect(
        Rect.fromLTWH(-barWidth * 0.5, yTopOffset + barBottomY - barHeight,
            barWidth, barHeight),
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width * 0.5, size.height - textPainter.height),
      );

      _drawDashedVerticalLine(
        canvas,
        unitWidth * 0.5,
        size.height,
        0,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
        2,
        2,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  // 破線を描画する
  void _drawDashedVerticalLine(
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

  // 桁数を求める
  int _calcDigit(int value) {
    return value > 0
        ? math.pow(10, math.log(value) ~/ math.log(10)).toInt()
        : 0;
  }

// 最大値からグラフの目盛り間隔を求める
// @see https://ameblo.jp/hiromi-0505/entry-12580621059.html
  int? _calcScaleInterval(int maxValue) {
    final digit = _calcDigit(maxValue);
    if (digit > 0) {
      const radixList = <int>[1, 2, 5, 10, 20];
      for (var i = 0; i < radixList.length - 1; i++) {
        final radix = radixList[i];
        if ((maxValue / digit) / radix < 1.0) {
          return radixList[i + 1] * digit ~/ 10;
        }
      }
    }
    return null;
  }
}
