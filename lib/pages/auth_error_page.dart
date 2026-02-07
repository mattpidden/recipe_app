import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';

class AuthErrorPage extends StatefulWidget {
  const AuthErrorPage({super.key});

  @override
  State<AuthErrorPage> createState() => _AuthErrorPageState();
}

class _AuthErrorPageState extends State<AuthErrorPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundColour,
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryColour,
          ),
        ),
      ),
    );
  }
}
