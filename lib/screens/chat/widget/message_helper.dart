bool isUri(String text) {
  final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
  return urlPattern.hasMatch(text);
}

String? extractUrl(String text) {
  final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);
  final match = urlPattern.firstMatch(text);
  return match?.group(0);
}
