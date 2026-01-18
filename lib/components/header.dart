import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0.0,
      //backgroundColor:
      automaticallyImplyLeading: false,
      title: Center(
        child: SizedBox(
          width: 700,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 0.0, right: 8.0),
                child: SizedBox(
                  height: 30,
                  width: 30,
                  child: Image.asset('assets/logo.png'),
                ),
              ),
              const Text("Recipe App", style: TextStyles.pageTitle),
              const Spacer(),
              PopupMenuButton<int>(
                icon: const Icon(Icons.menu, color: AppColors.primaryColour),
                onSelected: (value) async {
                  switch (value) {
                    case 0:
                      break;
                    case 1:
                      break;
                    case 2:
                      break;
                  }
                },
                itemBuilder: (context) => [],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
