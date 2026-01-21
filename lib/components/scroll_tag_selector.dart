import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class ScrollTagSelector extends StatefulWidget {
  final List<String> tagList;
  final void Function(Set<String>) onUpdated;
  const ScrollTagSelector({
    super.key,
    this.tagList = const [],
    required this.onUpdated,
  });

  @override
  State<ScrollTagSelector> createState() => _ScrollTagSelectorState();
}

class _ScrollTagSelectorState extends State<ScrollTagSelector> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        final theTagList = widget.tagList.isNotEmpty
            ? widget.tagList
            : notifier.allTags;

        return SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: theTagList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tags = [...theTagList]
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
                  widget.onUpdated(_selected);
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
