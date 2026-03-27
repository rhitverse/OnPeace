import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/common/utils/navigator_key.dart';
import 'package:whatsapp_clone/core/providers/theme_provider.dart';
import 'package:whatsapp_clone/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whatsapp_clone/features/app/splash/splash_screen.dart';
import 'package:whatsapp_clone/screens/calls/screen/incoming_call_overlay.dart';
import 'package:whatsapp_clone/screens/calls/service/zego_engine_service.dart';

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
      title: 'Whatsapp Clone',
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
