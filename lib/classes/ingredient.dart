class Ingredient {
  final String raw; // always required, source of truth

  final double? quantity;
  final String? unit; // e.g. "tbsp", "g"
  final String? item; // e.g. "olive oil"
  final String? notes; // e.g. "optional", "finely chopped"

  const Ingredient({
    required this.raw,
    this.quantity,
    this.unit,
    this.item,
    this.notes,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      raw: map['raw'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble(),
      unit: map['unit'] as String?,
      item: map['item'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'raw': raw,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (item != null) 'item': item,
      if (notes != null) 'notes': notes,
    };
  }
}
