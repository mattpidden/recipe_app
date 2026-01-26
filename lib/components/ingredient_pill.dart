import 'package:flutter/material.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/classes/unit_value.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class ParsedIngredientPill extends StatefulWidget {
  final Ingredient ingredient;
  final bool showSubOption;
  final Future<void> Function() onSub;
  final void Function() removeSubs;
  final List<Ingredient> subs;
  final bool isSub;
  final double scale;
  final UnitSystem unitSystem;

  const ParsedIngredientPill({
    super.key,
    required this.ingredient,
    required this.onSub,
    required this.subs,
    this.isSub = false,
    required this.removeSubs,
    required this.showSubOption,
    required this.unitSystem,
    required this.scale,
  });

  @override
  State<ParsedIngredientPill> createState() => _ParsedIngredientPillState();
}

class _ParsedIngredientPillState extends State<ParsedIngredientPill> {
  bool loadingSubs = false;

  Ingredient _displayIngredient(Ingredient base) {
    final qScaled = (base.quantity == null)
        ? null
        : base.quantity! * widget.scale;

    if (widget.unitSystem == UnitSystem.original) {
      return Ingredient(
        raw: base.raw,
        quantity: qScaled,
        unit: base.unit,
        item: base.item,
        notes: base.notes,
      );
    }

    final target = widget.unitSystem == UnitSystem.metric
        ? UnitSystem.metric
        : UnitSystem.imperial;

    final converted = UnitConverter.convert(qScaled, base.unit, target);

    return Ingredient(
      raw: base.raw, // keep original raw as “source of truth”
      quantity: converted.qty,
      unit: converted.unit,
      item: base.item,
      notes: base.notes,
    );
  }

  String get _viewModeLabel {
    switch (widget.unitSystem) {
      case UnitSystem.original:
        return "Original";
      case UnitSystem.metric:
        return "Metric";
      case UnitSystem.imperial:
        return "Imperial";
    }
  }

  @override
  Widget build(BuildContext context) {
    final qty = widget.ingredient.quantity;
    final unit = widget.ingredient.unit;
    final item = widget.ingredient.item ?? widget.ingredient.raw;

    final left = [
      if (qty != null)
        qty.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
      if (unit != null && unit.trim().isNotEmpty) unit,
    ].join(' ');

    return Column(
      children: [
        Container(
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
                  if (!widget.isSub)
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.successColor,
                    ),
                  if (!widget.isSub) const SizedBox(width: 6),
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
                  if (!widget.isSub && widget.showSubOption)
                    const SizedBox(width: 3),
                  if (!widget.isSub &&
                      widget.subs.isEmpty &&
                      widget.showSubOption)
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          loadingSubs = true;
                        });
                        await widget.onSub();
                        setState(() {
                          loadingSubs = false;
                        });
                      },
                      child: Center(
                        child: loadingSubs
                            ? Container(
                                width: 11,
                                height: 11,
                                margin: EdgeInsets.only(right: 3),
                                child: CircularProgressIndicator(
                                  color: Colors.grey,
                                  strokeWidth: 1.2,
                                ),
                              )
                            : const Icon(
                                Icons.autorenew,
                                size: 16,
                                color: Colors.grey,
                              ),
                      ),
                    ),
                  if (widget.subs.isNotEmpty)
                    GestureDetector(
                      onTap: widget.removeSubs,
                      child: Center(
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
              if (widget.ingredient.notes != null &&
                  widget.ingredient.notes!.trim().isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.notes, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        '${widget.ingredient.notes}',
                        style: TextStyles.inputedText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (widget.subs.isNotEmpty) const SizedBox(height: 6),
        ...List.generate(widget.subs.length, (i) {
          final sub = _displayIngredient(widget.subs[i]);

          return Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 25),
            child: ParsedIngredientPill(
              ingredient: sub,
              onSub: () async {},
              removeSubs: () {},
              subs: [],
              isSub: true,
              showSubOption: false,
              scale: widget.scale,
              unitSystem: widget.unitSystem,
            ),
          );
        }),
      ],
    );
  }
}
