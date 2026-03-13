import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class PageFlipCalendar extends StatefulWidget {
  final DateTime initialDate;
  final void Function(DateTime) onDateChanged;

  const PageFlipCalendar({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
  });

  @override
  State<PageFlipCalendar> createState() => _PageFlipCalendarState();
}

class _PageFlipCalendarState extends State<PageFlipCalendar>
    with TickerProviderStateMixin {
  late DateTime _currentDate;
  late DateTime _nextDate;

  Offset _touchPoint = const Offset(0.01, 0.01);
  double _cornerX = 0;
  double _cornerY = 0;
  double _initialTouchX = 0;
  bool _isRTandLB = false;
  bool _isDragging = false;
  bool _isCalendarUpdated = false;
  bool _dragToRight = false;

  late AnimationController _animController;
  late Animation<Offset> _animTouchPoint;

  Size _size = Size.zero;

  double get _minSize => _size.width / 10;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _nextDate = widget.initialDate;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.addListener(() {
      setState(() {
        _touchPoint = _animTouchPoint.value;
      });
    });
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentDate = _nextDate;
          _isDragging = false;
          _touchPoint = Offset(0.01, 0.01);
        });
        widget.onDateChanged(_currentDate);
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _calcCornerXY(Offset pos) {
    _cornerX = pos.dx <= _size.width / 2 ? 0 : _size.width;
    _cornerY = pos.dy <= _size.height / 2 ? 0 : _size.height;
    _isRTandLB =
        (_cornerX == 0 && _cornerY == _size.height) ||
        (_cornerX == _size.width && _cornerY == 0);
  }

  bool _canDragOver() {
    final dist = (_touchPoint - Offset(_cornerX, _cornerY)).distance;
    return dist > _minSize;
  }

  bool _isDragOverMinSize(double newX) {
    if (_dragToRight) {
      return (newX - _initialTouchX) > _minSize;
    } else {
      return (_initialTouchX - newX) > _minSize;
    }
  }

  void _startAnimation() {
    double dx, dy;
    if (_cornerX > 0) {
      dx = -(_size.width + _touchPoint.dx);
    } else {
      dx = _size.width - _touchPoint.dx + _size.width;
    }
    if (_cornerY > 0) {
      dy = _size.height - _touchPoint.dy;
    } else {
      dy = 1 - _touchPoint.dy;
    }

    final endPoint = Offset(_touchPoint.dx + dx, _touchPoint.dy + dy);

    _animTouchPoint = Tween<Offset>(begin: _touchPoint, end: endPoint).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _animController.forward(from: 0);
  }

  void _onPanStart(DragStartDetails d) {
    _animController.stop();
    _isCalendarUpdated = false;
    _isDragging = true;
    _calcCornerXY(d.localPosition);
    _dragToRight = _cornerX == 0;
    _touchPoint = d.localPosition;
    _initialTouchX = d.localPosition.dx;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_isDragOverMinSize(d.localPosition.dx) && !_isCalendarUpdated) {
      _nextDate = _dragToRight
          ? _currentDate.subtract(const Duration(days: 1))
          : _currentDate.add(const Duration(days: 1));
      _isCalendarUpdated = true;
    }
    setState(() {
      _touchPoint = d.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails d) {
    if (_canDragOver() && _isCalendarUpdated) {
      _startAnimation();
    } else {
      setState(() {
        _isDragging = false;
        _touchPoint = Offset(_cornerX - 0.09, _cornerY - 0.09);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight * 0.7);

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: CustomPaint(
              painter: _PageFlipPainter(
                size: _size,
                currentDate: _currentDate,
                nextDate: _nextDate,
                touchPoint: _touchPoint,
                cornerX: _cornerX,
                cornerY: _cornerY,
                isRTandLB: _isRTandLB,
                isDragging: _isDragging,
                themeColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageFlipPainter extends CustomPainter {
  final Size size;
  final DateTime currentDate;
  final DateTime nextDate;
  final Offset touchPoint;
  final double cornerX;
  final double cornerY;
  final bool isRTandLB;
  final bool isDragging;
  final Color themeColor;

  _PageFlipPainter({
    required this.size,
    required this.currentDate,
    required this.nextDate,
    required this.touchPoint,
    required this.cornerX,
    required this.cornerY,
    required this.isRTandLB,
    required this.isDragging,
    required this.themeColor,
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
    double bs1y = cornerY;

    Offset touch = touchPoint;

    if (touch.dx > 0 && touch.dx < size.width) {
      if (bs1x < 0 || bs1x > size.width) {
        if (bs1x < 0) bs1x = size.width - bs1x;

        double f1 = (cornerX - touch.dx).abs();
        double f2 = size.width * f1 / bs1x;
        double newTouchX = (cornerX - f2).abs();

        double f3 =
            (cornerX - newTouchX).abs() * (cornerY - touch.dy).abs() / f1;
        double newTouchY = (cornerY - f3).abs();
        touch = Offset(newTouchX, newTouchY);

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
    double a1 = (p2.dy - p1.dy) / (p2.dx - p1.dx);
    double b1 = (p1.dx * p2.dy - p2.dx * p1.dy) / (p1.dx - p2.dx);
    double a2 = (p4.dy - p3.dy) / (p4.dx - p3.dx);
    double b2 = (p3.dx * p4.dy - p4.dx * p3.dy) / (p3.dx - p4.dx);
    double x = (b2 - b1) / (a1 - a2);
    double y = a1 * x + b1;
    return Offset(x, y);
  }

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
    final diffPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height)),
      path0,
    );
    canvas.clipPath(diffPath);
    _drawDatePage(canvas, currentDate, canvasSize);
    canvas.restore();

    final path1 = Path()
      ..moveTo(_bezierStart1.dx, _bezierStart1.dy)
      ..lineTo(_bezierVertex1.dx, _bezierVertex1.dy)
      ..lineTo(_bezierVertex2.dx, _bezierVertex2.dy)
      ..lineTo(_bezierStart2.dx, _bezierStart2.dy)
      ..lineTo(cornerX, cornerY)
      ..close();

    final nextPageRegion = Path.combine(PathOperation.intersect, path0, path1);
    canvas.save();
    canvas.clipPath(nextPageRegion);
    _drawDatePage(canvas, nextDate, canvasSize);
    _drawBackShadow(canvas);
    canvas.restore();

    _drawCurrentBackArea(canvas, canvasSize, path0, path1);

    _drawCurrentPageShadow(canvas, path0);
  }

  void _drawDatePage(Canvas canvas, DateTime date, Size canvasSize) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawRect(rect, Paint()..color = Colors.white);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final dayStr = DateFormat('d').format(date);
    final datePaint = TextPainter(
      text: TextSpan(
        text: dayStr,
        style: TextStyle(
          fontSize: size.width * 0.28,
          fontWeight: FontWeight.bold,
          color: themeColor,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    datePaint.paint(
      canvas,
      Offset(centerX - datePaint.width / 2, centerY - datePaint.height / 2),
    );

    final monthStr = DateFormat('MMMM yyyy').format(date);
    final monthPaint = TextPainter(
      text: TextSpan(
        text: monthStr,
        style: TextStyle(
          fontSize: size.width * 0.055,
          color: themeColor,
          letterSpacing: 2,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    monthPaint.paint(
      canvas,
      Offset(
        centerX - monthPaint.width / 2,
        centerY - datePaint.height / 2 - monthPaint.height - 8,
      ),
    );

    final dayNameStr = DateFormat('EEEE').format(date).toUpperCase();
    final dayNamePaint = TextPainter(
      text: TextSpan(
        text: dayNameStr,
        style: TextStyle(
          fontSize: size.width * 0.04,
          color: themeColor.withOpacity(0.7),
          letterSpacing: 3,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    dayNamePaint.paint(
      canvas,
      Offset(
        centerX - dayNamePaint.width / 2,
        centerY + datePaint.height / 2 + 12,
      ),
    );
  }

  void _drawBackShadow(Canvas canvas) {
    final shadowPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [Colors.black54, Colors.transparent],
            begin: isRTandLB ? Alignment.centerLeft : Alignment.centerRight,
            end: isRTandLB ? Alignment.centerRight : Alignment.centerLeft,
          ).createShader(
            Rect.fromLTWH(
              _bezierStart1.dx - _touchToCornerDist / 4,
              _bezierStart1.dy,
              _touchToCornerDist / 4,
              size.height,
            ),
          );

    canvas.drawRect(
      Rect.fromLTWH(
        isRTandLB
            ? _bezierStart1.dx
            : _bezierStart1.dx - _touchToCornerDist / 4,
        _bezierStart1.dy,
        _touchToCornerDist / 4,
        size.height,
      ),
      shadowPaint,
    );
  }

  void _drawCurrentPageShadow(Canvas canvas, Path path0) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        path0,
      ),
    );

    final edgePath = Path()
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
      );

    canvas.drawPath(edgePath, shadowPaint);
    canvas.restore();
  }

  void _drawCurrentBackArea(
    Canvas canvas,
    Size canvasSize,
    Path path0,
    Path path1,
  ) {
    final backPath = Path()
      ..moveTo(_bezierVertex2.dx, _bezierVertex2.dy)
      ..lineTo(_bezierVertex1.dx, _bezierVertex1.dy)
      ..lineTo(_bezierEnd1.dx, _bezierEnd1.dy)
      ..lineTo(touchPoint.dx, touchPoint.dy)
      ..lineTo(_bezierEnd2.dx, _bezierEnd2.dy)
      ..close();

    final backRegion = Path.combine(PathOperation.intersect, path0, backPath);

    canvas.save();
    canvas.clipPath(backRegion);

    final dis = sqrt(
      pow(cornerX - _bezierControl1.dx, 2) +
          pow(_bezierControl2.dy - cornerY, 2),
    );
    final f8 = (cornerX - _bezierControl1.dx) / dis;
    final f9 = (_bezierControl2.dy - cornerY) / dis;

    final matrix = Matrix4.identity()
      ..translate(_bezierControl1.dx, _bezierControl1.dy)
      ..storage[0] = 1 - 2 * f9 * f9
      ..storage[1] = 2 * f8 * f9
      ..storage[4] = 2 * f8 * f9
      ..storage[5] = 1 - 2 * f8 * f8
      ..translate(-_bezierControl1.dx, -_bezierControl1.dy);

    final backPaint = Paint()
      ..colorFilter = ColorFilter.matrix([
        0.55,
        0,
        0,
        0,
        80,
        0,
        0.55,
        0,
        0,
        80,
        0,
        0,
        0.55,
        0,
        80,
        0,
        0,
        0,
        0.2,
        0,
      ]);

    canvas.transform(matrix.storage);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      Paint()..color = Colors.white,
    );
    _drawDatePageFaded(canvas, currentDate, canvasSize, backPaint);
    canvas.restore();

    final f1 =
        ((_bezierStart1.dx + _bezierControl1.dx) / 2 - _bezierControl1.dx)
            .abs();
    final f2 =
        ((_bezierStart2.dy + _bezierControl2.dy) / 2 - _bezierControl2.dy)
            .abs();
    final f3 = min(f1, f2);

    canvas.save();
    canvas.clipPath(backRegion);

    final left = isRTandLB ? _bezierStart1.dx - 1 : _bezierStart1.dx - f3 - 1;
    final right = isRTandLB ? _bezierStart1.dx + f3 + 1 : _bezierStart1.dx + 1;

    final foldShadow = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.7),
            ],
            begin: isRTandLB ? Alignment.centerRight : Alignment.centerLeft,
            end: isRTandLB ? Alignment.centerLeft : Alignment.centerRight,
          ).createShader(
            Rect.fromLTWH(left, _bezierStart1.dy, right - left, size.height),
          );

    canvas.drawRect(
      Rect.fromLTWH(left, _bezierStart1.dy, right - left, size.height),
      foldShadow,
    );
    canvas.restore();
  }

  void _drawDatePageFaded(
    Canvas canvas,
    DateTime date,
    Size canvasSize,
    Paint basePaint,
  ) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    final dayStr = DateFormat('d').format(date);
    final datePaint = TextPainter(
      text: TextSpan(
        text: dayStr,
        style: TextStyle(
          fontSize: size.width * 0.28,
          fontWeight: FontWeight.bold,
          color: themeColor.withOpacity(0.3),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    datePaint.paint(
      canvas,
      Offset(centerX - datePaint.width / 2, centerY - datePaint.height / 2),
    );
  }

  @override
  bool shouldRepaint(_PageFlipPainter oldDelegate) {
    return oldDelegate.touchPoint != touchPoint ||
        oldDelegate.currentDate != currentDate ||
        oldDelegate.nextDate != nextDate ||
        oldDelegate.isDragging != isDragging;
  }
}
