import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/components/recipe_card.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class CookbookPage extends StatefulWidget {
  final String id;
  const CookbookPage({super.key, required this.id});

  @override
  State<CookbookPage> createState() => _CookbookPageState();
}

class _CookbookPageState extends State<CookbookPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        final cookbook = notifier.cookbooks.firstWhere(
          (c) => c.id == widget.id,
        );

        final recipes = notifier.recipes
            .where((r) => (r.cookbookId ?? '') == widget.id)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
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
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        cookbook.title,
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
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Cover card
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
                                child: cookbook.coverImageUrl == null
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
                            const SizedBox(width: 8),

                            // Details card
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
                                      cookbook.title,
                                      style: TextStyles.smallHeading,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if ((cookbook.author ?? '')
                                        .trim()
                                        .isNotEmpty) ...[
                                      Text(
                                        cookbook.author!,
                                        style: TextStyles.inputText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if ((cookbook.description ?? '')
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        cookbook.description!,
                                        style: TextStyles.inputText,
                                        maxLines: 6,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text('Recipes', style: TextStyles.pageTitle),

                        if (recipes.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'No recipes added for this cookbook yet.',
                              style: TextStyles.inputText,
                            ),
                          ),

                        if (recipes.isNotEmpty)
                          Column(
                            children: recipes.map((r) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: RecipeCard(
                                  title: r.title,
                                  description: r.description,
                                  imageUrl: r.imageUrl,
                                ),
                              );
                            }).toList(),
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
