import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class AddRecipeManuallyPage extends StatefulWidget {
  const AddRecipeManuallyPage({super.key});

  @override
  State<AddRecipeManuallyPage> createState() => _AddRecipeManuallyPageState();
}

class _AddRecipeManuallyPageState extends State<AddRecipeManuallyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColour,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
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
                  const Expanded(
                    child: Text(
                      'Add Recipe',
                      style: TextStyles.pageTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
