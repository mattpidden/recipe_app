import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/classes/plannedmeal.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/classes/unit_value.dart';
import 'package:recipe_app/components/ingredient_pill.dart';
import 'package:recipe_app/pages/recipe_page.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  bool _showList = false; // false = Meal Plan, true = Shopping List

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
    const w = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
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
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Text(
                    "Plan",
                    style: TextStyles.hugeTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Toggle + Auto-plan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PlanToggle(
                          showList: _showList,
                          onChanged: (v) => setState(() => _showList = v),
                          lengthOfList: notifier.shoppingListItems.length,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 44,
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await notifier.convertPlanToShoppingList();
                          },
                          child: Container(
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColour,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Create List from Plan',
                                style: TextStyles.smallHeadingSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await notifier.clearShoppingList();
                          },
                          child: Container(
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.accentColour1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Clear List',
                                style: TextStyles.smallHeadingSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_showList) ...[
                            // Meal plan card
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...List.generate(days.length, (i) {
                                  final d = days[i];
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
                                              ? Colors.white.withAlpha(170)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        left: 8,
                                                        top: 4,
                                                      ),
                                                  child: Text(
                                                    '${_fmtWeekday(d)} • ${_fmtDayHeader(d)}',
                                                    style:
                                                        TextStyles.smallHeading,
                                                  ),
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
                                                      color: AppColors
                                                          .accentColour1,
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
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
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
                                                        color:
                                                            Colors.transparent,
                                                        child: SizedBox(
                                                          width: 260,
                                                          child: Opacity(
                                                            opacity: 0.95,
                                                            child:
                                                                PlannedMealRow(
                                                                  recipe:
                                                                      recipe,
                                                                  reason:
                                                                      pm.reason,
                                                                  status:
                                                                      pm.status,
                                                                  onAccept:
                                                                      null,
                                                                  onDelete:
                                                                      null,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      childWhenDragging:
                                                          Opacity(
                                                            opacity: 0.35,
                                                            child:
                                                                PlannedMealRow(
                                                                  recipe:
                                                                      recipe,
                                                                  reason:
                                                                      pm.reason,
                                                                  status:
                                                                      pm.status,
                                                                  onAccept:
                                                                      () {},
                                                                  onDelete:
                                                                      () {},
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
                                                            ? () => notifier
                                                                  .acceptPlannedMeal(
                                                                    pm.id,
                                                                  )
                                                            : null,
                                                        onDelete: () => notifier
                                                            .removePlannedMeal(
                                                              pm.id,
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
                                }),
                              ],
                            ),
                          ] else ...[
                            // Shopping list placeholder (we’ll wire this next)
                            _ShoppingListCard(
                              items: notifier.shoppingListItems,
                              onToggle: notifier.toggleShoppingItem,
                            ),
                          ],

                          const SizedBox(height: 16 + 70 + 16),
                        ],
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

class _PlanToggle extends StatelessWidget {
  final bool showList;
  final ValueChanged<bool> onChanged;
  final int lengthOfList;
  const _PlanToggle({
    required this.showList,
    required this.onChanged,
    required this.lengthOfList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: showList
                      ? Colors.transparent
                      : AppColors.backgroundColour,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('Calendar', style: TextStyles.subheading),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: showList
                      ? AppColors.backgroundColour
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'List ($lengthOfList items)',
                    style: TextStyles.subheading,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyDayRow extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyDayRow({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 18, color: AppColors.primaryTextColour),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nothing planned — tap to add',
                style: TextStyles.bodyTextBoldAccent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlannedMealRow extends StatelessWidget {
  final dynamic recipe; // Recipe
  final String? reason;
  final PlannedMealStatus status;
  final VoidCallback? onAccept;
  final VoidCallback? onDelete;

  const PlannedMealRow({
    super.key,
    required this.recipe,
    required this.reason,
    required this.status,
    this.onAccept,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              child: (recipe.imageUrls?.isEmpty ?? true)
                  ? const Icon(Icons.restaurant, color: Colors.white, size: 18)
                  : Image.network(recipe.imageUrls.first, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title ?? 'Recipe',
                  style: TextStyles.smallHeading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((reason ?? '').trim().isNotEmpty)
                  Text(
                    reason!.trim(),
                    style: TextStyles.bodyTextBoldAccent,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          if (status == PlannedMealStatus.suggested && onAccept != null)
            GestureDetector(
              onTap: onAccept,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryColour,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Accept', style: TextStyles.bodyTextBoldSecondary),
              ),
            )
          else
            Icon(Icons.check_circle, size: 18, color: AppColors.primaryColour),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.black.withAlpha(120),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingListCard extends StatefulWidget {
  final List<dynamic> items; // List<ShoppingItem>
  final void Function(String id) onToggle;

  const _ShoppingListCard({required this.items, required this.onToggle});

  @override
  State<_ShoppingListCard> createState() => _ShoppingListCardState();
}

class _ShoppingListCardState extends State<_ShoppingListCard> {
  final Map<String, List<Ingredient>> _subsByIndex = {};
  bool _showRecipeOrigin = true;

  Future<void> handleSubs(String id, String recipe, String ingredient) async {
    try {
      final fn = FirebaseFunctions.instanceFor(
        region: 'europe-west2',
      ).httpsCallable('substituteIngredient');

      final res = await fn.call({'recipe': recipe, 'ingredient': ingredient});
      final rawList = List.from(res.data);
      final listOfSubs = rawList
          .map((e) => Ingredient.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _subsByIndex[id] = listOfSubs;
      });
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to find substitutes',
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
    } finally {}
  }

  void handleRemoveSubs(String index) {
    setState(() {
      _subsByIndex[index] = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        if (widget.items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
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
                        'Your Shopping List is Empty',
                        style: TextStyles.smallHeading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Create a list from your meal plan, or add items manually',
                  style: TextStyles.bodyTextPrimary,
                ),
              ],
            ),
          );
        }

        final grouped = <String, List<dynamic>>{};
        for (final it in widget.items) {
          (grouped[it.category] ??= []).add(it);
        }
        final cats = grouped.keys.toList()..sort();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _showRecipeOrigin = !_showRecipeOrigin),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _showRecipeOrigin
                          ? AppColors.primaryColour
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 14,
                          color: _showRecipeOrigin
                              ? AppColors.secondaryTextColour
                              : AppColors.primaryTextColour,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showRecipeOrigin ? 'Hide Recipe' : 'Show Recipe',
                          style: _showRecipeOrigin
                              ? TextStyles.bodyTextBoldSecondary
                              : TextStyles.bodyTextBold,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.primaryColour,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (_) {
                        Widget option(String label, UnitSystem mode) {
                          final selected = notifier.unitSystem == mode;
                          return ListTile(
                            title: Text(
                              label,
                              style: TextStyles.smallHeadingSecondary,
                            ),
                            trailing: selected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              notifier.updateUnitSystem(mode);
                            },
                          );
                        }

                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                option("Original", UnitSystem.original),
                                option("Metric", UnitSystem.metric),
                                option("Imperial", UnitSystem.imperial),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColour,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.balance,
                          size: 14,
                          color: AppColors.secondaryTextColour,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Convert (${viewModeLabel(notifier.unitSystem)})',
                          style: TextStyles.bodyTextBoldSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ...cats.map((cat) {
              final catItems = grouped[cat]!;
              // optional: sort unchecked first
              catItems.sort(
                (a, b) => (a.checked == b.checked) ? 0 : (a.checked ? 1 : -1),
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Text(cat, style: TextStyles.smallHeading),
                    ),

                    ...List.generate(catItems.length, (i) {
                      final it = catItems[i];
                      final displayIngred = displayIngredient(
                        it.ingredient,
                        notifier.unitSystem,
                        1,
                      );
                      Recipe? recipe;
                      for (final r in notifier.recipes) {
                        if (r.id == it.recipeId) {
                          recipe = r;
                          break;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => widget.onToggle(it.id),
                                child: ParsedIngredientPill(
                                  ingredient: displayIngred,
                                  showSubOption: true,
                                  onSub: () => handleSubs(
                                    it.id,
                                    recipe?.title ?? "",
                                    "${it.ingredient.quantity} ${it.ingredient.unit} ${it.ingredient.item}",
                                  ),
                                  removeSubs: () => handleRemoveSubs(it.id),
                                  subs: _subsByIndex[it.id] ?? const [],
                                  scale: 1,
                                  unitSystem: notifier.unitSystem,
                                  checked: it.checked,
                                  originRecipe: _showRecipeOrigin
                                      ? recipe?.title
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () =>
                                  notifier.deleteFromShoppingList(it.id),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  size: 16,
                                  Icons.delete_outline,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class RecipePickerSheet extends StatefulWidget {
  final List<dynamic> recipes; // List<Recipe>
  const RecipePickerSheet({required this.recipes});

  @override
  State<RecipePickerSheet> createState() => RecipePickerSheetState();
}

class RecipePickerSheetState extends State<RecipePickerSheet> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    final filtered =
        widget.recipes.where((r) {
          final title = (r.title ?? '').toString().toLowerCase();
          return title.contains(q.trim().toLowerCase());
        }).toList()..sort(
          (a, b) =>
              ((a.title ?? '') as String).compareTo((b.title ?? '') as String),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom, top: 100),
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundColour,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(15),
              topLeft: Radius.circular(15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryTextColour.withAlpha(40),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pick a recipe',
                      style: TextStyles.pageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: AppColors.primaryTextColour,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: TextField(
                    onChanged: (v) => setState(() => q = v),
                    style: TextStyles.inputedText,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey, size: 20),
                      hintText: 'Search',
                      hintStyle: TextStyles.inputText,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Flexible(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final r = filtered[i];

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.pop(context, r.id as String),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(bottom: 8),
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
                                child: (r.imageUrls?.isEmpty ?? true)
                                    ? const Icon(
                                        Icons.restaurant,
                                        color: Colors.white,
                                        size: 18,
                                      )
                                    : Image.network(
                                        r.imageUrls.first,
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
                                    r.title ?? 'Recipe',
                                    style: TextStyles.smallHeading,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    r.description ?? 'Recipe',
                                    style: TextStyles.bodyTextPrimary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.primaryTextColour,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
