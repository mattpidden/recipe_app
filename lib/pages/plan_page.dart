import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/plannedmeal.dart';
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
        return _RecipePickerSheet(recipes: notifier.recipes);
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
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _showList
                            ? () async {
                                await notifier.clearShoppingList();
                              }
                            : () async {
                                await notifier
                                    .convertPlanToShoppingListNext7Days();
                              },
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColour,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _showList ? 'Clear List' : 'Create List',
                              style: TextStyles.smallHeadingSecondary,
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_showList) ...[
                            // Meal plan card
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
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
                                                ? AppColors.backgroundColour
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '${_fmtWeekday(d)} • ${_fmtDayHeader(d)}',
                                                    style:
                                                        TextStyles.bodyTextBold,
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
                                              const SizedBox(height: 4),

                                              if (meals.isEmpty)
                                                _EmptyDayRow(
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
                                                              r.id ==
                                                              pm.recipeId,
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
                                                          color: Colors
                                                              .transparent,
                                                          child: SizedBox(
                                                            width: 260,
                                                            child: Opacity(
                                                              opacity: 0.95,
                                                              child:
                                                                  _PlannedMealRow(
                                                                    recipe:
                                                                        recipe,
                                                                    reason: pm
                                                                        .reason,
                                                                    status: pm
                                                                        .status,
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
                                                                  _PlannedMealRow(
                                                                    recipe:
                                                                        recipe,
                                                                    reason: pm
                                                                        .reason,
                                                                    status: pm
                                                                        .status,
                                                                    onAccept:
                                                                        () {},
                                                                    onDelete:
                                                                        () {},
                                                                  ),
                                                            ),
                                                        child: _PlannedMealRow(
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
                            ),
                          ] else ...[
                            // Shopping list placeholder (we’ll wire this next)
                            _ShoppingListCard(
                              items: notifier.shoppingListItems,
                              onToggle: notifier.toggleShoppingItem,
                            ),
                          ],

                          const SizedBox(height: 70),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
  const _PlanToggle({required this.showList, required this.onChanged});

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
                  child: Text('List', style: TextStyles.subheading),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayRow extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDayRow({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onAdd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundColour,
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

class _PlannedMealRow extends StatelessWidget {
  final dynamic recipe; // Recipe
  final String? reason;
  final PlannedMealStatus status;
  final VoidCallback? onAccept;
  final VoidCallback? onDelete;

  const _PlannedMealRow({
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
        color: AppColors.backgroundColour,
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

class _ShoppingListCard extends StatelessWidget {
  final List<dynamic> items; // List<ShoppingItem>
  final void Function(String id) onToggle;

  const _ShoppingListCard({required this.items, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        if (items.isEmpty) {
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
        for (final it in items) {
          (grouped[it.category] ??= []).add(it);
        }
        final cats = grouped.keys.toList()..sort();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...cats.map((cat) {
                final catItems = grouped[cat]!;
                // optional: sort unchecked first
                catItems.sort(
                  (a, b) => (a.checked == b.checked) ? 0 : (a.checked ? 1 : -1),
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat, style: TextStyles.bodyTextBold),
                      const SizedBox(height: 6),

                      ...catItems.map((it) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => onToggle(it.id),
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
                                children: [
                                  Icon(
                                    it.checked
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 20,
                                    color: it.checked
                                        ? AppColors.primaryColour
                                        : Colors.black.withAlpha(120),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      it.name,
                                      style: TextStyles.bodyTextPrimary,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      notifier.deleteFromShoppingList(it.id);
                                    },
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: Colors.black.withAlpha(120),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _RecipePickerSheet extends StatefulWidget {
  final List<dynamic> recipes; // List<Recipe>
  const _RecipePickerSheet({required this.recipes});

  @override
  State<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends State<_RecipePickerSheet> {
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
