import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String id; // firestore doc id (stable)
  final String name;
  final String category;
  final bool checked;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.name,
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
      name: data['name'] as String? ?? '',
      category: data['category'] as String? ?? 'Pantry',
      checked: data['checked'] as bool? ?? false,
      createdAt: dt(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category,
      'checked': checked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? checked,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      checked: checked ?? this.checked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
