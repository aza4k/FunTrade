import 'package:flutter/cupertino.dart';
import '../core/constants/colors.dart';

class SparklineChart extends StatelessWidget {
  final List<double> history;

  const SparklineChart({
    super.key,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return const SizedBox(width: 75, height: 32);
    }

    final isUp = history.last >= history.first;
    final color = isUp ? AppColors.profit : AppColors.loss;

    return SizedBox(
      width: 75,
      height: 32,
      child: CustomPaint(
        painter: _SparklinePainter(history, color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> history;
  final Color color;

  _SparklinePainter(this.history, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Find min and max values in the price history
    double minVal = history[0];
    double maxVal = history[0];
    for (var val in history) {
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }

    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;
    final double widthStep = size.width / (history.length - 1);

    final path = Path();
    for (int i = 0; i < history.length; i++) {
      final x = i * widthStep;
      // Invert Y coordinate since Canvas Y grows downwards
      final y = size.height - ((history[i] - minVal) / range * (size.height - 4)) - 2;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.history != history || oldDelegate.color != color;
  }
}
