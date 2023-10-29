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
            values: [1420, 1780, 700, 900, 1300, 400, 1200, 1300, 450, 900],
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
    final canvasRect = Rect.fromLTWH(0, 0, size.width, size.height);
    var graphAreaRect = Rect.fromLTRB(0, 0, 0, canvasRect.bottom - 24);

    // デバッグ用に描画エリアを塗りつぶす
    canvas.drawRect(
      canvasRect,
      Paint()..color = Colors.grey.withOpacity(0.1),
    );

    // Y軸の目盛りラベルを描画する
    final maxValue = values.reduce(math.max);
    final yScaleInterval = _calcScaleInterval(maxValue) ?? maxValue;
    final yScaleCount = (maxValue / yScaleInterval).ceil();
    final yScaleMaxValue = yScaleInterval * yScaleCount;
    final yScaleLabelFormatter = intl.NumberFormat("#,###");
    for (var i = yScaleCount; i >= 0; i--) {
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

      const yScaleLabelMargin = 6.0;
      if (i == yScaleCount) {
        graphAreaRect = graphAreaRect.copyWith(
          top: math.max(graphAreaRect.top, textPainter.height * 0.5),
          right: canvasRect.right - textPainter.width - yScaleLabelMargin,
        );
      }

      textPainter.paint(
          canvas,
          Offset(
            graphAreaRect.right + yScaleLabelMargin,
            graphAreaRect.height * (1 - scaleLabelValue / yScaleMaxValue),
          ));
    }

    // X軸の目盛りラベル・棒グラフを描画する
    final xItemWidth = graphAreaRect.width / values.length;
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final barWidth = xItemWidth * 0.25;
      final barHeight =
          (value / yScaleMaxValue) * graphAreaRect.height * animationValue;
      canvas.save();
      canvas.translate((i + 0.5) * xItemWidth, 0);

      // 棒グラフを描画する
      canvas.drawRect(
        Rect.fromLTWH(
          -barWidth * 0.5,
          graphAreaRect.bottom - barHeight,
          barWidth,
          barHeight,
        ),
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill,
      );

      // X軸ラベルを描画する
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
        Offset(
            -textPainter.width * 0.5, canvasRect.bottom - textPainter.height),
      );

      // 破線を描画する
      _drawDashedVerticalLine(
        canvas,
        xItemWidth * 0.5,
        graphAreaRect.top,
        canvasRect.bottom,
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
  bool shouldRepaint(CustomPainter oldDelegate) => true;

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

extension RectExt on Rect {
  Rect copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return Rect.fromLTRB(
      left ?? this.left,
      top ?? this.top,
      right ?? this.right,
      bottom ?? this.bottom,
    );
  }
}
