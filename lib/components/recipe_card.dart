import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class RecipeCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final String? description;

  const RecipeCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 0.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Container(
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.smallHeading,
                ),
                Text(
                  description ?? "-",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.bodyTextPrimary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
