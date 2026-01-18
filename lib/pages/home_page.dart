import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundColour,
      body: SafeArea(
        child: Column(
          children: [
            const Text("Home Page", style: TextStyles.hugeTitle, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
