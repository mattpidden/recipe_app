import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/cookevent.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/components/recent_cooked_card.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/recipe_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class RecentCookedPage extends StatefulWidget {
  final String? filterByRecipeID;
  const RecentCookedPage({super.key, this.filterByRecipeID});

  @override
  State<RecentCookedPage> createState() => _RecentCookedPageState();
}

class _RecentCookedPageState extends State<RecentCookedPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        List<CookEvent> events = [];
        if (widget.filterByRecipeID != null) {
          events =
              notifier.cookHistory
                  .where((e) => e.recipeId == widget.filterByRecipeID!)
                  .toList()
                ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
        } else {
          events = [...notifier.cookHistory]
            ..sort((a, b) => b.cookedAt.compareTo(a.cookedAt));
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundColour,

          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.primaryTextColour,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Recently Cooked',
                        style: TextStyles.pageTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(events.length, (i) {
                          final e = events[i];
                          final recipe = notifier.recipes.firstWhere(
                            (r) => r.id == e.recipeId,
                          );

                          return Padding(
                            padding: EdgeInsets.only(
                              top: i == 0 ? 4 : 0,
                              bottom: i == events.length - 1 ? 32 : 8,
                              left: 16,
                              right: 16,
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
                              child: DetailedRecentlyCookedCard(
                                e: e,
                                recipe: recipe,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DetailedRecentlyCookedCard extends StatelessWidget {
  final CookEvent e;
  final Recipe recipe;
  const DetailedRecentlyCookedCard({
    super.key,
    required this.e,
    required this.recipe,
  });

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  color: AppColors.accentColour1,

                  child: recipe.imageUrls.isEmpty
                      ? Icon(Icons.restaurant, color: Colors.white, size: 18)
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
                      recipe.title,
                      style: TextStyles.smallHeading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _fmtDate(e.cookedAt),
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
          const SizedBox(height: 2),
          if (e.wouldMakeAgain != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Icon(
                    e.wouldMakeAgain! == true ? Icons.check : Icons.close,
                    size: 14,
                    color: AppColors.primaryColour,
                  ),
                ),
                Text(
                  e.wouldMakeAgain! == true
                      ? "Would make again"
                      : "Would not make again",
                  style: TextStyles.bodyTextPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          if ((e.occasion ?? "").trim().isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Icon(
                    Icons.celebration,
                    size: 14,
                    color: AppColors.primaryColour,
                  ),
                ),
                Text(
                  e.occasion!,
                  style: TextStyles.bodyTextPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          if (e.withWho.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Icon(
                    Icons.people,
                    size: 14,
                    color: AppColors.primaryColour,
                  ),
                ),
                Text(
                  e.withWho
                      .map(
                        (p) => p.isNotEmpty
                            ? p[0].toUpperCase() + p.substring(1)
                            : p,
                      )
                      .join(', '),
                  style: TextStyles.bodyTextPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          if ((e.comment ?? "").trim().isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Icon(
                    Icons.comment,
                    size: 14,
                    color: AppColors.primaryColour,
                  ),
                ),
                Expanded(
                  child: Text(
                    e.comment!,
                    style: TextStyles.bodyTextPrimary,
                    maxLines: 100,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
