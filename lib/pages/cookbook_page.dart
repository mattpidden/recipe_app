import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/components/recipe_card.dart';
import 'package:recipe_app/components/scroll_tag_selector.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/add_cookbook_manually_page.dart';
import 'package:recipe_app/pages/add_recipe_manually_page.dart';
import 'package:recipe_app/pages/cookbook_list_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class CookbookPage extends StatefulWidget {
  const CookbookPage({super.key});

  @override
  State<CookbookPage> createState() => _CookbookPageState();
}

class _CookbookPageState extends State<CookbookPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SingleChildScrollView(
            child: SafeArea(
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
                        decoration: const InputDecoration(
                          icon: Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CookbookListPage(),
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
                    child: notifier.cookbooks.isNotEmpty
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: notifier.cookbooks.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cookbook = notifier.cookbooks[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {},
                                child: RecipeCard(
                                  imageUrl: cookbook.coverImageUrl,
                                  title: cookbook.title,
                                  description: cookbook.author,
                                ),
                              );
                            },
                          )
                        : GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddCookbookManuallyPage(),
                                ),
                              );
                            },
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      color: AppColors.secondaryTextColour,
                                    ),
                                    Text(
                                      "Add Your First Cookbook",
                                      style: TextStyles.smallHeadingSecondary,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (notifier.cookbooks.isNotEmpty) const SizedBox(height: 8),
                  if (notifier.cookbooks.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddCookbookManuallyPage(),
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
                            "Add Cookbook",
                            style: TextStyles.smallHeadingSecondary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                  SizedBox(
                    height: 245,
                    child: notifier.recipes.isNotEmpty
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: notifier.recipes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final recipe = notifier.recipes[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {},
                                child: RecipeCard(
                                  imageUrl: recipe.imageUrl,
                                  title: recipe.title,
                                  description: recipe.description,
                                ),
                              );
                            },
                          )
                        : GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddRecipeManuallyPage(),
                                ),
                              );
                            },
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.note_add_outlined,
                                      color: AppColors.secondaryTextColour,
                                    ),
                                    Text(
                                      "Add Your First Recipe",
                                      style: TextStyles.smallHeadingSecondary,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (notifier.recipes.isNotEmpty) const SizedBox(height: 8),
                  if (notifier.recipes.isNotEmpty)
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
                          color: AppColors.accentColour1,
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
                  const SizedBox(height: 58),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
