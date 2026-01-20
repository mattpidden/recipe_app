import 'package:flutter/material.dart';
import 'package:recipe_app/pages/cookbook_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class CookbookCard extends StatelessWidget {
  final String id;
  final String? imageUrl;
  final String title;
  final String? author;

  const CookbookCard({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CookbookPage(id: id)),
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
              padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.smallHeading,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 8),
                child: Text(
                  author ?? "-",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.bodyTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
