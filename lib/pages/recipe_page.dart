import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/cookbook.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/cookbook_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class RecipePage extends StatefulWidget {
  final String id;
  const RecipePage({super.key, required this.id});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
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

                // Top layout:
                // - If cookbook exists: cookbook card left + recipe card right
                // - Else: big full-width image card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cookbook card (left)
                      Container(
                        width: 140,
                        height: 180,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: (recipe.imageUrls.firstOrNull == null)
                              ? const Center(
                                  child: Icon(
                                    Icons.menu_book,
                                    color: AppColors.accentColour1,
                                    size: 40,
                                  ),
                                )
                              : Image.network(
                                  recipe.imageUrls.firstOrNull!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Recipe summary card (right)
                      Expanded(
                        child: Container(
                          height: 180,
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
                              if ((recipe.description ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  recipe.description!,
                                  style: TextStyles.inputText,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const Spacer(),
                              Row(
                                children: [
                                  if (recipe.timeMinutes != null)
                                    _Pill(text: '${recipe.timeMinutes} min'),
                                  if (recipe.timeMinutes != null &&
                                      recipe.servings != null)
                                    const SizedBox(width: 6),
                                  if (recipe.servings != null)
                                    _Pill(text: '${recipe.servings} servings'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Extra images (if any) when cookbook exists, or if more than 1 image
                        if (recipe.imageUrls.length > 1) ...[
                          const Text('Photos', style: TextStyles.pageTitle),
                          const SizedBox(height: 8),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recipe.imageUrls.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final url = recipe.imageUrls[i];
                                return Container(
                                  width: 170,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Tags
                        if (recipe.tags.isNotEmpty) ...[
                          const Text('Tags', style: TextStyles.pageTitle),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: recipe.tags
                                .map((t) => _TagChip(text: t))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Ingredients
                        const Text('Ingredients', style: TextStyles.pageTitle),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: recipe.ingredients.isEmpty
                              ? const Text(
                                  'No ingredients yet.',
                                  style: TextStyles.inputText,
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: recipe.ingredients.map((ing) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            '•  ',
                                            style: TextStyles.inputText,
                                          ),
                                          Expanded(
                                            child: Text(
                                              ing.raw,
                                              style: TextStyles.inputText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),

                        const SizedBox(height: 16),

                        // Steps
                        const Text('Steps', style: TextStyles.pageTitle),
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
                                  style: TextStyles.inputText,
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
                                              style: TextStyles.inputText,
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
                          const Text('Notes', style: TextStyles.pageTitle),
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
                              style: TextStyles.inputText,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Source + cookbook link
                        const Text('Source', style: TextStyles.pageTitle),
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

                        const SizedBox(height: 16),
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
      child: Text(text, style: TextStyles.inputText),
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
          SizedBox(width: 74, child: Text(label, style: TextStyles.inputText)),
          Expanded(child: Text(value, style: TextStyles.inputText)),
        ],
      ),
    );
  }
}
