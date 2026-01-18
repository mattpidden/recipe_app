import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

void presentPaywall() async {
  final paywallResult = await RevenueCatUI.presentPaywall();
}
