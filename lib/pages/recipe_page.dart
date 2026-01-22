import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/components/ingredient_pill.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/cookbook_page.dart';
import 'package:recipe_app/pages/cooking_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
                  ],
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    child: Text(
                                      recipe.description!,
                                      style: TextStyles.inputText,
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if (recipe.timeMinutes != null)
                                        _Pill(
                                          text: '${recipe.timeMinutes} min',
                                        ),
                                      if (recipe.timeMinutes != null &&
                                          recipe.servings != null)
                                        const SizedBox(width: 6),
                                      if (recipe.servings != null)
                                        _Pill(
                                          text: '${recipe.servings} servings',
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
                            children: recipe.tags
                                .map((t) => _TagChip(text: t))
                                .toList(),
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
                                      builder: (_) => const CookingPage(),
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
                                onTap: () {},
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
                        const Text('Ingredients', style: TextStyles.subheading),
                        if (recipe.ingredients.isNotEmpty)
                          Column(
                            children: List.generate(recipe.ingredients.length, (
                              i,
                            ) {
                              final ingred = recipe.ingredients[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: ParsedIngredientPill(ingredient: ingred),
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
                                    if (cookbook != null)
                                      _InfoRow(
                                        label: 'Cookbook',
                                        value: cookbook.title,
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
                        // const SizedBox(height: 8),
                        // GestureDetector(
                        //   onTap: () {
                        //     notifier.deleteRecipe(widget.id);
                        //     Navigator.pop(context);
                        //   },
                        //   child: Container(
                        //     height: 50,
                        //     padding: const EdgeInsets.symmetric(horizontal: 12),

                        //     decoration: BoxDecoration(
                        //       color: AppColors.errorColor,
                        //       borderRadius: BorderRadius.circular(10),
                        //     ),
                        //     child: Center(
                        //       child: Text(
                        //         "Delete Recipe",
                        //         style: TextStyles.smallHeadingSecondary,
                        //       ),
                        //     ),
                        //   ),
                        // ),
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

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentColour1,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyles.smallHeadingSecondary),
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
          Expanded(child: Text(value, style: TextStyles.inputedText)),
        ],
      ),
    );
  }
}
