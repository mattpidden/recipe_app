import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/components/recent_cooks.dart';
import 'package:recipe_app/components/todays_planned_meal_card.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class HomePage extends StatefulWidget {
  final void Function() navToPlan;
  const HomePage({super.key, required this.navToPlan});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SingleChildScrollView(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Text(
                      "Home",
                      style: TextStyles.hugeTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TodaysPlannedMealCard(navToPlan: widget.navToPlan),
                  const SizedBox(height: 8),
                  RecentCookedCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
