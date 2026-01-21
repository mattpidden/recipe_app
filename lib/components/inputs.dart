import 'package:flutter/material.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const Input({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: TextStyles.inputedText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyles.inputText,
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          iconEnabledColor: AppColors.primaryTextColour,
          dropdownColor: Colors.white,
          style: TextStyles.inputText,
          items: items
              .map((x) => DropdownMenuItem<String>(value: x, child: Text(x)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class CookbookDropdown extends StatelessWidget {
  final String? value;
  final List<dynamic>
  cookbooks; // keep dynamic to avoid needing Cookbook import here
  final ValueChanged<String?> onChanged;

  const CookbookDropdown({
    required this.value,
    required this.cookbooks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          iconEnabledColor: AppColors.primaryTextColour,
          style: TextStyles.inputText,
          hint: const Text('Cookbook (optional)', style: TextStyles.inputText),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('None')),
            ...cookbooks.map((c) {
              return DropdownMenuItem<String?>(
                value: c.id as String,
                child: Text(
                  (c.title as String?) ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
