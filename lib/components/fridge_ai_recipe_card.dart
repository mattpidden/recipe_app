import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/pages/add_recipe_manually_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class FridgeAiRecipeCard extends StatefulWidget {
  final bool hasPro;
  const FridgeAiRecipeCard({super.key, required this.hasPro});

  @override
  State<FridgeAiRecipeCard> createState() => _FridgeAiRecipeCardState();
}

class _FridgeAiRecipeCardState extends State<FridgeAiRecipeCard> {
  final controller = TextEditingController();
  bool _loading = false;

  void _handleCreate() async {
    try {
      final input = controller.text.trim();
      if (input.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please enter some ingredients or a style",
              style: TextStyles.smallHeadingSecondary,
            ),
            backgroundColor: AppColors.primaryColour,
          ),
        );
        return;
      } else {
        setState(() {
          _loading = true;
        });
        final fn = FirebaseFunctions.instanceFor(
          region: 'europe-west2',
        ).httpsCallable('recipeFromFridgeIngreds');

        final res = await fn.call({'ingredients': input});
        debugPrint(res.data.toString());
        final data = Map<String, dynamic>.from(res.data as Map);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddRecipeManuallyPage(popOnSave: false, draftRecipe: data),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to create recipe, please try again",
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accentColour1,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "What’s in your fridge?",
                      style: TextStyles.subheading,
                    ),
                    Text(
                      // text telling user to list what ingredients they have and what cusine or style of recipe they want concisely
                      "List ingredients, cuisine, and we’ll create a recipe",
                      style: TextStyles.bodyTextPrimary,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            decoration: BoxDecoration(
              color: AppColors.backgroundColour,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              enabled: !_loading && widget.hasPro,
              controller: controller,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyles.inputedText,
              decoration: const InputDecoration(
                hintText: "e.g. chicken, rice, half a lemon, chinese style",
                hintStyle: TextStyles.inputText,
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // CTA
          GestureDetector(
            onTap: !_loading && widget.hasPro ? _handleCreate : null,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _loading || !widget.hasPro
                    ? Colors.grey
                    : AppColors.primaryColour,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondaryTextColour,
                        ),
                      )
                    : Text(
                        "Create a recipe",
                        style: TextStyles.smallHeadingSecondary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
