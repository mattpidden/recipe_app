import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/classes/ingredient.dart';

class ShoppingItem {
  final String id; // firestore doc id (stable)
  final Ingredient ingredient;
  final String? recipeId;
  final String category;
  final bool checked;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.ingredient,
    this.recipeId,
    required this.category,
    required this.checked,
    required this.createdAt,
  });

  static ShoppingItem fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime? dt(dynamic v) =>
        v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

    return ShoppingItem(
      id: doc.id,
      ingredient: Ingredient.fromMap(
        (data['ingredient'] as Map<String, dynamic>? ?? {}),
      ),
      recipeId: data['recipeId'] as String?,
      category: data['category'] as String? ?? 'Pantry',
      checked: data['checked'] as bool? ?? false,
      createdAt: dt(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ingredient': ingredient.toMap(),
      'recipeId': recipeId,
      'category': category,
      'checked': checked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ShoppingItem copyWith({
    String? id,
    Ingredient? ingredient,
    String? recipeId,
    String? category,
    bool? checked,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      ingredient: ingredient ?? this.ingredient,
      recipeId: recipeId ?? this.recipeId,
      category: category ?? this.category,
      checked: checked ?? this.checked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
