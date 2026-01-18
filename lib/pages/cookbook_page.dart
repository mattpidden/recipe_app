import 'package:flutter/material.dart';
import 'package:recipe_app/components/recipe_card.dart';
import 'package:recipe_app/components/scroll_tag_selector.dart';
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
                      icon: Icon(Icons.search, color: Colors.grey, size: 20),
                      hintText: 'Search',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
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
                    const Text(
                      "See All",
                      style: TextStyles.bodyTextBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primaryTextColour,
                      size: 15,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {},
                      child: RecipeCard(
                        imageUrl:
                            "https://parentscanada.com/wp-content/uploads/2024/11/Simply-Jamie-Cover-787x1024.jpg",
                        title: "Simply Jamie",
                        description: "Jamie Oliver",
                      ),
                    );
                  },
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
                    const Text(
                      "See All",
                      style: TextStyles.bodyTextBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: AppColors.primaryTextColour,
                      size: 15,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {},
                      child: RecipeCard(
                        imageUrl:
                            "https://cdn-ilebiak.nitrocdn.com/pvZLUVBCBEdPhoZIpzQDlQTCJtXdlADr/assets/images/optimized/rev-abcd05a/thehappyfoodie.co.uk/wp-content/uploads/2024/08/Jamie-Oliver-Pepper-Pasta-768x1017.jpg",
                        title: "Jarred Pepper Pasta",
                        description:
                            "Who knew big sunshine flavours could be made so fast? You need this sunny one in your life",
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
