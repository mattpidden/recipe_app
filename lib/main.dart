import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/firebase_options.dart';
import 'package:recipe_app/main_page.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/onboarding/onboarding_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/subscription/initalize.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  analytics.logAppOpen();
  await dotenv.load(fileName: ".env");
  initializeRevenueCat();
  final prefs = await SharedPreferences.getInstance();
  final showDemo = prefs.getBool("demo_done") ?? false;
  runApp(MainApp(showDemo: !showDemo));
}

class MainApp extends StatelessWidget {
  final bool showDemo;
  const MainApp({super.key, required this.showDemo});

  void setSharedPrefs() async {}

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Notifier(),
      child: MaterialApp(
        title: "Made",
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          );
        },
        theme: ThemeData(
          useMaterial3: true,

          // Global brand colours
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColour,
            primary: AppColors.primaryColour,
            secondary: AppColors.accentColour1,
          ),

          // Cursor + selection
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: AppColors.accentColour1,
            selectionColor: AppColors.accentColour1.withAlpha(35),
            selectionHandleColor: AppColors.accentColour1,
          ),

          // Progress indicators
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: AppColors.primaryColour,
          ),
        ),
        home: showDemo ? OnboardingPage() : MainPage(),
      ),
    );
  }
}
