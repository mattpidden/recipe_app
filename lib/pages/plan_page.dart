import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppColors.accentColour1);
  }
}
