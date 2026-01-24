import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/components/ingredient_pill.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class CookingModePage extends StatefulWidget {
  final String recipeId;
  const CookingModePage({super.key, required this.recipeId});

  @override
  State<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends State<CookingModePage> {
  late final PageController _controller;
  int _index = 0;
  final double _scale = 1.0;
  List<Ingredient> subs = [];
  final Map<String, List<Ingredient>> _subsByKey = {};
  @override
  void initState() {
    super.initState();
    _controller = PageController();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    super.dispose();
  }

  void _go(int i, int max) {
    final next = i.clamp(0, max - 1);
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> handleSubs(String key, String recipe, String ingredient) async {
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
      setState(() => _subsByKey[key] = listOfSubs);
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
    }
  }

  void handleRemoveSubs(String key) {
    setState(() => _subsByKey.remove(key));
  }

  // Very practical “good enough” extraction:
  // - try matching Ingredient.item words inside the step
  // - fallback to matching Ingredient.raw
  List<Ingredient> _ingredientsForStep(String step, List<Ingredient> all) {
    final s = step.toLowerCase();

    // words we don’t care about when matching
    const stopWords = {
      'fresh',
      'large',
      'small',
      'medium',
      'finely',
      'roughly',
      'chopped',
      'sliced',
      'diced',
      'minced',
      'ground',
      'crushed',
      'extra',
      'virgin',
      'optional',
    };

    List<String> normalise(String text) {
      return text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z\s]'), '')
          .split(' ')
          .where((w) => w.length > 2 && !stopWords.contains(w))
          .map(
            (w) => w.endsWith('s') ? w.substring(0, w.length - 1) : w,
          ) // plural → singular
          .toList();
    }

    final stepTokens = normalise(s);

    final hits = <Ingredient>[];

    for (final ing in all) {
      final base = ing.item?.isNotEmpty == true ? ing.item! : ing.raw;
      final ingTokens = normalise(base);

      if (ingTokens.isEmpty) continue;

      // match if *any* meaningful token appears in the step
      final match = ingTokens.any((t) => stepTokens.contains(t));

      if (match) hits.add(ing);
    }

    // de-dupe by raw text
    final seen = <String>{};
    return hits.where((i) => seen.add(i.raw.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, _) {
        final recipe = notifier.recipes.firstWhere(
          (r) => r.id == widget.recipeId,
        );

        final steps = recipe.steps.where((s) => s.trim().isNotEmpty).toList();
        final total = steps.isEmpty ? 1 : steps.length;

        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
            child: Column(
              children: [
                // Top bar (big + clean)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: AppColors.primaryTextColour,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: TextStyles.pageTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_index + 1}/$total',
                          style: TextStyles.bodyTextBoldAccent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Step pages
                Expanded(
                  child: steps.isEmpty
                      ? Center(
                          child: Text(
                            'No steps yet.',
                            style: TextStyles.subheading,
                          ),
                        )
                      : PageView.builder(
                          controller: _controller,
                          itemCount: steps.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (context, i) {
                            final step = steps[i];
                            final stepIngredients = _ingredientsForStep(
                              step,
                              recipe.ingredients,
                            );

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Ingredients for this step (top)
                                    if (stepIngredients.isNotEmpty) ...[
                                      Text(
                                        'You’ll need',
                                        style: TextStyles.subheading,
                                      ),
                                      const SizedBox(height: 10),
                                      Column(
                                        children: List.generate(
                                          stepIngredients.length,
                                          (ingredIndex) {
                                            final ingred =
                                                stepIngredients[ingredIndex];
                                            final subKey =
                                                '$i|${ingred.raw.toLowerCase()}';

                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 6,
                                              ),
                                              child: ParsedIngredientPill(
                                                ingredient: ingred,
                                                scale: _scale,
                                                showSubOption: true,
                                                onSub: () => handleSubs(
                                                  subKey,
                                                  recipe.title,
                                                  "${ingred.quantity ?? ''} ${ingred.unit ?? ''} ${ingred.item ?? ingred.raw}"
                                                      .trim(),
                                                ),
                                                removeSubs: () =>
                                                    handleRemoveSubs(subKey),
                                                subs:
                                                    _subsByKey[subKey] ??
                                                    const [],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ] else ...[
                                      const SizedBox(height: 4),
                                    ],

                                    // Step number + text (BIG)
                                    Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: AppColors.accentColour1,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${i + 1}',
                                              style: TextStyles
                                                  .smallHeadingSecondary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Step ${i + 1}',
                                            style: TextStyles.subheading,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          step,
                                          style: TextStyles.pageTitle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Bottom controls (kitchen friendly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _go(_index - 1, total),
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: _index <= 0
                                  ? AppColors.backgroundColour
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _index <= 0 ? "" : 'Back',
                                style: TextStyles.smallHeading,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_index >= steps.length - 1) {
                              Navigator.pop(context);
                            } else {
                              _go(_index + 1, total);
                            }
                          },

                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColour,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _index >= steps.length - 1 ? "Done" : 'Next',
                                style: TextStyles.smallHeadingSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
