import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';

class CookbookPage extends StatefulWidget {
  const CookbookPage({super.key});

  @override
  State<CookbookPage> createState() => _CookbookPageState();
}

class _CookbookPageState extends State<CookbookPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppColors.accentColour2);
  }
}
