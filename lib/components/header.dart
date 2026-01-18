import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0.0,
      automaticallyImplyLeading: false,
      title: const Text(
        "Embark on Your Cooking Journey",
        style: TextStyles.hugeTitle,
        maxLines: 2,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
