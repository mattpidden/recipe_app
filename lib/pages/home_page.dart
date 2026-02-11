import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:recipe_app/components/cooking_momentum_card.dart';
import 'package:recipe_app/components/fridge_ai_recipe_card.dart';
import 'package:recipe_app/components/recent_cooked_card.dart';
import 'package:recipe_app/components/todays_planned_meal_card.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class HomePage extends StatefulWidget {
  final void Function() navToPlan;
  const HomePage({super.key, required this.navToPlan});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String appVersion = "";
  bool _hasPro = false;

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = "${packageInfo.version} (${packageInfo.buildNumber})";
    });
  }

  Future<void> _checkProStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final active = customerInfo.entitlements.active.containsKey(
        "RecipeApp Pro",
      );
      setState(() {
        _hasPro = active;
      });
    } catch (e) {
      debugPrint("Failed to check pro status: $e");
    }
  }

  Future<void> _presentPaywallIfNeeded() async {
    final result = await RevenueCatUI.presentPaywallIfNeeded("RecipeApp Pro");
    debugPrint("Paywall result: $result");
    _checkProStatus();
  }

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _checkProStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        _checkProStatus();
        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
            bottom: false,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,

              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Text(
                      "Home",
                      style: TextStyles.hugeTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_hasPro)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: GestureDetector(
                                onTap: _presentPaywallIfNeeded,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Free Plan",
                                        style: TextStyles.subheading,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        notifier.totalRecipesAdded >= 3
                                            ? "You’ve reached the 3 recipe limit."
                                            : "You have added ${notifier.totalRecipesAdded} of 3 recipes",
                                        style: TextStyles.tinyTextPrimary,
                                      ),
                                      Text(
                                        notifier.totalRecipesAdded >= 3
                                            ? "Upgrade to Pro to add unlimited recipes. Start with a 14-day free trial."
                                            : "Add up to 3 recipes completely free. When you're ready for more, upgrade to Pro to add unlimited recipes.",
                                        style: TextStyles.bodyTextPrimary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (!_hasPro) const SizedBox(height: 8),
                          TodaysPlannedMealCard(navToPlan: widget.navToPlan),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const CookingMomentumCard(),
                          ),
                          const SizedBox(height: 8),
                          FridgeAiRecipeCard(),
                          const SizedBox(height: 8),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: RecentCookedCard(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "App Version $appVersion Beta Testing",
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await RevenueCatUI.presentCustomerCenter();
                                },
                                child: Text(
                                  "Customer Center",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12 + 70 + 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
