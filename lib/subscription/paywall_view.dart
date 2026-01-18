import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class ContentView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaywallView(
        onDismiss: () {
          // Dismiss the paywall, e.g. remove the view, navigate to another screen.
        },
      ),
    );
  }
}
