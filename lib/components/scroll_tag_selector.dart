import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class ScrollTagSelector extends StatefulWidget {
  const ScrollTagSelector({super.key});

  @override
  State<ScrollTagSelector> createState() => _ScrollTagSelectorState();
}

class _ScrollTagSelectorState extends State<ScrollTagSelector> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        return SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: notifier.allTags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tags = [...notifier.allTags]
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
              final tag = tags[index];
              final isSelected = _selected.contains(tag);

              return InkWell(
                borderRadius: BorderRadius.circular(1000),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selected.remove(tag);
                    } else {
                      _selected.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColour : Colors.white,
                    borderRadius: BorderRadius.circular(1000),
                  ),
                  child: Center(
                    child: Text(
                      tag,
                      overflow: TextOverflow.ellipsis,
                      style: isSelected
                          ? TextStyles.bodyTextSecondary
                          : TextStyles.bodyTextPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
