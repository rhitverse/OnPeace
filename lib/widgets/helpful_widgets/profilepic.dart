import 'dart:io';

import 'package:flutter/material.dart';

Widget profileAvatar({required double radius, File? image, String? photoUrl}) {
  if (image != null) {
    return CircleAvatar(radius: radius, backgroundImage: FileImage(image));
  }

  if (photoUrl != null && photoUrl.isNotEmpty) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(photoUrl),
    );
  }

  return CircleAvatar(
    radius: radius,
    backgroundImage: const NetworkImage(
      'https://yt3.ggpht.com/a/default-user=s600-k-no-rp-mo',
    ),
  );
}
