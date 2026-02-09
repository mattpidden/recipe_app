import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/components/inputs.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class AddShoppingItemSheet extends StatefulWidget {
  final String initialName;

  const AddShoppingItemSheet({super.key, this.initialName = ''});

  @override
  State<AddShoppingItemSheet> createState() => AddShoppingItemSheetState();
}

class AddShoppingItemSheetState extends State<AddShoppingItemSheet> {
  final _ingredientInput = TextEditingController();
  bool _ingredientParsing = false;

  @override
  void initState() {
    super.initState();
    _ingredientInput.text = widget.initialName;
  }

  @override
  void dispose() {
    _ingredientInput.dispose();
    super.dispose();
  }

  Future<void> _addIngredientFromInput() async {
    final raw = _ingredientInput.text.trim();
    if (raw.isEmpty || _ingredientParsing) return;

    setState(() {
      _ingredientParsing = true;
    });

    try {
      final fn = FirebaseFunctions.instanceFor(
        region: 'europe-west2',
      ).httpsCallable('parseIngredient');

      final res = await fn.call({'raw': raw});
      final ingred = Ingredient.fromMap(
        Map<String, dynamic>.from(res.data as Map),
      );
      final notifier = context.read<Notifier>();
      await notifier.addToShoppingList(ingred);
      setState(() {
        _ingredientInput.clear();
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _ingredientParsing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundColour,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: DraggableScrollableSheet(
            expand: false,
            snap: true,
            initialChildSize: 0.75,
            maxChildSize: 0.9,
            builder: (context, scroll) {
              return SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(30),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Add to shopping list',
                      style: TextStyles.pageTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    const Text('Ingredient', style: TextStyles.subheading),
                    Input(
                      controller: _ingredientInput,
                      hint: 'e.g. Cherry tomatoes',
                    ),

                    const SizedBox(height: 14),

                    Consumer<Notifier>(
                      builder: (context, notifier, _) {
                        return GestureDetector(
                          onTap: _ingredientParsing
                              ? null
                              : () async {
                                  await _addIngredientFromInput();
                                  if (context.mounted) Navigator.pop(context);
                                },
                          child: Container(
                            height: 54,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColour,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: _ingredientParsing
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.secondaryTextColour,
                                      ),
                                    )
                                  : Text(
                                      'Add',
                                      style: TextStyles.smallHeadingSecondary,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
