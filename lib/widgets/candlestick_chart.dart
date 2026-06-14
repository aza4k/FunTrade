import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/candlestick.dart';
import '../core/constants/colors.dart';
import '../core/utils/formatter.dart';

class CandlestickChart extends StatelessWidget {
  final List<Candlestick> candles;
  final double currentPrice;

  const CandlestickChart({
    super.key,
    required this.candles,
    required this.currentPrice,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const CupertinoActivityIndicator(radius: 12, color: AppColors.primary),
      );
    }

    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 12, 65, 20), // Leave right padding for prices, bottom for dates
      child: CustomPaint(
        painter: _CandlestickPainter(candles, currentPrice),
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<Candlestick> candles;
  final double currentPrice;

  _CandlestickPainter(this.candles, this.currentPrice);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    if (candles.length < 2) return;

    // 1. Calculate price range
    double minVal = candles[0].low;
    double maxVal = candles[0].high;
    for (var candle in candles) {
      if (candle.low < minVal) minVal = candle.low;
      if (candle.high > maxVal) maxVal = candle.high;
    }

    double range = maxVal - minVal;
    if (range == 0) range = 1.0;
    
    // Add 8% padding to top/bottom of chart
    final pad = range * 0.08;
    minVal -= pad;
    maxVal += pad;
    range = maxVal - minVal;

    final double widthStep = width / candles.length;
    final double candleWidth = widthStep * 0.7; // 70% of space is candle body, 30% gap

    // 2. Draw Horizontal Gridlines (4 levels)
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final textStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 9,
      fontFamily: '.SF Pro Text',
    );

    for (int i = 0; i <= 4; i++) {
      final yGrid = height * (i / 4.0);
      final priceValue = maxVal - (i / 4.0) * range;

      // Draw dashed line
      _drawDashedLine(canvas, 0, width, yGrid, gridPaint);

      // Draw price labels on the right (off canvas space)
      final textSpan = TextSpan(
        text: AppFormatter.formatCurrency(priceValue),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(width + 6, yGrid - 6));
    }

    // 3. Draw Candlesticks
    final Paint wickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Paint bodyPaint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final x = (i * widthStep) + (widthStep / 2); // Center of candle slot

      final yHigh = height - ((candle.high - minVal) / range * height);
      final yLow = height - ((candle.low - minVal) / range * height);
      final yOpen = height - ((candle.open - minVal) / range * height);
      final yClose = height - ((candle.close - minVal) / range * height);

      final isUp = candle.close >= candle.open;
      final Color color = isUp ? AppColors.profit : AppColors.loss;

      wickPaint.color = color;
      bodyPaint.color = color;

      // Draw Wick (High to Low line)
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

      // Draw Body (Open to Close box)
      final double top = yOpen < yClose ? yOpen : yClose;
      final double bottom = yOpen < yClose ? yClose : yOpen;
      
      // Ensure body has at least 1px height
      double bodyHeight = bottom - top;
      if (bodyHeight < 1.5) bodyHeight = 1.5;

      final Rect bodyRect = Rect.fromLTWH(
        x - (candleWidth / 2),
        top,
        candleWidth,
        bodyHeight,
      );
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)),
        bodyPaint,
      );

      // 4. Draw Time Axis Labels (draw 4 stamps at 0%, 33%, 66%, 100%)
      if (i % (candles.length ~/ 4 + 1) == 0 || i == candles.length - 1) {
        final timeFormatter = DateFormat('HH:mm');
        final timeText = timeFormatter.format(candle.time);
        
        final timeSpan = TextSpan(text: timeText, style: textStyle);
        final timePainter = TextPainter(
          text: timeSpan,
          textDirection: ui.TextDirection.ltr,
        );
        timePainter.layout();
        timePainter.paint(canvas, Offset(x - 12, height + 6));
      }
    }

    // 5. Draw spot price dashed marker & badge
    final currentY = height - ((currentPrice - minVal) / range * height);
    if (currentY >= 0 && currentY <= height) {
      final markerColor = currentPrice >= candles.last.open ? AppColors.profit : AppColors.loss;

      final markerPaint = Paint()
        ..color = markerColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      _drawDashedLine(canvas, 0, width, currentY, markerPaint);

      // Price bubble on the right
      final badgePaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      final RRect badgeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(width + 4, currentY - 9, 62, 18),
        const Radius.circular(4),
      );
      canvas.drawRRect(badgeRRect, badgePaint);

      final textSpan = TextSpan(
        text: AppFormatter.formatCurrency(currentPrice),
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(width + 8, currentY - 5.5));
    }

    // 6. Draw Info Card (Top-Left overlay values)
    final boxPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final Rect infoRect = Rect.fromLTWH(4, 4, 115, 38);
    canvas.drawRect(infoRect, boxPaint);
    canvas.drawRect(infoRect, borderPaint);

    final infoStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 7.5,
      fontWeight: FontWeight.w500,
    );
    final valStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 8,
      fontWeight: FontWeight.bold,
    );

    // Row 1: Max
    _drawInfoText(canvas, 'Max:', AppFormatter.formatCurrency(maxVal - pad), infoStyle, valStyle, Offset(8, 8));
    // Row 2: Min
    _drawInfoText(canvas, 'Min:', AppFormatter.formatCurrency(minVal + pad), infoStyle, valStyle, Offset(8, 18));
    // Row 3: Range
    _drawInfoText(canvas, 'Range:', AppFormatter.formatCurrency((maxVal - pad) - (minVal + pad)), infoStyle, valStyle, Offset(8, 28));
  }

  void _drawInfoText(Canvas canvas, String label, String val, TextStyle lblStyle, TextStyle vStyle, Offset offset) {
    final lblSpan = TextSpan(text: '$label ', style: lblStyle);
    final valSpan = TextSpan(text: val, style: vStyle);
    final painter = TextPainter(
      text: TextSpan(children: [lblSpan, valSpan]),
      textDirection: ui.TextDirection.ltr,
    );
    painter.layout();
    painter.paint(canvas, offset);
  }

  void _drawDashedLine(Canvas canvas, double startX, double endX, double y, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double currentX = startX;
    while (currentX < endX) {
      canvas.drawLine(
        Offset(currentX, y),
        Offset(currentX + dashWidth, y),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles || oldDelegate.currentPrice != currentPrice;
  }
}
