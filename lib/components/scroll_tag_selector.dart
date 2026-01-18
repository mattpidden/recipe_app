import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class ScrollTagSelector extends StatefulWidget {
  const ScrollTagSelector({super.key});

  @override
  State<ScrollTagSelector> createState() => _ScrollTagSelectorState();
}

class _ScrollTagSelectorState extends State<ScrollTagSelector> {
  final Set<String> _selected = {};

  final List<_TagItem> _tags = const [
    _TagItem('Special', Icons.star_border),
    _TagItem('Breakfast', Icons.breakfast_dining),
    _TagItem('Lunch', Icons.lunch_dining),
    _TagItem('Dinner', Icons.dinner_dining),
    _TagItem('Dessert', Icons.icecream_outlined),
    _TagItem('Quick', Icons.bolt_outlined),
    _TagItem('Healthy', Icons.favorite_border),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tag = _tags[index];
          final isSelected = _selected.contains(tag.label);

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selected.remove(tag.label);
                } else {
                  _selected.add(tag.label);
                }
              });
            },
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryColour : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tag.icon,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : AppColors.primaryTextColour,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tag.label,
                    overflow: TextOverflow.ellipsis,
                    style: isSelected
                        ? TextStyles.bodyTextSecondary
                        : TextStyles.bodyTextPrimary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TagItem {
  final String label;
  final IconData icon;
  const _TagItem(this.label, this.icon);
}
