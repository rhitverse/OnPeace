import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/colors.dart';
import 'package:whatsapp_clone/common/utils/navigator_key.dart';
import 'package:whatsapp_clone/core/providers/theme_provider.dart';
import 'package:whatsapp_clone/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whatsapp_clone/features/app/splash/splash_screen.dart';

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
    final themeMode = ref.watch(appThemeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whatsapp Clone',
      navigatorKey: navigatorKey,
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
    );
  }
}
