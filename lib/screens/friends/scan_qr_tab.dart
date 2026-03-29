import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:on_peace/colors.dart';

class ScanQrTab extends StatefulWidget {
  const ScanQrTab({super.key});

  @override
  State<ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends State<ScanQrTab> {
  bool isScanned = false;

  @override
  Widget build(BuildContext context) {
    final double boxWidth = 285;
    final double boxHeight = 270;
    const double verticalOffset = -102;
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            if (!isScanned) {
              final code = capture.barcodes.first.rawValue;
              if (code != null) {
                setState(() => isScanned = true);
                debugPrint("Scanned Code: $code");
              }
            }
          },
        ),
        CustomPaint(
          size: Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height,
          ),
          painter: ScannerOverlayPainter(
            width: boxWidth,
            height: boxHeight,
            borderRadius: 20,
            verticalOffset: verticalOffset,
          ),
        ),
        Align(
          alignment: const Alignment(0, -0.3),
          child: Container(
            width: boxWidth,
            height: boxHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.transparent),
            ),
            child: Stack(
              children: [
                scanCorner(true, true),
                scanCorner(true, false),
                scanCorner(false, true),
                scanCorner(false, false),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget scanCorner(bool top, bool left) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: whiteColor, width: 4)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: whiteColor, width: 4)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: whiteColor, width: 4)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: whiteColor, width: 4)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top && left ? const Radius.circular(20) : Radius.zero,
            topRight: top && !left ? const Radius.circular(20) : Radius.zero,
            bottomLeft: !top && left ? const Radius.circular(20) : Radius.zero,
            bottomRight: !top && !left
                ? const Radius.circular(20)
                : Radius.zero,
          ),
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double width;
  final double height;
  final double borderRadius;
  final double verticalOffset;

  ScannerOverlayPainter({
    required this.width,
    required this.height,
    required this.verticalOffset,
    this.borderRadius = 20,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2 + verticalOffset);

    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      Radius.circular(borderRadius),
    );

    overlayPath.addRRect(boxRect);
    overlayPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
