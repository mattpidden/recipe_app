import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/recipe_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class RecentCookedCard extends StatelessWidget {
  const RecentCookedCard({super.key});

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
        final events = [...notifier.cookHistory]
          ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));

        final last5 = events.take(3).toList();

        if (last5.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                      'Recently cooked',
                      style: TextStyles.subheading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.history,
                    size: 18,
                    color: AppColors.primaryTextColour,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(last5.length, (i) {
                final e = last5[i];
                final recipe = notifier.recipes.firstWhere(
                  (r) => r.id == e.recipeId,
                );

                final title = recipe?.title ?? 'Recipe';
                final subtitleBits = <String>[
                  _fmtDate(e.cookedAt),
                  if ((e.occasion ?? '').trim().isNotEmpty) e.occasion!.trim(),
                ];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i == last5.length - 1 ? 0 : 8,
                  ),
                  child: InkWell(
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

                          _StarsSmall(rating: e.rating),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StarsSmall extends StatelessWidget {
  final int rating; // 1..5
  const _StarsSmall({required this.rating});

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
