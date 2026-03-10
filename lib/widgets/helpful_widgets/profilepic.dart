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
      'https://scontent-ssn1-1.cdninstagram.com/v/t51.2885-19/573323465_1219825463302212_7278921664109726296_n.png?stp=dst-jpg_e0_s150x150_tt6&efg=eyJ2ZW5jb2RlX3RhZyI6InByb2ZpbGVfcGljLmRqYW5nby4xNTAuYzIifQ&_nc_ht=scontent-ssn1-1.cdninstagram.com&_nc_cat=1&_nc_oc=Q6cZ2QH-D4ZS7uKSql_7HpxPaexdEIDjMMfhNvl9oU4gByxeIGsh_5gJXnszJMFR51u0JMs&_nc_ohc=2tyZ8HJj7tUQ7kNvwFR5mRI&_nc_gid=GRpEBnRVsBgnwu3BMSgGcQ&edm=AGqCYasBAAAA&ccb=7-5&ig_cache_key=YW5vbnltb3VzX3Byb2ZpbGVfcGlj.3-ccb7-5&oh=00_AfwDar6o1e1hMOGViptl34FG0-BsdSVP7vcySd3H1JcG6g&oe=69B5FAEA&_nc_sid=6c5dea',
    ),
  );
}
