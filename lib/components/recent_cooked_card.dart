import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/cookevent.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/recent_cooked_page.dart';
import 'package:recipe_app/pages/recipe_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class RecentCookedCard extends StatelessWidget {
  final String? filterByRecipeID;
  const RecentCookedCard({super.key, this.filterByRecipeID});

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        List<CookEvent> events = [];
        if (filterByRecipeID != null) {
          events =
              notifier.cookHistory
                  .where((e) => e.recipeId == filterByRecipeID!)
                  .toList()
                ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
        } else {
          events = [...notifier.cookHistory]
            ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
        }

        final last3 = events.take(3).toList();

        if (last3.isEmpty) return const SizedBox.shrink();

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RecentCookedPage(filterByRecipeID: filterByRecipeID),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recently Cooked',
                        style: TextStyles.subheading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      "See All",
                      style: TextStyles.bodyTextBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primaryTextColour,
                      size: 15,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...List.generate(last3.length, (i) {
                  final e = last3[i];
                  Recipe? recipe;
                  for (final r in notifier.recipes) {
                    if (r.id == e.recipeId) {
                      recipe = r;
                      break;
                    }
                  }
                  if (recipe == null) {
                    return SizedBox.shrink();
                  }

                  final title = recipe.title;
                  final subtitleBits = <String>[
                    _fmtDate(e.cookedAt),
                    if ((e.occasion ?? '').trim().isNotEmpty)
                      e.occasion!.trim(),
                  ];

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == last3.length - 1 ? 0 : 8,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipePage(id: recipe!.id),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
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
                                width: 38,
                                height: 38,
                                color: AppColors.accentColour1,

                                child: recipe.imageUrls.isEmpty
                                    ? Icon(
                                        Icons.restaurant,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : Image.network(
                                        recipe.imageUrls.first,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyles.smallHeading,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    subtitleBits.join(' • '),
                                    style: TextStyles.bodyTextBoldAccent,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            StarsSmall(rating: e.rating),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StarsSmall extends StatelessWidget {
  final int rating; // 1..5
  const StarsSmall({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 16,
          color: filled ? AppColors.primaryColour : Colors.grey.withAlpha(120),
        );
      }),
    );
  }
}
