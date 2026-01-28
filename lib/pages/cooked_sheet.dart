import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/components/inputs.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class CookedSheet extends StatefulWidget {
  final Recipe recipe;
  const CookedSheet({required this.recipe});

  @override
  State<CookedSheet> createState() => CookedSheetState();
}

class CookedSheetState extends State<CookedSheet> {
  int _rating = 5;
  final _comment = TextEditingController();
  final _occasion = TextEditingController();
  final _withWho = TextEditingController(); // comma separated
  bool _wouldMakeAgain = true;
  DateTime _cookedAt = DateTime.now();
  bool saving = false;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _cookedAt = _dateOnly(DateTime.now());
  }

  @override
  void dispose() {
    _comment.dispose();
    _occasion.dispose();
    _withWho.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
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
            initialChildSize: 0.9,
            //minChildSize: 0.55,
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
                    Text(
                      'How was ${widget.recipe.title}?',
                      style: TextStyles.pageTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _StarRow(
                      rating: _rating,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                    const SizedBox(height: 8),
                    const Text('Cooked date', style: TextStyles.subheading),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _cookedAt,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primaryColour,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: AppColors.primaryTextColour,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null)
                          setState(() => _cookedAt = _dateOnly(picked));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _fmtDate(_cookedAt),
                                style: TextStyles.inputedText,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppColors.primaryTextColour,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text('Comments', style: TextStyles.subheading),
                    Input(
                      controller: _comment,
                      maxLines: 3,
                      hint:
                          "e.g. First time cooking this recipe and everyone loved it!",
                    ),
                    const SizedBox(height: 8),
                    const Text('Occasion', style: TextStyles.subheading),
                    Input(
                      hint: "e.g. Eitan's Birthday Dinner",
                      controller: _occasion,
                    ),
                    const SizedBox(height: 8),
                    const Text('Who was there?', style: TextStyles.subheading),
                    Input(
                      hint: 'Comma separated (e.g. Matt, Sela)',
                      controller: _withWho,
                    ),
                    const SizedBox(height: 8),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Would make again',
                            style: TextStyles.subheading,
                          ),
                        ),
                        Switch(
                          inactiveTrackColor: AppColors.backgroundColour,
                          value: _wouldMakeAgain,
                          onChanged: (v) => setState(() => _wouldMakeAgain = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Consumer<Notifier>(
                      builder: (context, notifier, _) {
                        return GestureDetector(
                          onTap: () async {
                            setState(() {
                              saving = true;
                            });
                            final list = _withWho.text
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList();

                            await notifier.addCookedEvent(
                              recipeId: widget.recipe.id,
                              rating: _rating,
                              comment: _comment.text,
                              occasion: _occasion.text,
                              withWho: list,
                              wouldMakeAgain: _wouldMakeAgain,
                            );
                            setState(() {
                              saving = false;
                            });
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
                              child: saving
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.secondaryTextColour,
                                      ),
                                    )
                                  : Text(
                                      'Save',
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

class _StarRow extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  const _StarRow({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final v = i + 1;
          final filled = v <= rating;
          return IconButton(
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(v),
            icon: Icon(
              filled ? Icons.star : Icons.star_border,
              color: AppColors.primaryColour,
              size: 30,
            ),
          );
        }),
      ),
    );
  }
}
