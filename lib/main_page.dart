import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:recipe_app/pages/auth_error_page.dart';
import 'package:recipe_app/pages/cookbook_page.dart';
import 'package:recipe_app/pages/home_page.dart';
import 'package:recipe_app/pages/plan_page.dart';
import 'package:recipe_app/pages/settings_page.dart';
import 'package:recipe_app/styles/colours.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1;

  final _pages = const [HomePage(), CookbookPage(), PlanPage(), SettingsPage()];

  void presentPaywallIfNeeded() async {
    final paywallResult = await RevenueCatUI.presentPaywallIfNeeded("pro");
    debugPrint('Paywall result: $paywallResult');
  }

  Future<User> signInAnonymouslyIfNeeded() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return auth.currentUser!;
    }
    final credential = await auth.signInAnonymously();
    return credential.user!;
  }

  @override
  void initState() {
    super.initState();
    signInAnonymouslyIfNeeded();
    // presentPaywallIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            body: Stack(
              children: [
                IndexedStack(index: _selectedIndex, children: _pages),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(245),
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
                        GButton(icon: Icons.person, text: 'Profile'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            extendBody: true,
          );
        } else {
          return const AuthErrorPage();
        }
      },
    );
  }
}
