import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io';

Future<void> initializeRevenueCat() async {
  // Platform-specific API keys
  String apiKey;
  if (Platform.isIOS) {
    apiKey =
        (kDebugMode
            ? dotenv.env['RC_TEST_KEY']
            : dotenv.env['RC_REAL_APPLE_KEY']) ??
        "";
  } else if (Platform.isAndroid) {
    apiKey = dotenv.env['RC_TEST_KEY'] ?? "";
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}
