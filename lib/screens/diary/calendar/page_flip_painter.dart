import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone/colors.dart';

class PageFlipPainter extends CustomPainter {
  final Size size;
  final DateTime currentDate;
  final DateTime nextDate;
  final Offset touchPoint;
  final double cornerX;
  final double cornerY;
  final bool isRTandLB;
  final bool isDragging;

  PageFlipPainter({
    required this.size,
    required this.currentDate,
    required this.nextDate,
    required this.touchPoint,
    required this.cornerX,
    required this.cornerY,
    required this.isRTandLB,
    required this.isDragging,
  });

  late Offset _bezierStart1, _bezierControl1, _bezierVertex1, _bezierEnd1;
  late Offset _bezierStart2, _bezierControl2, _bezierVertex2, _bezierEnd2;
  late double _touchToCornerDist;

  void _calcPoints() {
    double middleX = (touchPoint.dx + cornerX) / 2;
    double middleY = (touchPoint.dy + cornerY) / 2;

    double bc1x =
        middleX -
        (cornerY - middleY) * (cornerY - middleY) / (cornerX - middleX);
    double bc1y = cornerY;
    double bc2x = cornerX;
    double bc2y =
        middleY -
        (cornerX - middleX) * (cornerX - middleX) / (cornerY - middleY);

    _bezierControl1 = Offset(bc1x, bc1y);
    _bezierControl2 = Offset(bc2x, bc2y);

    double bs1x = bc1x - (cornerX - bc1x) / 2;
    final double bs1y = cornerY;

    Offset touch = touchPoint;

    if (touch.dx > 0 &&
        touch.dx < size.width &&
        (bs1x < 0 || bs1x > size.width)) {
      if (bs1x < 0) bs1x = size.width - bs1x;

      final f1 = (cornerX - touch.dx).abs();
      final f2 = size.width * f1 / bs1x;
      final newTouchX = (cornerX - f2).abs();
      final f3 = (cornerX - newTouchX).abs() * (cornerY - touch.dy).abs() / f1;
      touch = Offset(newTouchX, (cornerY - f3).abs());

      middleX = (touch.dx + cornerX) / 2;
      middleY = (touch.dy + cornerY) / 2;

      bc1x =
          middleX -
          (cornerY - middleY) * (cornerY - middleY) / (cornerX - middleX);
      bc1y = cornerY;
      bc2x = cornerX;
      bc2y =
          middleY -
          (cornerX - middleX) * (cornerX - middleX) / (cornerY - middleY);

      _bezierControl1 = Offset(bc1x, bc1y);
      _bezierControl2 = Offset(bc2x, bc2y);
      bs1x = bc1x - (cornerX - bc1x) / 2;
    }

    _bezierStart1 = Offset(bs1x, bs1y);
    _bezierStart2 = Offset(cornerX, bc2y - (cornerY - bc2y) / 2);
    _touchToCornerDist = (touch - Offset(cornerX, cornerY)).distance;

    _bezierEnd1 = _getCross(
      touch,
      _bezierControl1,
      _bezierStart1,
      _bezierStart2,
    );
    _bezierEnd2 = _getCross(
      touch,
      _bezierControl2,
      _bezierStart1,
      _bezierStart2,
    );

    _bezierVertex1 = Offset(
      (_bezierStart1.dx + 2 * _bezierControl1.dx + _bezierEnd1.dx) / 4,
      (2 * _bezierControl1.dy + _bezierStart1.dy + _bezierEnd1.dy) / 4,
    );
    _bezierVertex2 = Offset(
      (_bezierStart2.dx + 2 * _bezierControl2.dx + _bezierEnd2.dx) / 4,
      (2 * _bezierControl2.dy + _bezierStart2.dy + _bezierEnd2.dy) / 4,
    );
  }

  Offset _getCross(Offset p1, Offset p2, Offset p3, Offset p4) {
    final a1 = (p2.dy - p1.dy) / (p2.dx - p1.dx);
    final b1 = (p1.dx * p2.dy - p2.dx * p1.dy) / (p1.dx - p2.dx);
    final a2 = (p4.dy - p3.dy) / (p4.dx - p3.dx);
    final b2 = (p3.dx * p4.dy - p4.dx * p3.dy) / (p3.dx - p4.dx);
    final x = (b2 - b1) / (a1 - a2);
    return Offset(x, a1 * x + b1);
  }

  bool _isValidOffset(Offset o) => !o.dx.isNaN && !o.dy.isNaN;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = Colors.white,
    );
    _drawDatePage(canvas, currentDate, canvasSize);

    if (!isDragging) return;

    try {
      _calcPoints();
    } catch (_) {
      return;
    }

    if (!_isValidOffset(_bezierStart1) ||
        !_isValidOffset(_bezierStart2) ||
        !_isValidOffset(_bezierControl1) ||
        !_isValidOffset(_bezierControl2)) {
      return;
    }

    final path0 = Path()
      ..moveTo(_bezierStart1.dx, _bezierStart1.dy)
      ..quadraticBezierTo(
        _bezierControl1.dx,
        _bezierControl1.dy,
        _bezierEnd1.dx,
        _bezierEnd1.dy,
      )
      ..lineTo(touchPoint.dx, touchPoint.dy)
      ..lineTo(_bezierEnd2.dx, _bezierEnd2.dy)
      ..quadraticBezierTo(
        _bezierControl2.dx,
        _bezierControl2.dy,
        _bezierStart2.dx,
        _bezierStart2.dy,
      )
      ..lineTo(cornerX, cornerY)
      ..close();

    canvas.save();
    canvas.clipPath(path0, doAntiAlias: true);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = Colors.white,
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()
          ..addRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height)),
        path0,
      ),
    );
    _drawDatePage(canvas, currentDate, canvasSize);
    canvas.restore();

    final path1 = Path()
      ..moveTo(_bezierStart1.dx, _bezierStart1.dy)
      ..lineTo(_bezierVertex1.dx, _bezierVertex1.dy)
      ..lineTo(_bezierVertex2.dx, _bezierVertex2.dy)
      ..lineTo(_bezierStart2.dx, _bezierStart2.dy)
      ..lineTo(cornerX, cornerY)
      ..close();

    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.intersect, path0, path1));
    _drawDatePage(canvas, nextDate, canvasSize);
    _drawBackShadow(canvas);
    canvas.restore();

    _drawCurrentBackArea(canvas, canvasSize, path0, path1);
    _drawCurrentPageShadow(canvas, path0);
    _drawPageEdge(canvas);
  }

  void _drawDatePage(Canvas canvas, DateTime date, Size canvasSize) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = Colors.white,
    );

    final cx = canvasSize.width / 2;
    final cy = canvasSize.height / 2;

    final dayPainter = TextPainter(
      text: TextSpan(
        text: DateFormat('d').format(date),
        style: TextStyle(
          fontSize: canvasSize.width * 0.28,
          fontWeight: FontWeight.bold,
          color: calendarLightTheme1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    dayPainter.paint(
      canvas,
      Offset(cx - dayPainter.width / 2, cy - dayPainter.height / 2),
    );

    final monthPainter = TextPainter(
      text: TextSpan(
        text: DateFormat('MMMM yyyy').format(date),
        style: TextStyle(
          fontSize: canvasSize.width * 0.055,
          color: calendarLightTheme1,
          letterSpacing: 2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    monthPainter.paint(
      canvas,
      Offset(
        cx - monthPainter.width / 2,
        cy - dayPainter.height / 2 - monthPainter.height - 8,
      ),
    );

    final dayNamePainter = TextPainter(
      text: TextSpan(
        text: DateFormat('EEEE').format(date).toUpperCase(),
        style: TextStyle(
          fontSize: canvasSize.width * 0.04,
          color: calendarLightTheme1,
          letterSpacing: 3,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    dayNamePainter.paint(
      canvas,
      Offset(cx - dayNamePainter.width / 2, cy + dayPainter.height / 2 + 12),
    );
  }

  void _drawPageEdge(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(_bezierStart1.dx, _bezierStart1.dy)
        ..lineTo(_bezierVertex1.dx, _bezierVertex1.dy)
        ..lineTo(_bezierVertex2.dx, _bezierVertex2.dy)
        ..lineTo(_bezierStart2.dx, _bezierStart2.dy),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, Colors.grey.shade300, Colors.grey.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawBackShadow(Canvas canvas) {
    final rect = Rect.fromLTWH(
      isRTandLB ? _bezierStart1.dx : _bezierStart1.dx - _touchToCornerDist / 4,
      _bezierStart1.dy,
      _touchToCornerDist / 4,
      size.height,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.05),
          ],
          begin: isRTandLB ? Alignment.centerLeft : Alignment.centerRight,
          end: isRTandLB ? Alignment.centerRight : Alignment.centerLeft,
        ).createShader(rect),
    );
  }

  void _drawCurrentPageShadow(Canvas canvas, Path path0) {
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        path0,
      ),
    );
    canvas.drawPath(
      Path()
        ..moveTo(_bezierStart1.dx, _bezierStart1.dy)
        ..quadraticBezierTo(
          _bezierControl1.dx,
          _bezierControl1.dy,
          _bezierEnd1.dx,
          _bezierEnd1.dy,
        )
        ..lineTo(touchPoint.dx, touchPoint.dy)
        ..lineTo(_bezierEnd2.dx, _bezierEnd2.dy)
        ..quadraticBezierTo(
          _bezierControl2.dx,
          _bezierControl2.dy,
          _bezierStart2.dx,
          _bezierStart2.dy,
        ),
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.restore();
  }

  void _drawCurrentBackArea(
    Canvas canvas,
    Size canvasSize,
    Path path0,
    Path path1,
  ) {
    final backRegion = Path.combine(
      PathOperation.intersect,
      path0,
      Path()
        ..moveTo(_bezierVertex2.dx, _bezierVertex2.dy)
        ..lineTo(_bezierVertex1.dx, _bezierVertex1.dy)
        ..lineTo(_bezierEnd1.dx, _bezierEnd1.dy)
        ..lineTo(touchPoint.dx, touchPoint.dy)
        ..lineTo(_bezierEnd2.dx, _bezierEnd2.dy)
        ..close(),
    );

    canvas.save();
    canvas.clipPath(backRegion);

    final dis = sqrt(
      pow(cornerX - _bezierControl1.dx, 2) +
          pow(_bezierControl2.dy - cornerY, 2),
    );

    if (dis == 0 || dis.isNaN || dis.isInfinite) {
      canvas.restore();
      return;
    }

    final f8 = (cornerX - _bezierControl1.dx) / dis;
    final f9 = (_bezierControl2.dy - cornerY) / dis;

    canvas.transform(
      (Matrix4.identity()
            ..translate(_bezierControl1.dx, _bezierControl1.dy)
            ..storage[0] = 1 - 2 * f9 * f9
            ..storage[1] = 2 * f8 * f9
            ..storage[4] = 2 * f8 * f9
            ..storage[5] = 1 - 2 * f8 * f8
            ..translate(-_bezierControl1.dx, -_bezierControl1.dy))
          .storage,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = Colors.white,
    );
    _drawDatePageFaded(canvas, currentDate);
    canvas.restore();

    final f3 = min(
      ((_bezierStart1.dx + _bezierControl1.dx) / 2 - _bezierControl1.dx).abs(),
      ((_bezierStart2.dy + _bezierControl2.dy) / 2 - _bezierControl2.dy).abs(),
    );
    final left = isRTandLB ? _bezierStart1.dx - 1 : _bezierStart1.dx - f3 - 1;
    final right = isRTandLB ? _bezierStart1.dx + f3 + 1 : _bezierStart1.dx + 1;
    final rectWidth = right - left;

    if (rectWidth <= 0 || rectWidth.isNaN || _bezierStart1.dy.isNaN) return;

    canvas.save();
    canvas.clipPath(backRegion);
    final shadowRect = Rect.fromLTWH(
      left,
      _bezierStart1.dy,
      rectWidth,
      size.height,
    );
    canvas.drawRect(
      shadowRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.black.withOpacity(0.05),
            Colors.black.withOpacity(0.35),
          ],
          begin: isRTandLB ? Alignment.centerRight : Alignment.centerLeft,
          end: isRTandLB ? Alignment.centerLeft : Alignment.centerRight,
        ).createShader(shadowRect),
    );
    canvas.restore();
  }

  void _drawDatePageFaded(Canvas canvas, DateTime date) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final p = TextPainter(
      text: TextSpan(
        text: DateFormat('d').format(date),
        style: TextStyle(
          fontSize: size.width * 0.28,
          fontWeight: FontWeight.bold,
          color: calendarLightTheme1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    p.paint(canvas, Offset(cx - p.width / 2, cy - p.height / 2));
  }

  @override
  bool shouldRepaint(PageFlipPainter old) =>
      old.touchPoint != touchPoint ||
      old.currentDate != currentDate ||
      old.nextDate != nextDate ||
      old.isDragging != isDragging;
}
