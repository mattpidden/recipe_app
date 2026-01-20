import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/components/cookbook_card.dart';
import 'package:recipe_app/components/recipe_card.dart';
import 'package:recipe_app/components/scroll_tag_selector.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/add_cookbook_manually_page.dart';
import 'package:recipe_app/pages/add_recipe_manually_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class RecipesListPage extends StatefulWidget {
  const RecipesListPage({super.key});

  @override
  State<RecipesListPage> createState() => _RecipesListPageState();
}

class _RecipesListPageState extends State<RecipesListPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.primaryTextColour,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'All Recipes',
                          style: TextStyles.pageTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddRecipeManuallyPage(),
                      ),
                    );
                  },
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColour,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Add Recipe",
                        style: TextStyles.smallHeadingSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: TextField(
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
                ScrollTagSelector(),

                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notifier.recipes.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // number of columns
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio:
                                      0.72, // tweak to match  proportions
                                ),
                            itemBuilder: (context, index) {
                              final recipe = notifier.recipes[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {},
                                child: RecipeCard(
                                  id: recipe.id,
                                  imageUrl: recipe.imageUrls.firstOrNull,
                                  title: recipe.title,
                                  description: recipe.description,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 58),
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
