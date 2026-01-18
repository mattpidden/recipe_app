import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundColour,
      body: SafeArea(
        child: Column(
          children: [
            const Text(
              "Profile Page",
              style: TextStyles.hugeTitle,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
