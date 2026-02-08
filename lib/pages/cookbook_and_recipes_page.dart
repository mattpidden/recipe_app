import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/components/cookbook_card.dart';
import 'package:recipe_app/components/recipe_card.dart';
import 'package:recipe_app/components/scroll_tag_selector.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/add_cookbook_manually_page.dart';
import 'package:recipe_app/pages/add_recipe_manually_page.dart';
import 'package:recipe_app/pages/cookbook_list_page.dart';
import 'package:recipe_app/pages/recipes_list_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class CookbookAndRecipePage extends StatefulWidget {
  const CookbookAndRecipePage({super.key});

  @override
  State<CookbookAndRecipePage> createState() => _CookbookAndRecipePageState();
}

class _CookbookAndRecipePageState extends State<CookbookAndRecipePage> {
  final _searchCtrl = TextEditingController();
  String _q = "";
  Set<String> _qTags = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        List<Recipe> filteredRecipes = notifier.recipes
            .where((r) => notifier.matchRecipes(r, _q, _qTags))
            .toList();
        final filteredCookbooks = notifier.cookbooks
            .where((r) => notifier.matchCookbooks(r, _q, _qTags))
            .toList();
        // filteredRecipes.addAll(
        //   filteredCookbooks.map((c) => c.recipes).expand((e) => e),
        // );
        // // filtered recipes might now have recipes with same ids, that needs filtering out
        // final seen = <String>{};
        // filteredRecipes = filteredRecipes.where((r) => seen.add(r.id)).toList();

        final listOfUsedTags = notifier.recipes
            .map((r) => r.tags)
            .toList()
            .expand((e) => e)
            .toSet()
            .toList();

        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Text(
                    "Cookbooks & Recipes",
                    style: TextStyles.hugeTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _q = v.trim()),
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
                ScrollTagSelector(
                  tagList: listOfUsedTags,
                  onUpdated: (selectedSet) {
                    setState(() {
                      _qTags = selectedSet;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CookbookListPage(
                                    initialQ: _q,
                                    initialTags: _qTags,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: const Text(
                                    "Cookbooks",
                                    style: TextStyles.pageTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                if (notifier.cookbooks.length >= 3)
                                  const Text(
                                    "See All",
                                    style: TextStyles.bodyTextBold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (notifier.cookbooks.length >= 3)
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.primaryTextColour,
                                    size: 15,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 225,
                          child: filteredCookbooks.isNotEmpty
                              ? ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: filteredCookbooks.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final cookbook = filteredCookbooks[index];
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {},
                                      child: CookbookCard(
                                        id: cookbook.id,
                                        imageUrl: cookbook.coverImageUrl,
                                        title: cookbook.title,
                                        author: cookbook.author,
                                      ),
                                    );
                                  },
                                )
                              : GestureDetector(
                                  onTap: notifier.cookbooks.isEmpty
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const AddCookbookManuallyPage(),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Container(
                                    width: 170,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryColour,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (notifier.cookbooks.isEmpty)
                                            Icon(
                                              Icons.add,
                                              color:
                                                  AppColors.secondaryTextColour,
                                            ),
                                          Text(
                                            notifier.cookbooks.isEmpty
                                                ? "Add Your First Cookbook"
                                                : "No Results Found",
                                            style: TextStyles
                                                .smallHeadingSecondary,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // if (notifier.cookbooks.isNotEmpty)
                        //   const SizedBox(height: 8),
                        // if (notifier.cookbooks.isNotEmpty)
                        //   GestureDetector(
                        //     onTap: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //           builder: (_) =>
                        //               const AddCookbookManuallyPage(),
                        //         ),
                        //       );
                        //     },
                        //     child: Container(
                        //       height: 50,
                        //       padding: const EdgeInsets.symmetric(
                        //         horizontal: 12,
                        //       ),
                        //       margin: const EdgeInsets.symmetric(
                        //         horizontal: 16.0,
                        //       ),
                        //       decoration: BoxDecoration(
                        //         color: AppColors.primaryColour,
                        //         borderRadius: BorderRadius.circular(10),
                        //       ),
                        //       child: Center(
                        //         child: Text(
                        //           "Add Cookbook",
                        //           style: TextStyles.smallHeadingSecondary,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecipesListPage(
                                    initialQ: _q,
                                    initialTags: _qTags,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: const Text(
                                    "Recipes",
                                    style: TextStyles.pageTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (notifier.recipes.length >= 3)
                                  const Text(
                                    "See All",
                                    style: TextStyles.bodyTextBold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                if (notifier.recipes.length >= 3)
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: AppColors.primaryTextColour,
                                    size: 15,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 190,
                          child: filteredRecipes.isNotEmpty
                              ? ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: filteredRecipes.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final recipe = filteredRecipes[index];
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {},
                                      child: RecipeCard(recipe: recipe),
                                    );
                                  },
                                )
                              : GestureDetector(
                                  onTap: notifier.recipes.isEmpty
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AddRecipeManuallyPage(
                                                    popOnSave: false,
                                                  ),
                                            ),
                                          );
                                        }
                                      : null,
                                  child: Container(
                                    width: 170,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentColour1,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (notifier.recipes.isEmpty)
                                            Icon(
                                              Icons.note_add_outlined,
                                              color:
                                                  AppColors.secondaryTextColour,
                                            ),
                                          Text(
                                            notifier.recipes.isEmpty
                                                ? "Add Your First Recipe"
                                                : "No Results Found",
                                            style: TextStyles
                                                .smallHeadingSecondary,
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // if (notifier.recipes.isNotEmpty)
                        //   const SizedBox(height: 8),
                        // if (notifier.recipes.isNotEmpty)
                        //   GestureDetector(
                        //     onTap: () {
                        //       Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //           builder: (_) => AddRecipeManuallyPage(),
                        //         ),
                        //       );
                        //     },
                        //     child: Container(
                        //       height: 50,
                        //       padding: const EdgeInsets.symmetric(
                        //         horizontal: 12,
                        //       ),
                        //       margin: const EdgeInsets.symmetric(
                        //         horizontal: 16.0,
                        //       ),
                        //       decoration: BoxDecoration(
                        //         color: AppColors.accentColour1,
                        //         borderRadius: BorderRadius.circular(10),
                        //       ),
                        //       child: Center(
                        //         child: Text(
                        //           "Add Recipe",
                        //           style: TextStyles.smallHeadingSecondary,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        const SizedBox(height: 16 + 70 + 16),
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
