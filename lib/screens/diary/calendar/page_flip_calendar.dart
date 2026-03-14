import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class _PageFlipRecognizer extends OneSequenceGestureRecognizer {
  void Function(PointerDownEvent)? onDown;
  void Function(PointerMoveEvent)? onMove;
  void Function(PointerUpEvent)? onUp;
  void Function(PointerCancelEvent)? onCancel;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onDown?.call(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onMove?.call(event);
    } else if (event is PointerUpEvent) {
      onUp?.call(event);
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      onCancel?.call(event);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'pageFlip';
}

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

  double get _minSize => _size.width / 5;

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
      setState(() => _touchPoint = _animTouchPoint.value);
    });
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // ✅ Sirf tab update karo jab animation naturally complete ho
        if (!_isDragging) {
          setState(() {
            _currentDate = _nextDate;
            _touchPoint = const Offset(0.01, 0.01);
          });
          widget.onDateChanged(_currentDate);
        }
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool _canDragOver() {
    return (_touchPoint - Offset(_cornerX, _cornerY)).distance > _minSize;
  }

  bool _isDragOverMinSize(double newX) {
    return _dragToRight
        ? (newX - _initialTouchX) > _minSize
        : (_initialTouchX - newX) > _minSize;
  }

  void _startFlipAnimation() {
    final dx = _cornerX > 0
        ? -(_size.width + _touchPoint.dx)
        : _size.width - _touchPoint.dx + _size.width;
    final dy = _cornerY > 0
        ? _size.height - _touchPoint.dy
        : 1 - _touchPoint.dy;

    _animTouchPoint =
        Tween<Offset>(
          begin: _touchPoint,
          end: Offset(_touchPoint.dx + dx, _touchPoint.dy + dy),
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward(from: 0);
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_animController.isAnimating) {
      _animController.stop();
      _currentDate = _nextDate;
      widget.onDateChanged(_currentDate);
    } else {
      _animController.stop();
    }

    _isCalendarUpdated = false;
    _isDragging = false;

    // ✅ Charon corners — top-left, top-right, bottom-left, bottom-right
    final corners = [
      Offset(0, 0),
      Offset(_size.width, 0),
      Offset(0, _size.height),
      Offset(_size.width, _size.height),
    ];
    final nearest = corners.reduce(
      (a, b) => (a - e.localPosition).distance < (b - e.localPosition).distance
          ? a
          : b,
    );

    _cornerX = nearest.dx;
    _cornerY = nearest.dy;
    _isRTandLB =
        (_cornerX == 0 && _cornerY == _size.height) ||
        (_cornerX == _size.width && _cornerY == 0);
    _dragToRight = _cornerX == 0;
    _nextDate = _currentDate;
    _touchPoint = nearest;
    _initialTouchX = nearest.dx;

    setState(() {});
  }

  void _onPointerMove(PointerMoveEvent e) {
    final x = e.localPosition.dx.clamp(10.0, _size.width - 10);
    final y = e.localPosition.dy.clamp(10.0, _size.height - 10);
    final movedDist = (e.localPosition - Offset(_cornerX, _cornerY)).distance;

    if (!_isDragging && movedDist > 12) {
      _isDragging = true;
    }

    if (!_isDragging) return;

    if (_isDragOverMinSize(e.localPosition.dx) && !_isCalendarUpdated) {
      _nextDate = _dragToRight
          ? _currentDate.subtract(const Duration(days: 1))
          : _currentDate.add(const Duration(days: 1));
      _isCalendarUpdated = true;
    }
    final corner = Offset(_cornerX, _cornerY);
    Offset newPoint = Offset(x, y);

    double maxDist = _size.width * 0.8;

    final dist = (newPoint - corner).distance;

    if (dist > maxDist) {
      final dir = (newPoint - corner) / dist;
      newPoint = corner + dir * maxDist;
    }

    setState(() {
      _touchPoint = newPoint;
    });
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_canDragOver() && _isCalendarUpdated) {
      _startFlipAnimation();
    } else {
      setState(() {
        _isDragging = false;
        _touchPoint = Offset(_cornerX - 0.09, _cornerY - 0.09);
      });
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    setState(() {
      _isDragging = false;
      _touchPoint = const Offset(0.01, 0.01);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);

        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            _PageFlipRecognizer:
                GestureRecognizerFactoryWithHandlers<_PageFlipRecognizer>(
                  () => _PageFlipRecognizer(),
                  (instance) {
                    instance.onDown = _onPointerDown;
                    instance.onMove = _onPointerMove;
                    instance.onUp = _onPointerUp;
                    instance.onCancel = _onPointerCancel;
                  },
                ),
          },
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
          color: themeColor,
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
          color: themeColor,
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
          color: themeColor.withOpacity(0.7),
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
          color: themeColor.withOpacity(0.3),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    p.paint(canvas, Offset(cx - p.width / 2, cy - p.height / 2));
  }

  @override
  bool shouldRepaint(_PageFlipPainter old) =>
      old.touchPoint != touchPoint ||
      old.currentDate != currentDate ||
      old.nextDate != nextDate ||
      old.isDragging != isDragging;
}
