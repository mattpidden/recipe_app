import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/classes/unit_value.dart';
import 'package:recipe_app/components/ingredient_pill.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/add_recipe_manually_page.dart';
import 'package:recipe_app/pages/cookbook_page.dart';
import 'package:recipe_app/pages/cooked_sheet.dart';
import 'package:recipe_app/pages/cooking_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipePage extends StatefulWidget {
  final String id;
  const RecipePage({super.key, required this.id});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  late final PageController _imgController;
  Timer? _imgTimer;
  int _imgIndex = 0;
  bool modified = false;
  bool loading = false;
  int? _baseServings;
  int? _currentServings;
  double _scale = 1.0;
  List<Ingredient> subs = [];
  final Map<int, List<Ingredient>> _subsByIndex = {};

  Ingredient _displayIngredient(Ingredient base, UnitSystem unitSystem) {
    final qScaled = (base.quantity == null) ? null : base.quantity! * _scale;

    if (unitSystem == UnitSystem.original) {
      return Ingredient(
        raw: base.raw,
        quantity: qScaled,
        unit: base.unit,
        item: base.item,
        notes: base.notes,
      );
    }

    final converted = UnitConverter.convert(
      qScaled,
      base.unit,
      unitSystem,
      ingredient: base.item,
    );

    return Ingredient(
      raw: base.raw, // keep original raw as “source of truth”
      quantity: converted.qty,
      unit: converted.unit,
      item: base.item,
      notes: base.notes,
    );
  }

  String viewModeLabel(UnitSystem unitSystem) {
    switch (unitSystem) {
      case UnitSystem.original:
        return "Original";
      case UnitSystem.metric:
        return "Metric";
      case UnitSystem.imperial_cups:
        return "Imperial (cups)";
      case UnitSystem.imperial_ozs:
        return "Imperial (ozs)";
    }
  }

  void handleDecreaseServing() {
    if (_currentServings == null) return;
    if (_currentServings! <= 1) return;

    setState(() {
      _currentServings = _currentServings! - 1;
      _scale = _currentServings! / _baseServings!;
      modified = _currentServings != _baseServings;
    });
  }

  void handleIncreaseServing() {
    if (_currentServings == null) return;
    if (_currentServings! >= 100) return;

    setState(() {
      _currentServings = _currentServings! + 1;
      _scale = _currentServings! / _baseServings!;
      modified = _currentServings != _baseServings;
    });
  }

  Future<void> handleSubs(int index, String recipe, String ingredient) async {
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
        _subsByIndex[index] = listOfSubs;
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

  void handleRemoveSubs(index) {
    setState(() {
      _subsByIndex[index] = [];
    });
  }

  void _showCookedSheet(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundColour,
      builder: (_) => CookedSheet(recipe: recipe),
    );
  }

  @override
  void initState() {
    super.initState();
    _imgController = PageController();
    final notifier = context.read<Notifier>();
    final recipe = notifier.recipes.firstWhere((r) => r.id == widget.id);
    _imgTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || recipe.imageUrls.isEmpty) return;
      _imgIndex = (_imgIndex + 1) % recipe.imageUrls.length;
      _imgController.animateToPage(
        _imgIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
    _baseServings = recipe.servings;
    _currentServings = recipe.servings;
    _scale = 1.0;
  }

  @override
  void dispose() {
    _imgTimer?.cancel();
    _imgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        final recipe = notifier.recipes.firstWhere((r) => r.id == widget.id);

        final cookbook = recipe.cookbookId == null
            ? null
            : notifier.cookbooks.singleWhere((c) => c.id == recipe.cookbookId);

        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: TextStyles.pageTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddRecipeManuallyPage(
                              editingRecipe: true,
                              oldRecipe: recipe,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.edit_note,
                        color: AppColors.primaryTextColour,
                      ),
                    ),
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (modified)
                          GestureDetector(
                            onTap: loading
                                ? null
                                : () async {
                                    setState(() {
                                      loading = true;
                                    });
                                    try {
                                      await notifier.updateRecipeFromForm(
                                        id: recipe.id,
                                        title: recipe.title,
                                        ingredients: recipe.ingredients
                                            .map(
                                              (i) => Ingredient(
                                                raw: i.raw,
                                                unit: i.unit,
                                                item: i.item,
                                                notes: i.notes,
                                                quantity:
                                                    ((i.quantity ?? 0) *
                                                            _scale) ==
                                                        0
                                                    ? null
                                                    : (i.quantity ?? 0) *
                                                          _scale,
                                              ),
                                            )
                                            .toList(),
                                        servings: _currentServings,
                                      );

                                      setState(() {
                                        modified = false;
                                        _scale = 1;
                                      });
                                    } catch (_) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to update recipe - please try again',
                                            style: TextStyles
                                                .smallHeadingSecondary,
                                          ),
                                          backgroundColor:
                                              AppColors.primaryColour,
                                        ),
                                      );
                                    } finally {
                                      if (mounted)
                                        setState(() => loading = false);
                                    }
                                    setState(() {
                                      loading = false;
                                    });
                                  },
                            child: Container(
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: loading
                                    ? Colors.grey
                                    : AppColors.primaryColour,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: loading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.secondaryTextColour,
                                        ),
                                      )
                                    : Text(
                                        'Save Recipe',
                                        style: TextStyles.smallHeadingSecondary,
                                      ),
                              ),
                            ),
                          ),
                        // Top layout:
                        // - If cookbook exists: cookbook card left + recipe card right
                        // - Else: big full-width image card
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cookbook card (left)
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, c) {
                                  final isWide = c.maxWidth >= 380;

                                  return Container(
                                    height: 180,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: recipe.imageUrls.isEmpty
                                          ? const Center(
                                              child: Icon(
                                                Icons.menu_book,
                                                color: AppColors.accentColour1,
                                                size: 40,
                                              ),
                                            )
                                          : isWide
                                          ? ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              padding: EdgeInsets.zero,
                                              itemCount:
                                                  recipe.imageUrls.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(width: 8),
                                              itemBuilder: (context, i) {
                                                return AspectRatio(
                                                  aspectRatio: 4 / 3,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          7,
                                                        ),
                                                    child: Image.network(
                                                      recipe.imageUrls[i],
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          // ✅ Normal: PageView + dots
                                          : Stack(
                                              alignment: Alignment.bottomCenter,
                                              children: [
                                                PageView.builder(
                                                  controller: _imgController,
                                                  itemCount:
                                                      recipe.imageUrls.length,
                                                  itemBuilder: (context, i) =>
                                                      Image.network(
                                                        recipe.imageUrls[i],
                                                        fit: BoxFit.cover,
                                                      ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  child: SmoothPageIndicator(
                                                    controller: _imgController,
                                                    count:
                                                        recipe.imageUrls.length,
                                                    effect: WormEffect(
                                                      dotHeight: 6,
                                                      dotWidth: 6,
                                                      activeDotColor:
                                                          Colors.white,
                                                      dotColor: Colors.white
                                                          .withAlpha(125),
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
                            const SizedBox(width: 8),

                            // Recipe summary card (right)
                            Container(
                              height: 180,
                              width: 210,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipe.title,
                                    style: TextStyles.smallHeading,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 4),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Text(
                                        recipe.description ?? " ",
                                        style: TextStyles.inputText,
                                        maxLines: 50,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (recipe.servings != null)
                                    Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () => handleDecreaseServing(),
                                          child: Container(
                                            height: 30,
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentColour1,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(10),
                                                bottomLeft: Radius.circular(10),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.remove,
                                              size: 14,
                                              color:
                                                  AppColors.secondaryTextColour,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 30,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          color: AppColors.backgroundColour,
                                          child: Text(
                                            "$_currentServings serving${_currentServings! > 1 ? "s" : ""}",
                                            style:
                                                TextStyles.bodyTextBoldAccent,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => handleIncreaseServing(),
                                          child: Container(
                                            height: 30,
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentColour1,
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(10),
                                                bottomRight: Radius.circular(
                                                  10,
                                                ),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 14,
                                              color:
                                                  AppColors.secondaryTextColour,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Tags
                        if (recipe.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (recipe.timeMinutes != null)
                                _TagChip(text: '${recipe.timeMinutes} min'),
                              ...recipe.tags
                                  .map((t) => _TagChip(text: t))
                                  .toList(),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
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
                                        scale: _scale,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),

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
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _showCookedSheet(context, recipe);
                                },
                                child: Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColour,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Image.asset("assets/white_logo.png"),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Ingredients
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: const Text(
                                'Ingredients',
                                style: TextStyles.subheading,
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                    Widget option(
                                      String label,
                                      UnitSystem mode,
                                    ) {
                                      final selected =
                                          notifier.unitSystem == mode;
                                      return ListTile(
                                        title: Text(
                                          label,
                                          style:
                                              TextStyles.smallHeadingSecondary,
                                        ),
                                        trailing: selected
                                            ? const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                              )
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
                                            option(
                                              "Original",
                                              UnitSystem.original,
                                            ),
                                            option("Metric", UnitSystem.metric),
                                            option(
                                              "Imperial (cups)",
                                              UnitSystem.imperial_cups,
                                            ),
                                            option(
                                              "Imperial (ozs)",
                                              UnitSystem.imperial_ozs,
                                            ),
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
                        if (recipe.ingredients.isNotEmpty)
                          Column(
                            children: List.generate(recipe.ingredients.length, (
                              i,
                            ) {
                              final ingred = recipe.ingredients[i];
                              final displayIngred = _displayIngredient(
                                recipe.ingredients[i],
                                notifier.unitSystem,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: ParsedIngredientPill(
                                  ingredient: displayIngred,
                                  showSubOption: true,
                                  onSub: () => handleSubs(
                                    i,
                                    recipe.title,
                                    "${ingred.quantity} ${ingred.unit} ${ingred.item}",
                                  ),
                                  removeSubs: () => handleRemoveSubs(i),
                                  subs: _subsByIndex[i] ?? const [],
                                  scale: _scale,
                                  unitSystem: notifier.unitSystem,
                                ),
                              );
                            }),
                          ),

                        const SizedBox(height: 16),

                        // Steps
                        const Text('Steps', style: TextStyles.subheading),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: recipe.steps.isEmpty
                              ? const Text(
                                  'No steps yet.',
                                  style: TextStyles.inputedText,
                                )
                              : Column(
                                  children: List.generate(recipe.steps.length, (
                                    i,
                                  ) {
                                    final step = recipe.steps[i];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.accentColour1,
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                              step,
                                              style: TextStyles.inputedText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Notes
                        if ((recipe.notes ?? '').trim().isNotEmpty) ...[
                          const Text('Notes', style: TextStyles.subheading),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              recipe.notes!,
                              style: TextStyles.inputedText,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Source + cookbook link
                        const Text('Source', style: TextStyles.subheading),
                        Row(
                          children: [
                            if (cookbook != null)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CookbookPage(id: cookbook.id),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 140,
                                  height: 180,
                                  padding: const EdgeInsets.all(4),

                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: (cookbook.coverImageUrl == null)
                                        ? const Center(
                                            child: Icon(
                                              Icons.menu_book,
                                              color: AppColors.accentColour1,
                                              size: 40,
                                            ),
                                          )
                                        : Image.network(
                                            cookbook.coverImageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                            if (cookbook != null) const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: cookbook != null ? 180 : null,
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InfoRow(
                                      label: 'Type',
                                      value: recipe.sourceType,
                                    ),
                                    if (cookbook != null)
                                      _InfoRow(
                                        label: 'Cookbook',
                                        value: cookbook.title,
                                      ),
                                    if ((recipe.sourceTitle ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _InfoRow(
                                        label: 'Title',
                                        value: recipe.sourceTitle!,
                                      ),
                                    if ((recipe.sourceAuthor ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _InfoRow(
                                        label: 'Author',
                                        value: recipe.sourceAuthor!,
                                      ),
                                    if ((recipe.sourceUrl ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      _InfoRow(
                                        label: 'URL',
                                        value: recipe.sourceUrl!,
                                      ),

                                    if (recipe.pageNumber != null)
                                      _InfoRow(
                                        label: 'Page',
                                        value: '${recipe.pageNumber}',
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            notifier.deleteRecipe(widget.id);
                            Navigator.pop(context);
                          },
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),

                            decoration: BoxDecoration(
                              color: AppColors.errorColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "Delete Recipe",
                                style: TextStyles.smallHeadingSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
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

class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyles.inputedText),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyles.inputedText.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: GestureDetector(
              onTap: label == "URL"
                  ? () async {
                      final uri = Uri.parse(value);

                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  : null,
              child: Text(
                value,
                style: TextStyles.inputedText.copyWith(
                  color: label == "URL" ? Colors.blue : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
