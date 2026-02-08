import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/pages/recipe_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipePage(id: recipe.id)),
        );
      },
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: recipe.imageUrls.isNotEmpty
                      ? recipe.imageUrls[0]
                      : "",
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 50),
                  placeholder: (_, __) =>
                      Container(color: AppColors.backgroundColour),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.accentColour1,
                    child: Center(
                      child: Text(
                        "No Image",
                        style: TextStyles.bodyTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Text content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 4, 8, 0),
                child: Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.smallHeading,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 8,

                  children: [
                    if (recipe.timeMinutes != null)
                      _TagChip(text: '${recipe.timeMinutes} min'),
                    ...recipe.tags.map((t) => _TagChip(text: t)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundColour,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyles.tinyTextPrimary),
    );
  }
}
