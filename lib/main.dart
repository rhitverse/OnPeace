import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_peace/colors.dart';
import 'package:on_peace/common/utils/navigator_key.dart';
import 'package:on_peace/core/providers/theme_provider.dart';
import 'package:on_peace/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:on_peace/features/app/splash/splash_screen.dart';
import 'package:on_peace/screens/calls/screen/incoming_call_overlay.dart';
import 'package:on_peace/screens/calls/service/zego_engine_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      await ZegoEngineService().initializeZego();

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
    final themeMode = ref.watch(appThemeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OnPeace',
      navigatorKey: navigatorKey,
      themeMode: themeMode,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return IncomingCallOverlay(child: child);
      },
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
    );
  }
}
