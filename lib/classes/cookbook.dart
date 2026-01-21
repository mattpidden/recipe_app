import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/classes/recipe.dart';

class Cookbook {
  final String id;
  final String? isbn;

  final String title;
  final String? author;
  final String? description;

  final String? coverImageUrl;

  // Optional “nice to have” fields for UI sorting / stats
  final DateTime? lastCookedAt;
  final int? recipeCount; // optional denormalised

  final DateTime createdAt;
  final DateTime updatedAt;

  List<Recipe> recipes = [];

  Cookbook({
    required this.id,
    required this.title,
    this.isbn,
    this.author,
    this.description,
    this.coverImageUrl,
    this.lastCookedAt,
    this.recipeCount,
    required this.createdAt,
    required this.updatedAt,
    this.recipes = const [],
  });

  // ---------- Firestore ----------

  static Cookbook fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? dt(dynamic v) =>
        v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

    final createdAt = dt(data['createdAt']) ?? DateTime.now();
    final updatedAt = dt(data['updatedAt']) ?? createdAt;

    return Cookbook(
      id: doc.id,
      title: data['title'] as String? ?? '',
      isbn: data['isbn'] as String?,
      author: data['author'] as String?,
      description: data['description'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      lastCookedAt: dt(data['lastCookedAt']),
      recipeCount: (data['recipeCount'] as num?)?.toInt(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    Timestamp ts(DateTime d) => Timestamp.fromDate(d);

    return {
      'title': title,
      if (isbn != null) 'isbn': isbn,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
      if (lastCookedAt != null) 'lastCookedAt': ts(lastCookedAt!),
      if (recipeCount != null) 'recipeCount': recipeCount,
      'createdAt': ts(createdAt),
      'updatedAt': ts(updatedAt),
    };
  }

  // ---------- Helpers ----------

  Cookbook copyWith({
    String? title,
    String? isbn,
    String? author,
    String? description,
    String? coverImageUrl,
    DateTime? lastCookedAt,
    int? recipeCount,
    DateTime? updatedAt,
    List<Recipe>? recipes,
  }) {
    return Cookbook(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      author: author ?? this.author,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      lastCookedAt: lastCookedAt ?? this.lastCookedAt,
      recipeCount: recipeCount ?? this.recipeCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recipes: recipes ?? this.recipes,
    );
  }

  factory Cookbook.create({
    required String id,
    required String title,
    String? isbn,
    String? author,
    String? description,
    String? coverImageUrl,
  }) {
    final now = DateTime.now();
    return Cookbook(
      id: id,
      isbn: isbn,
      title: title,
      author: author,
      description: description,
      coverImageUrl: coverImageUrl,
      createdAt: now,
      updatedAt: now,
    );
  }
}
