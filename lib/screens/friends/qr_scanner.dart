import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/screens/friends/my_qr_code_tab.dart';
import 'package:on_peace/screens/friends/scan_qr_tab.dart';
import 'package:on_peace/screens/friends/qr_bottom_nav.dart';
import 'package:photo_manager/photo_manager.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  Uint8List? recentImage;

  final GlobalKey<ScanQrTabState> _scanQrKey = GlobalKey<ScanQrTabState>();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    loadRecentImage();
  }

  Future<void> loadRecentImage() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return;

    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return;

    final assets = await albums.first.getAssetListPaged(page: 0, size: 1);
    if (assets.isEmpty) return;

    final thumb = await assets.first.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
    );

    if (mounted) {
      setState(() => recentImage = thumb);
    }
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          TabBarView(
            controller: tabController,
            children: [
              ScanQrTab(key: _scanQrKey),
              const MyQrCodeTab(),
            ],
          ),

          QrBottomNav(controller: tabController),

          Positioned(
            top: 50,
            left: 15,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: whiteColor, size: 26),
            ),
          ),

          Positioned(
            bottom: 190,
            right: 20,
            child: GestureDetector(
              onTap: () {
                tabController.animateTo(0);
                _scanQrKey.currentState?.pickFromGallery();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black38,
                ),
                child: recentImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          recentImage!,
                          fit: BoxFit.cover,
                          width: 48,
                          height: 48,
                        ),
                      )
                    : const Icon(Icons.photo, color: whiteColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
