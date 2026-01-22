import 'package:flutter/material.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class ParsedIngredientPill extends StatelessWidget {
  final Ingredient ingredient;
  const ParsedIngredientPill({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    final qty = ingredient.quantity;
    final unit = ingredient.unit;
    final item = ingredient.item ?? ingredient.raw;

    final left = [
      if (qty != null)
        qty.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
      if (unit != null && unit.trim().isNotEmpty) unit,
    ].join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 16,
                color: AppColors.successColor,
              ),
              const SizedBox(width: 6),
              if (left.isNotEmpty)
                Text(
                  left,
                  style: TextStyles.inputedText.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (left.isNotEmpty) const SizedBox(width: 6),
              // if (left.isNotEmpty)
              //   const Icon(Icons.balance, size: 14, color: Colors.grey),
              Expanded(
                child: Text(
                  item,
                  style: TextStyles.inputedText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.autorenew,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (ingredient.notes != null && ingredient.notes!.trim().isNotEmpty)
            Row(
              children: [
                const Icon(Icons.notes, size: 16, color: Colors.grey),
                const SizedBox(width: 6),

                Expanded(
                  child: Text(
                    '${ingredient.notes}',
                    style: TextStyles.inputedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
