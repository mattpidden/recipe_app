import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recipe_app/classes/cookbook.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/classes/recipe.dart';

class Notifier extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  List<Recipe> recipes = [];
  List<Cookbook> cookbooks = [];
  List<String> partnerCodes = [];

  bool isLoading = false;

  Notifier() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        refresh();
      } else {
        recipes = [];
        cookbooks = [];
        notifyListeners();
      }
    });
  }

  Future<void> refresh() async {
    final user = _auth.currentUser;
    if (user == null) {
      recipes = [];
      cookbooks = [];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      final recipesSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('recipes')
          .get();

      final cookbooksSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('cookbooks')
          .get();

      recipes = recipesSnap.docs.map(Recipe.fromFirestore).toList();
      cookbooks = cookbooksSnap.docs.map(Cookbook.fromFirestore).toList();
    } catch (_) {
      // If anything goes wrong, keep it safe and empty for now
      recipes = [];
      cookbooks = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Cookbook?> addCookbook({
    required String title,
    String? author,
    String? description,
    String? coverImageUrl,
    String? isbn,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('cookbooks')
        .doc();

    final cookbook = Cookbook.create(
      id: ref.id,
      title: title,
      author: author,
      description: description,
      coverImageUrl: coverImageUrl,
      isbn: isbn,
    );

    await ref.set(cookbook.toFirestore());

    cookbooks = [...cookbooks, cookbook];
    notifyListeners();

    return cookbook;
  }

  Future<Recipe?> addRecipe({
    required String title,
    List<Ingredient> ingredients = const [],
    List<String> steps = const [],
    String sourceType = 'manual',
    String? cookbookId,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc();

    final recipe = Recipe.create(
      id: ref.id,
      title: title,
      ingredients: ingredients,
      steps: steps,
      sourceType: sourceType,
      cookbookId: cookbookId,
    ).copyWith(imageUrl: imageUrl);

    await ref.set(recipe.toFirestore());

    recipes = [...recipes, recipe];
    notifyListeners();

    return recipe;
  }
}
