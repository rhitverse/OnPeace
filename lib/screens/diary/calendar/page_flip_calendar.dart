import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:on_peace/screens/diary/calendar/page_flip_painter.dart';

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
              painter: PageFlipPainter(
                size: _size,
                currentDate: _currentDate,
                nextDate: _nextDate,
                touchPoint: _touchPoint,
                cornerX: _cornerX,
                cornerY: _cornerY,
                isRTandLB: _isRTandLB,
                isDragging: _isDragging,
              ),
            ),
          ),
        );
      },
    );
  }
}
