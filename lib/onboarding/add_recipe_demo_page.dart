import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/components/recipe_card.dart';
import 'package:recipe_app/components/scroll_tag_selector.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/add_recipe_manually_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AddRecipeDemoPage extends StatefulWidget {
  const AddRecipeDemoPage({super.key});

  @override
  State<AddRecipeDemoPage> createState() => _AddRecipeDemoPageState();
}

class _AddRecipeDemoPageState extends State<AddRecipeDemoPage>
    with WidgetsBindingObserver {
  String? _pendingShared;
  bool _pushed = false;
  static const _channel = MethodChannel('share_bridge');
  final _searchCtrl = TextEditingController();
  String _q = "";
  Set<String> _qTags = {};
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _tagsKey = GlobalKey();
  final GlobalKey _addRecipeKey = GlobalKey();

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
      _pendingShared = url;
      _pushed = false;
      if (mounted) setState(() {});
      print("SHARED INTO APP: ${shared}");
    } else {
      if (!context.mounted) return;
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
  }

  void _showTutorial() {
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "search",
        keyTarget: _searchKey,
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        radius: 10,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "Search through your recipes here. You can search by title, description, or ingredients.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "tags",
        keyTarget: _tagsKey,
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        radius: 10,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "Filter recipes by tags. You can select multiple tags at once, and deselect by tapping again.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "add_recipe",
        keyTarget: _addRecipeKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        enableOverlayTab: true,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "Tap here to add a recipe. You can import from a photo, URL, manually, or share directly from a social media platform into the app. Try adding your favourite recipe now!",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      hideSkip: true,
      pulseEnable: true,
      opacityShadow: 0.9,
      pulseAnimationDuration: Duration(seconds: 1),
    ).show(context: context);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkShared();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        if (_pendingShared != null && !_pushed) {
          _pushed = true;
          final shared = _pendingShared!;
          _pendingShared = null;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) =>
                    AddRecipeManuallyPage(importingUrl: shared, demo: true),
              ),
            );
          });
        }

        return Consumer<Notifier>(
          builder: (context, notifier, child) {
            List<Recipe> filtered = notifier.recipes
                .where((r) => notifier.matchRecipes(r, _q, _qTags))
                .toList();

            final listOfUsedTags = notifier.recipes
                .map((r) => r.tags)
                .toList()
                .expand((e) => e)
                .toSet()
                .toList();
            return Scaffold(
              backgroundColor: AppColors.backgroundColour,
              body: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'All Recipes',
                        style: TextStyles.hugeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GestureDetector(
                        key: _addRecipeKey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddRecipeManuallyPage(demo: true),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 12),

                          decoration: BoxDecoration(
                            color: AppColors.primaryColour,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "Add Recipe",
                              style: TextStyles.smallHeadingSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        key: _searchKey,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _q = v.trim()),
                            style: TextStyles.inputedText,
                            decoration: const InputDecoration(
                              icon: Icon(
                                Icons.search,
                                color: Colors.grey,
                                size: 20,
                              ),
                              hintText: 'Search',
                              hintStyle: TextStyles.inputText,
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      key: _tagsKey,
                      child: ScrollTagSelector(
                        tagList: listOfUsedTags,
                        onUpdated: (selectedSet) {
                          setState(() {
                            _qTags = selectedSet;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 170,

                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      mainAxisExtent:
                                          250, // tweak to match  proportions
                                    ),
                                itemBuilder: (context, index) {
                                  final recipe = filtered[index];
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {},
                                    child: RecipeCard(
                                      id: recipe.id,
                                      imageUrl: recipe.imageUrls.firstOrNull,
                                      title: recipe.title,
                                      description: recipe.description,
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 58),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
