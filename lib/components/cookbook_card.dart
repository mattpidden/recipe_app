import 'package:cached_network_image/cached_network_image.dart';
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
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: SizedBox(
                height: 165,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: imageUrl ?? "",
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
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.smallHeading,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(
                  author ?? "",
                  maxLines: 1,
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
