import 'package:cloud_firestore/cloud_firestore.dart';
import 'ingredient.dart';

class Recipe {
  final String id;

  final String title;
  final String? description;
  final List<String> imageUrls;

  final List<Ingredient> ingredients;
  final List<String> steps;
  final List<String> tags;

  final int? timeMinutes;
  final int? servings;

  // Source
  final String
  sourceType; // cookbook | url | tiktok | instagram | My Own Recipe
  final String? sourceUrl;
  final String? sourceAuthor;
  final String? sourceTitle;

  // Cookbook link
  final String? cookbookId;
  final int? pageNumber;

  // User data
  final String? notes; // general recipe notes
  final int cookCount;
  final int? lastRating;
  final DateTime? lastCookedAt;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.title,
    this.description,
    this.imageUrls = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.tags = const [],
    this.timeMinutes,
    this.servings,
    this.sourceType = 'My Own Recipe',
    this.sourceUrl,
    this.sourceAuthor,
    this.sourceTitle,
    this.cookbookId,
    this.pageNumber,
    this.notes,
    this.cookCount = 0,
    this.lastRating,
    this.lastCookedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------- Firestore ----------

  static Recipe fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime? dt(dynamic v) =>
        v is Timestamp ? v.toDate() : (v is DateTime ? v : null);

    List<Ingredient> ingredientList(dynamic v) {
      if (v is! List) return const [];
      return v
          .whereType<Map<String, dynamic>>()
          .map(Ingredient.fromMap)
          .toList();
    }

    List<String> strList(dynamic v) {
      if (v is! List) return const [];
      return v.whereType<String>().toList();
    }

    final createdAt = dt(data['createdAt']) ?? DateTime.now();
    final updatedAt = dt(data['updatedAt']) ?? createdAt;

    return Recipe(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      imageUrls: strList(data['imageUrls']),
      ingredients: ingredientList(data['ingredients']),
      steps: strList(data['steps']),
      tags: strList(data['tags']),
      timeMinutes: (data['timeMinutes'] as num?)?.toInt(),
      servings: (data['servings'] as num?)?.toInt(),
      sourceType: data['sourceType'] as String? ?? 'My Own Recipe',
      sourceUrl: data['sourceUrl'] as String?,
      sourceAuthor: data['sourceAuthor'] as String?,
      sourceTitle: data['sourceTitle'] as String?,
      cookbookId: data['cookbookId'] as String?,
      pageNumber: (data['pageNumber'] as num?)?.toInt(),
      notes: data['notes'] as String?,
      cookCount: (data['cookCount'] as num?)?.toInt() ?? 0,
      lastRating: (data['lastRating'] as num?)?.toInt(),
      lastCookedAt: dt(data['lastCookedAt']),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    Timestamp ts(DateTime d) => Timestamp.fromDate(d);

    return {
      'title': title,
      if (description != null) 'description': description,
      'imageUrls': imageUrls,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'steps': steps,
      'tags': tags,
      if (timeMinutes != null) 'timeMinutes': timeMinutes,
      if (servings != null) 'servings': servings,
      'sourceType': sourceType,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (sourceAuthor != null) 'sourceAuthor': sourceAuthor,
      if (sourceTitle != null) 'sourceTitle': sourceTitle,
      if (cookbookId != null) 'cookbookId': cookbookId,
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (notes != null) 'notes': notes,
      'cookCount': cookCount,
      if (lastRating != null) 'lastRating': lastRating,
      if (lastCookedAt != null) 'lastCookedAt': ts(lastCookedAt!),
      'createdAt': ts(createdAt),
      'updatedAt': ts(updatedAt),
    };
  }

  // ---------- Helpers ----------

  Recipe copyWith({
    String? title,
    String? description,
    List<String>? imageUrls,
    List<Ingredient>? ingredients,
    List<String>? steps,
    List<String>? tags,
    int? timeMinutes,
    int? servings,
    String? sourceType,
    String? sourceUrl,
    String? sourceAuthor,
    String? sourceTitle,
    String? cookbookId,
    int? pageNumber,
    String? notes,
    int? cookCount,
    int? lastRating,
    DateTime? lastCookedAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      tags: tags ?? this.tags,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      servings: servings ?? this.servings,
      sourceType: sourceType ?? this.sourceType,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceAuthor: sourceAuthor ?? this.sourceAuthor,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      cookbookId: cookbookId ?? this.cookbookId,
      pageNumber: pageNumber ?? this.pageNumber,
      notes: notes ?? this.notes,
      cookCount: cookCount ?? this.cookCount,
      lastRating: lastRating ?? this.lastRating,
      lastCookedAt: lastCookedAt ?? this.lastCookedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Recipe.create({
    required String id,
    required String title,
    String? description,
    List<String> imageUrls = const [],
    List<Ingredient> ingredients = const [],
    List<String> steps = const [],
    List<String> tags = const [],
    int? timeMinutes,
    int? servings,
    String sourceType = 'My Own Recipe',
    String? sourceUrl,
    String? sourceAuthor,
    String? sourceTitle,
    String? cookbookId,
    int? pageNumber,
    String? notes,
  }) {
    final now = DateTime.now();
    return Recipe(
      id: id,
      title: title,
      description: description,
      imageUrls: imageUrls,
      ingredients: ingredients,
      steps: steps,
      tags: tags,
      timeMinutes: timeMinutes,
      servings: servings,
      sourceType: sourceType,
      sourceUrl: sourceUrl,
      sourceAuthor: sourceAuthor,
      sourceTitle: sourceTitle,
      cookbookId: cookbookId,
      pageNumber: pageNumber,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }
}
