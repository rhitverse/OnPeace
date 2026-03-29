import 'package:fluttertoast/fluttertoast.dart';
import 'package:on_peace/colors.dart';

void toast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 2,
    backgroundColor: backgroundColor,
    textColor: whiteColor,
    fontSize: 16.0,
  );
}
