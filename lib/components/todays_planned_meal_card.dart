import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/plannedmeal.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/cooking_page.dart';
import 'package:recipe_app/pages/recipe_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class TodaysPlannedMealCard extends StatelessWidget {
  final void Function() navToPlan;
  const TodaysPlannedMealCard({super.key, required this.navToPlan});

  String _outcomeLine(String title, int? mins) {
    final cleanTitle = title.trim().isEmpty ? 'something tasty' : title.trim();
    final m = mins ?? 30;

    final options = <String>[
      "You could be eating $cleanTitle in $m minutes",
      "Dinner solved: $cleanTitle in about $m minutes",
      "Future you says thanks — $cleanTitle in $m minutes",
      "Less thinking, more eating: $cleanTitle in $m minutes",
      "Tonight’s win: $cleanTitle on your plate in $m minutes",
      "Crush dinner in $m minutes: $cleanTitle",
    ];

    return options[DateTime.now().hour % options.length];
  }

  String _smallNudge({required bool hasRecipe, required bool hasPlan}) {
    if (!hasRecipe) return "Add a recipe to unlock auto-planning.";
    if (!hasPlan) return "No plan yet — pick something quick and start now.";
    return "Tap cook now and let the app guide you step-by-step.";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        final pm = notifier.plannedMealToday;

        final hasRecipe = notifier.recipes.isNotEmpty;
        if (!hasRecipe && pm == null) return const SizedBox.shrink();

        final recipe = (pm == null)
            ? null
            : notifier.recipes.where((r) => r.id == pm.recipeId).isEmpty
            ? null
            : notifier.recipes.firstWhere((r) => r.id == pm.recipeId);

        final title = recipe?.title ?? "Pick something to cook";
        final mins = recipe?.timeMinutes;

        // If we don’t have a recipe for today (no plan / deleted recipe), show a soft empty state
        if (recipe == null) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: AppColors.accentColour1,
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today",
                        style: TextStyles.subheading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _smallNudge(hasRecipe: hasRecipe, hasPlan: pm != null),
                        style: TextStyles.bodyTextBoldAccent,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColour,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: AppColors.primaryColour,
                  ),
                ),
              ],
            ),
          );
        }

        final outcome = _outcomeLine(title, mins);
        final statusLabel = pm!.status == PlannedMealStatus.committed
            ? "Planned for today"
            : "Suggested for today";

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Today",
                      style: TextStyles.subheading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      print("tapped");
                      navToPlan();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColour,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.primaryTextColour,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: TextStyles.bodyTextBoldAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Hero tile (same inner-tile style as your recent cooked rows)
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipePage(id: recipe.id),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColour,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppColors.accentColour1,
                          child: recipe.imageUrls.isEmpty
                              ? const Icon(
                                  Icons.restaurant,
                                  color: Colors.white,
                                  size: 22,
                                )
                              : Image.network(
                                  recipe.imageUrls.first,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outcome,
                              style: TextStyles.smallHeading,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (pm.reason ?? '').trim().isNotEmpty
                                  ? pm.reason!.trim()
                                  : "Open cooking mode and just follow along.",
                              style: TextStyles.bodyTextBoldAccent,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Actions row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CookingModePage(
                              recipeId: recipe.id,
                              scale: 1.0,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.accentColour1,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            "Cook Now",
                            style: TextStyles.smallHeadingSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipePage(id: recipe.id),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      width: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColour,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
