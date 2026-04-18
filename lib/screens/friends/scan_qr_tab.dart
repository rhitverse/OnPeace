import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:on_peace/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:on_peace/screens/chat/widget/profile/view_profile_screen.dart';
import 'package:on_peace/screens/chat/widget/profile/view_profile_unknown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:on_peace/widgets/helpful_widgets/info_popup.dart';

class ScanQrTab extends StatefulWidget {
  const ScanQrTab({super.key});

  @override
  ScanQrTabState createState() => ScanQrTabState();
}

class ScanQrTabState extends State<ScanQrTab> {
  bool isScanned = false;
  final MobileScannerController _controller = MobileScannerController();
  Future<DocumentSnapshot?> _resolveUser(String scannedValue) async {
    final byUid = await FirebaseFirestore.instance
        .collection('users')
        .doc(scannedValue)
        .get();

    if (byUid.exists) return byUid;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('qrData', isEqualTo: scannedValue)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) return query.docs.first;

    return null;
  }

  Future<void> pickFromGallery() => _pickFromGallery();

  Future<void> _pickFromGallery() async {
    await _controller.stop();

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked == null) {
      await _controller.start();
      return;
    }

    final result = await _controller.analyzeImage(picked.path);

    if (result == null || result.barcodes.isEmpty) {
      _showSnack("No QR code found in image.");
      await _controller.start();
      return;
    }

    final raw = result.barcodes.first.rawValue;
    if (raw != null) _handleScan(raw);
  }

  Future<void> _handleScan(String code) async {
    if (isScanned) return;
    setState(() => isScanned = true);

    debugPrint("🟡 Scan started: $code");

    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final userDoc = await _resolveUser(code);
      debugPrint("🟡 User found: ${userDoc != null}");

      if (userDoc == null) {
        _showSnack("Invalid QR code — user not found.");
        if (mounted) setState(() => isScanned = false);
        await _controller.start();
        return;
      }

      final resolvedUid = userDoc.id;
      final userData = userDoc.data() as Map<String, dynamic>;
      final profilePic = userData['profilePic'] ?? '';
      final displayName = userData['displayname'] ?? '';

      if (resolvedUid == currentUid) {
        _showSnack("That's your own QR code!");
        if (mounted) setState(() => isScanned = false);
        await _controller.start();
        return;
      }

      final friendDoc = await FirebaseFirestore.instance
          .collection('Friends')
          .doc('${currentUid}_$resolvedUid')
          .get();

      final friendDoc2 = await FirebaseFirestore.instance
          .collection('Friends')
          .doc('${resolvedUid}_$currentUid')
          .get();

      final isFriend = friendDoc.exists || friendDoc2.exists;

      if (!mounted) return;
      await _controller.stop();

      debugPrint("🟡 Navigating... isFriend: $isFriend");

      final route = isFriend
          ? MaterialPageRoute(
              builder: (_) => ViewProfileScreen(
                receiverUid: resolvedUid,
                receiverDisplayName: displayName,
                receiverProfilePic: profilePic,
              ),
            )
          : MaterialPageRoute(
              builder: (_) => ViewProfileUnknown(
                receiverUid: resolvedUid,
                receiverDisplayName: displayName,
                receiverProfilePic: profilePic,
              ),
            );

      Navigator.of(context).pushReplacement(route);
    } catch (e) {
      debugPrint("🔥 Error: $e");
      final msg = e is TimeoutException
          ? "Connection timeout. Check your internet."
          : "Something went wrong. Please try again.";
      _showSnack(msg);
      if (mounted) {
        setState(() => isScanned = false);
        await _controller.start();
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    InfoPopup.show(context, message);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double boxWidth = 285;
    const double boxHeight = 270;
    const double verticalOffset = -102;

    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final raw = capture.barcodes.firstOrNull?.rawValue;
            if (raw != null) _handleScan(raw);
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
          child: SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: Stack(
              children: [
                _scanCorner(top: true, left: true),
                _scanCorner(top: true, left: false),
                _scanCorner(top: false, left: true),
                _scanCorner(top: false, left: false),
              ],
            ),
          ),
        ),

        Align(
          alignment: const Alignment(0, 0.85),
          child: GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, color: whiteColor),
                  SizedBox(width: 8),
                  Text(
                    "Choose from Gallery",
                    style: TextStyle(color: whiteColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (isScanned)
          Align(
            alignment: const Alignment(0, -0.05),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: whiteColor,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Looking For user…",
                    style: TextStyle(color: whiteColor, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _scanCorner({required bool top, required bool left}) {
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

  const ScannerOverlayPainter({
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

    overlayPath
      ..addRRect(boxRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
