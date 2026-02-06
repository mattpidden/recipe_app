import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class AuthErrorPage extends StatefulWidget {
  const AuthErrorPage({super.key});

  @override
  State<AuthErrorPage> createState() => _AuthErrorPageState();
}

class _AuthErrorPageState extends State<AuthErrorPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryColour,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                "There was an error authenticating you. Please try again.",
                style: TextStyles.smallHeadingSecondary,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
