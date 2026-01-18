import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/firebase_options.dart';
import 'package:recipe_app/main_page.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/subscription/initalize.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  analytics.logAppOpen();
  //initializeRevenueCat();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Notifier(),
      child: MaterialApp(
        title: "Made",
        debugShowCheckedModeBanner: false,
        home: const MainPage(),
      ),
    );
  }
}
