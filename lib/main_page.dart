import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:recipe_app/pages/add_cookbook_manually_page.dart';
import 'package:recipe_app/pages/add_recipe_manually_page.dart';
import 'package:recipe_app/pages/add_shopping_list_sheet.dart';
import 'package:recipe_app/pages/auth_error_page.dart';
import 'package:recipe_app/pages/cookbook_and_recipes_page.dart';
import 'package:recipe_app/pages/home_page.dart';
import 'package:recipe_app/pages/plan_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  int _selectedIndex = 1;
  bool _fabOpen = false;
  bool _hideNavBar = false;

  void _toggleFab() => setState(() => _fabOpen = !_fabOpen);
  void _closeFab() => setState(() => _fabOpen = false);

  final _pages = const [HomePage(), CookbookAndRecipePage(), PlanPage()];

  static const _channel = MethodChannel('share_bridge');

  Future<String?> getSharedOnce() async {
    final v = await _channel.invokeMethod<String>('getShared');
    if (v != null && v.trim().isNotEmpty) {
      await _channel.invokeMethod('clearShared');
      return v.trim();
    }
    return null;
  }

  String? extractFirstUrl(String input) {
    final regex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);

    final match = regex.firstMatch(input);
    return match?.group(0);
  }

  Future<void> _checkShared() async {
    print("Checking shared...");
    final shared = await getSharedOnce();
    if (shared == null) return;
    final url = extractFirstUrl(shared);
    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddRecipeManuallyPage(importingUrl: shared),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Import failed - could not find URL',
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
    }
    // _handleShared(shared);
    print("SHARED INTO APP: ${shared}");
  }

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

  Future<void> checkForUpdate(BuildContext context) async {
    if (kDebugMode) return;
    final snap = await FirebaseFirestore.instance
        .collection('general')
        .doc('general')
        .get();

    final int remoteBuild = snap.data()?['build'] ?? 0;

    final info = await PackageInfo.fromPlatform();
    final int localBuild = int.tryParse(info.buildNumber) ?? 0;
    print("remote build $remoteBuild");
    print("local build $localBuild");
    if (remoteBuild > localBuild && context.mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Update Available'),
          content: const Text(
            'A newer version of the app is available in TestFlight. Please update to test the latest and greatest features!',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Later'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final uri = Uri.parse(
                  'https://testflight.apple.com/join/zAdEaHde',
                );
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    signInAnonymouslyIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdate(context);
      _checkShared();
    });
    // presentPaywallIfNeeded();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkShared();
    }
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

                if (!_hideNavBar)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 98,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTextColour.withAlpha(30),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
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
                          GButton(icon: Icons.menu_book, text: 'Recipes'),
                          GButton(icon: Icons.calendar_today, text: 'Plan'),
                        ],
                      ),
                    ),
                  ),

                if (!_hideNavBar)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_fabOpen,
                      child: GestureDetector(
                        onTap: _closeFab,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 100),
                          opacity: _fabOpen ? 1 : 0,
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: _fabOpen ? 20 : 0,
                              sigmaY: _fabOpen ? 20 : 0,
                            ),
                            child: Container(
                              color: Colors.grey.shade900.withAlpha(150),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (!_hideNavBar)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _FabAction(
                          visible: _fabOpen,
                          index: 0,
                          label: 'Add Cookbook',
                          icon: Icons.menu_book_outlined,
                          onTap: () {
                            _closeFab();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddCookbookManuallyPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),
                        _FabAction(
                          visible: _fabOpen,
                          index: 1,
                          label: 'Add Recipe',
                          icon: Icons.receipt_long,
                          onTap: () {
                            _closeFab();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddRecipeManuallyPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _FabAction(
                          visible: _fabOpen,
                          index: 2,
                          label: 'Add Recipe From Photo',
                          icon: Icons.photo_camera,
                          onTap: () {
                            _closeFab();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddRecipeManuallyPage(openCamera: true),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _FabAction(
                          visible: _fabOpen,
                          index: 2,
                          label: 'Add to Shopping List',
                          icon: Icons.receipt,
                          onTap: () {
                            _closeFab();
                            _selectedIndex = 2;
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: AppColors.backgroundColour,
                              builder: (_) => AddShoppingItemSheet(),
                            );
                          },
                        ),

                        const SizedBox(height: 8),

                        // main button styled like navbar
                        GestureDetector(
                          onTap: _toggleFab,
                          child: Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              color: _fabOpen ? null : AppColors.primaryColour,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(15),
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(40),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryTextColour.withAlpha(
                                    30,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedRotation(
                                turns: _fabOpen ? 0.125 : 0.0, // 45 degrees
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                child: Icon(
                                  Icons.add,
                                  size: _fabOpen ? 35 : 25,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _FabAction extends StatelessWidget {
  final bool visible;
  final int index;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FabAction({
    required this.visible,
    required this.index,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = visible ? 1.0 : 0.0;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: t,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 0.2),
          duration: Duration(milliseconds: 200 + index * 40),
          curve: Curves.easeOut,
          child: GestureDetector(
            onTap: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),

                  child: Text(
                    label,
                    style: TextStyles.subheading.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Icon(icon, color: AppColors.primaryColour),
                ),
                const SizedBox(width: 9),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
