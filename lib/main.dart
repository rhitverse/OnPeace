import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/utils/navigator_key.dart';
import 'package:on_peace/core/providers/theme_provider.dart';
import 'package:on_peace/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:on_peace/features/app/splash/splash_screen.dart';
import 'package:on_peace/screens/calls/controller/call_provider.dart';
import 'package:on_peace/screens/calls/screen/incoming_call_overlay.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      debugPrint('Caught unhandled error: $error');
    },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final themeMode = ref.watch(appThemeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'OnPeace',
      themeMode: themeMode,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: whiteColor,
          foregroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
      ),
      home: const SplashScreen(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox(),
            if (callState.incomingCall != null)
              const Positioned.fill(child: IncomingCallScreen()),
          ],
        );
      },
    );
  }
}
