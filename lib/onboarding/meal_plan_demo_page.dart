import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/plannedmeal.dart';
import 'package:recipe_app/main_page.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/plan_page.dart';
import 'package:recipe_app/pages/recipe_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class MealPlanDemoPage extends StatefulWidget {
  const MealPlanDemoPage({super.key});

  @override
  State<MealPlanDemoPage> createState() => _MealPlanDemoPageState();
}

class _MealPlanDemoPageState extends State<MealPlanDemoPage> {
  int interactions = 0;
  final GlobalKey _dayKey = GlobalKey();
  final GlobalKey _reasonKey = GlobalKey();
  final GlobalKey _acceptKey = GlobalKey();
  final GlobalKey _deleteKey = GlobalKey();
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  String _fmtDayHeader(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]}';
  }

  String _fmtWeekday(DateTime d) {
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return w[d.weekday - 1];
  }

  Future<void> _pickRecipeAndAddForDay(
    BuildContext context,
    DateTime day,
  ) async {
    final notifier = context.read<Notifier>();

    if (notifier.recipes.isEmpty) return;

    final pickedRecipeId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return RecipePickerSheet(recipes: notifier.recipes);
      },
    );

    if (pickedRecipeId == null) return;

    await notifier.addPlannedDinnerForDay(day: day, recipeId: pickedRecipeId);
    addInteraction();
  }

  void _showTutorial() {
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "day",
        keyTarget: _dayKey,
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        radius: 10,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "This is one day of your meal plan. Meals are automatically added to your plan based your ratings, cooking patterns, and preferences, but you can also drag and drop recipes to change the day.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "reason",
        keyTarget: _reasonKey,
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        radius: 10,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "This is the reason why this recipe was added to your plan, as determined by the smart planning algorithm.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "accept",
        keyTarget: _acceptKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        enableOverlayTab: true,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "Tap here to accept this recipe suggestion and confirm its inclusion in your meal plan.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "delete",
        keyTarget: _deleteKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        enableOverlayTab: true,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "Tap here to delete this recipe from your meal plan. You can then manually add your own recipe. Now try adjusting your meal plan, adding and removing recipes.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      hideSkip: true,
      pulseEnable: true,
      opacityShadow: 0.9,
      pulseAnimationDuration: Duration(seconds: 1),
    ).show(context: context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  void addInteraction() {
    interactions++;
    if (interactions >= 3 && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        final today = _dateOnly(DateTime.now());
        final days = List.generate(30, (i) => today.add(Duration(days: i)));

        // Group planned meals by day (date-only)
        final byDay = <DateTime, List<dynamic>>{};
        for (final pm in notifier.plannedMeals) {
          final day = _dateOnly(pm.day);
          (byDay[day] ??= []).add(pm);
        }
        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'All Recipes',
                    style: TextStyles.hugeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 12,
                        left: 12,
                        right: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Builder(
                              builder: (context) {
                                final d = days[0];
                                final meals = (byDay[d] ?? [])
                                  ..sort((a, b) {
                                    // if you have a sortIndex/createdAt, use that.
                                    // fallback: stable
                                    return 0;
                                  });

                                final isToday = d == today;
                                return DragTarget(
                                  onWillAcceptWithDetails: (_) => true,
                                  onAcceptWithDetails:
                                      (
                                        DragTargetDetails<String> details,
                                      ) async {
                                        addInteraction();
                                        await notifier.movePlannedMeal(
                                          details.data,
                                          d,
                                        );
                                      },
                                  builder: (context, candidate, rejected) {
                                    final isHovering = candidate.isNotEmpty;

                                    return Container(
                                      key: _dayKey,
                                      decoration: BoxDecoration(
                                        color: isHovering
                                            ? AppColors.backgroundColour
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${_fmtWeekday(d)} • ${_fmtDayHeader(d)}',
                                                style: TextStyles.bodyTextBold,
                                              ),
                                              if (isToday) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.accentColour1,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Today',
                                                    style: TextStyles
                                                        .bodyTextBoldSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),

                                          if (meals.isEmpty)
                                            EmptyDayRow(
                                              onAdd: () =>
                                                  _pickRecipeAndAddForDay(
                                                    context,
                                                    d,
                                                  ),
                                            )
                                          else
                                            Column(
                                              children: meals.map((pm) {
                                                final idx = notifier.recipes
                                                    .indexWhere(
                                                      (r) =>
                                                          r.id == pm.recipeId,
                                                    );
                                                if (idx == -1)
                                                  return const SizedBox.shrink();
                                                final recipe =
                                                    notifier.recipes[idx];

                                                return InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            RecipePage(
                                                              id: recipe.id,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: LongPressDraggable<String>(
                                                    data: pm.id,
                                                    feedback: Material(
                                                      color: Colors.transparent,
                                                      child: SizedBox(
                                                        width: 260,
                                                        child: Opacity(
                                                          opacity: 0.95,
                                                          child: PlannedMealRow(
                                                            recipe: recipe,
                                                            reason: pm.reason,
                                                            status: pm.status,
                                                            onAccept: null,
                                                            onDelete: null,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    childWhenDragging: Opacity(
                                                      opacity: 0.35,
                                                      child: PlannedMealRow(
                                                        recipe: recipe,
                                                        reason: pm.reason,
                                                        status: pm.status,
                                                        onAccept: () {},
                                                        onDelete: () {},
                                                      ),
                                                    ),
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 8,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .backgroundColour,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                            child: Container(
                                                              width: 44,
                                                              height: 44,
                                                              color: AppColors
                                                                  .accentColour1,
                                                              child:
                                                                  (recipe
                                                                      .imageUrls
                                                                      .isEmpty)
                                                                  ? const Icon(
                                                                      Icons
                                                                          .restaurant,
                                                                      color: Colors
                                                                          .white,
                                                                      size: 18,
                                                                    )
                                                                  : Image.network(
                                                                      recipe
                                                                          .imageUrls
                                                                          .first,
                                                                      fit: BoxFit
                                                                          .cover,
                                                                    ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  recipe.title,
                                                                  style: TextStyles
                                                                      .smallHeading,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                if ((pm.reason ??
                                                                        '')
                                                                    .trim()
                                                                    .isNotEmpty)
                                                                  Text(
                                                                    key:
                                                                        _reasonKey,
                                                                    pm.reason!
                                                                        .trim(),
                                                                    style: TextStyles
                                                                        .bodyTextBoldAccent,
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),

                                                          if (pm.status ==
                                                              PlannedMealStatus
                                                                  .suggested)
                                                            GestureDetector(
                                                              key: _acceptKey,
                                                              onTap:
                                                                  pm.status ==
                                                                      PlannedMealStatus
                                                                          .suggested
                                                                  ? () {
                                                                      addInteraction();
                                                                      notifier
                                                                          .acceptPlannedMeal(
                                                                            pm.id,
                                                                          );
                                                                    }
                                                                  : null,
                                                              child: Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          6,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: AppColors
                                                                      .primaryColour,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  'Accept',
                                                                  style: TextStyles
                                                                      .bodyTextBoldSecondary,
                                                                ),
                                                              ),
                                                            )
                                                          else
                                                            Icon(
                                                              Icons
                                                                  .check_circle,
                                                              size: 18,
                                                              color: AppColors
                                                                  .primaryColour,
                                                            ),

                                                          const SizedBox(
                                                            width: 8,
                                                          ),

                                                          GestureDetector(
                                                            key: _deleteKey,
                                                            onTap: () {
                                                              addInteraction();
                                                              notifier
                                                                  .removePlannedMeal(
                                                                    pm.id,
                                                                  );
                                                            },
                                                            child: Icon(
                                                              Icons
                                                                  .delete_outline,
                                                              size: 20,
                                                              color: Colors
                                                                  .black
                                                                  .withAlpha(
                                                                    120,
                                                                  ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            ...List.generate(days.length - 1, (i) {
                              final d = days[i + 1];
                              final meals = (byDay[d] ?? [])
                                ..sort((a, b) {
                                  // if you have a sortIndex/createdAt, use that.
                                  // fallback: stable
                                  return 0;
                                });

                              final isToday = d == today;

                              return DragTarget(
                                onWillAcceptWithDetails: (_) => true,
                                onAcceptWithDetails:
                                    (DragTargetDetails<String> details) async {
                                      addInteraction();
                                      await notifier.movePlannedMeal(
                                        details.data,
                                        d,
                                      );
                                    },
                                builder: (context, candidate, rejected) {
                                  final isHovering = candidate.isNotEmpty;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: isHovering
                                          ? AppColors.backgroundColour
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${_fmtWeekday(d)} • ${_fmtDayHeader(d)}',
                                              style: TextStyles.bodyTextBold,
                                            ),
                                            if (isToday) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.accentColour1,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  'Today',
                                                  style: TextStyles
                                                      .bodyTextBoldSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        if (meals.isEmpty)
                                          EmptyDayRow(
                                            onAdd: () =>
                                                _pickRecipeAndAddForDay(
                                                  context,
                                                  d,
                                                ),
                                          )
                                        else
                                          Column(
                                            children: meals.map((pm) {
                                              final idx = notifier.recipes
                                                  .indexWhere(
                                                    (r) => r.id == pm.recipeId,
                                                  );
                                              if (idx == -1)
                                                return const SizedBox.shrink();
                                              final recipe =
                                                  notifier.recipes[idx];

                                              return InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          RecipePage(
                                                            id: recipe.id,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: LongPressDraggable<String>(
                                                  data: pm.id,
                                                  feedback: Material(
                                                    color: Colors.transparent,
                                                    child: SizedBox(
                                                      width: 260,
                                                      child: Opacity(
                                                        opacity: 0.95,
                                                        child: PlannedMealRow(
                                                          recipe: recipe,
                                                          reason: pm.reason,
                                                          status: pm.status,
                                                          onAccept: null,
                                                          onDelete: null,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  childWhenDragging: Opacity(
                                                    opacity: 0.35,
                                                    child: PlannedMealRow(
                                                      recipe: recipe,
                                                      reason: pm.reason,
                                                      status: pm.status,
                                                      onAccept: () {},
                                                      onDelete: () {},
                                                    ),
                                                  ),
                                                  child: PlannedMealRow(
                                                    recipe: recipe,
                                                    reason: pm.reason,
                                                    status: pm.status,
                                                    onAccept:
                                                        pm.status ==
                                                            PlannedMealStatus
                                                                .suggested
                                                        ? () {
                                                            addInteraction();
                                                            notifier
                                                                .acceptPlannedMeal(
                                                                  pm.id,
                                                                );
                                                          }
                                                        : null,
                                                    onDelete: () {
                                                      addInteraction();
                                                      notifier
                                                          .removePlannedMeal(
                                                            pm.id,
                                                          );
                                                    },
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
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
