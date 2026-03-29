import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:on_peace/colors.dart';

class ImageCropHelper {
  static Future<File?> cropProfilePic(File file) async {
    return _crop(
      file: file,
      ratio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      preset: CropAspectRatioPreset.square,
      title: 'Crop Profile Picture',
    );
  }

  static Future<File?> cropBanner(File file) async {
    return _crop(
      file: file,
      ratio: const CropAspectRatio(ratioX: 16, ratioY: 9),
      preset: CropAspectRatioPreset.ratio16x9,
      title: 'Crop Banner',
    );
  }

  static Future<File?> _crop({
    required File file,
    required CropAspectRatio ratio,
    required CropAspectRatioPreset preset,
    required String title,
  }) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: file.path,
      aspectRatio: ratio,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: backgroundColor,
          statusBarColor: backgroundColor,
          toolbarWidgetColor: whiteColor,
          activeControlsWidgetColor: uiColor,
          initAspectRatio: preset,
          lockAspectRatio: true,
          hideBottomControls: true,
          showCropGrid: true,
          cropGridRowCount: 3,
          cropGridColumnCount: 3,
          cropGridColor: whiteColor.withOpacity(0.55),
          cropGridStrokeWidth: 1,
          cropFrameColor: whiteColor,
          cropFrameStrokeWidth: 2,
          dimmedLayerColor: backgroundColor.withOpacity(0.82),
          backgroundColor: backgroundColor,
        ),
        IOSUiSettings(title: title, aspectRatioLockEnabled: true),
      ],
    );
    if (cropped == null) return null;
    return File(cropped.path);
  }
}
