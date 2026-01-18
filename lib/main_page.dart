import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:recipe_app/components/header.dart';
import 'package:recipe_app/pages/cookbook_page.dart';
import 'package:recipe_app/pages/home_page.dart';
import 'package:recipe_app/pages/plan_page.dart';
import 'package:recipe_app/styles/colours.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final _pages = const [HomePage(), CookbookPage(), PlanPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _pages),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: GNav(
                gap: 8,
                selectedIndex: _selectedIndex,
                onTabChange: (i) => setState(() => _selectedIndex = i),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                color: AppColors.primaryColour,
                activeColor: Colors.white,
                tabBackgroundColor: AppColors.primaryColour,
                tabs: const [
                  GButton(icon: Icons.home, text: 'Home'),
                  GButton(icon: Icons.menu_book, text: 'Cookbooks'),
                  GButton(icon: Icons.calendar_today, text: 'Plan'),
                ],
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
    );
  }
}
