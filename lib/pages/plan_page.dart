import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundColour,
      body: SafeArea(
        child: Column(
          children: [
            const Text("Plan Page", style: TextStyles.hugeTitle, maxLines: 2),
          ],
        ),
      ),
    );
  }
}
