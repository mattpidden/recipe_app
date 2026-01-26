import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recipe_app/classes/cookbook.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/classes/unit_value.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Notifier extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  UnitSystem _unitSystem = UnitSystem.original;
  UnitSystem get unitSystem => _unitSystem;
  static const _kUnitSystemKey = 'unitSystemPreference';
  bool isLoading = false;
  List<Recipe> recipes = [];
  List<Cookbook> cookbooks = [];
  List<String> partnerCodes = [];

  final List<String> allTags = [
    // Diet & Lifestyle
    'Vegan',
    'Vegetarian',
    'Pescatarian',
    'Flexitarian',
    'Keto',
    'Low Carb',
    'High Protein',
    'Paleo',
    'Whole30',
    'Gluten Free',
    'Dairy Free',
    'Nut Free',
    'Egg Free',
    'Soy Free',
    'Sugar Free',
    'Low Sugar',
    'Low Fat',
    'Low Calorie',
    'Heart Healthy',
    'Diabetic Friendly',
    'Plant Based',
    // Meal Type
    'Breakfast',
    'Brunch',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
    'Appetiser',
    'Side Dish',
    'Main Course',
    'Soup',
    'Salad',
    'Sandwich',
    'Wrap',
    'Bowl',
    'One Pot',
    'Family Meal',
    'Party Food',
    // Cuisine
    'Italian',
    'French',
    'Spanish',
    'Greek',
    'Mediterranean',
    'British',
    'Irish',
    'American',
    'Mexican',
    'Tex-Mex',
    'Caribbean',
    'Brazilian',
    'Peruvian',
    'Chinese',
    'Japanese',
    'Korean',
    'Thai',
    'Vietnamese',
    'Indian',
    'Pakistani',
    'Sri Lankan',
    'Middle Eastern',
    'Lebanese',
    'Turkish',
    'Moroccan',
    'African',
    'Ethiopian',
    'Nigerian',
    'South African',
    'Fusion',
    // Time & Effort
    'Quick',
    '10 Minutes',
    '15 Minutes',
    '20 Minutes',
    '30 Minutes',
    'Under 1 Hour',
    'Slow Cook',
    'Overnight',
    'Minimal Prep',
    'No Cook',
    'Make Ahead',
    'Freezer Friendly',
    'Batch Cook',
    // Difficulty / Skill
    'Beginner',
    'Easy',
    'Intermediate',
    'Advanced',
    'Chef Level',
    'Kid Friendly',
    'Student Friendly',
    // Cooking Method
    'Baked',
    'Roasted',
    'Fried',
    'Stir Fry',
    'Grilled',
    'BBQ',
    'Air Fryer',
    'Slow Cooker',
    'Pressure Cooker',
    'Instant Pot',
    'Steamed',
    'Poached',
    'Braised',
    'Smoked',
    'Raw',
    // Protein / Main Ingredient
    'Chicken',
    'Beef',
    'Pork',
    'Lamb',
    'Turkey',
    'Duck',
    'Fish',
    'Salmon',
    'Tuna',
    'Prawns',
    'Seafood',
    'Eggs',
    'Tofu',
    'Tempeh',
    'Beans',
    'Lentils',
    'Chickpeas',
    'Mushrooms',
    // Ingredient Focus
    'Cheese',
    'Pasta',
    'Rice',
    'Noodles',
    'Potatoes',
    'Sweet Potato',
    'Avocado',
    'Tomato',
    'Spinach',
    'Kale',
    'Courgette',
    'Aubergine',
    'Cauliflower',
    'Broccoli',
    'Peppers',
    'Onions',
    'Garlic',
    'Chilli',
    // Sweet / Baking
    'Baking',
    'Cake',
    'Cookies',
    'Brownies',
    'Pastry',
    'Bread',
    'Sourdough',
    'Muffins',
    'Pancakes',
    'Waffles',
    'No Bake',
    'Chocolate',
    'Fruit Based',
    // Seasonal / Occasion
    'Summer',
    'Winter',
    'Autumn',
    'Spring',
    'Christmas',
    'Easter',
    'Halloween',
    'Thanksgiving',
    'BBQ Season',
    'Picnic',
    'Comfort Food',
    'Date Night',
    // Lifestyle / Utility
    'Meal Prep',
    'Leftovers',
    'Budget',
    'Cheap Eats',
    'Healthy',
    'Indulgent',
    'Comfort',
    'Crowd Pleaser',
    'Light',
    'Filling',
  ];

  void updateUnitSystem(UnitSystem newPreference) async {
    _unitSystem = newPreference;
    notifyListeners();
    await _saveUnitSystemPreference(newPreference);
  }

  Future<void> _loadUnitSystemPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kUnitSystemKey);

    if (saved == null) return;

    final match = UnitSystem.values.where((e) => e.name == saved);
    if (match.isNotEmpty) {
      _unitSystem = match.first;
      notifyListeners();
    }
  }

  Future<void> _saveUnitSystemPreference(UnitSystem value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUnitSystemKey, value.name);
  }

  Notifier() {
    _loadUnitSystemPreference();
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
      // for each cookbook, add all the recipes with its id to its list
      cookbooks = cookbooksSnap.docs.map(Cookbook.fromFirestore).toList();
      for (Cookbook c in cookbooks) {
        final cRecipes = recipes
            .where((r) => (r.cookbookId ?? '') == c.id)
            .toList();
        c.recipes = cRecipes;
      }
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

  Future<void> deleteCookbook(String cookbookId) async {
    // optimistic local delete
    final cookbookIndex = cookbooks.indexWhere((r) => r.id == cookbookId);
    if (cookbookIndex == -1) return;
    final cookbook = cookbooks.removeAt(cookbookIndex);
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cookbooks')
          .doc(cookbookId)
          .delete();
    } catch (e) {
      // rollback on failure
      cookbooks.insert(cookbookIndex, cookbook);
      notifyListeners();
      rethrow;
    }
  }

  Future<Recipe?> addRecipe({
    required String title,
    String? id,
    String? description,
    List<String> imageUrls = const [],
    List<Ingredient> ingredients = const [],
    List<String> steps = const [],
    List<String> tags = const [],
    int? timeMinutes,
    int? servings,
    String sourceType = 'manual',
    String? sourceUrl,
    String? sourceAuthor,
    String? sourceTitle,
    String? cookbookId,
    int? pageNumber,
    String? notes,
    bool updateExisting = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    final cleanImages = imageUrls
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    final cleanTags = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final cleanSteps = steps
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final cleanIngredients = ingredients
        .where((i) => i.raw.trim().isNotEmpty)
        .toList();

    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc();

    final recipe = Recipe.create(
      id: updateExisting ? id! : ref.id,
      title: cleanTitle,
      description: (description?.trim().isEmpty ?? true)
          ? null
          : description!.trim(),
      imageUrls: cleanImages,
      ingredients: cleanIngredients,
      steps: cleanSteps,
      tags: cleanTags,
      timeMinutes: timeMinutes,
      servings: servings,
      sourceType: sourceType,
      sourceUrl: (sourceUrl?.trim().isEmpty ?? true) ? null : sourceUrl!.trim(),
      sourceAuthor: (sourceAuthor?.trim().isEmpty ?? true)
          ? null
          : sourceAuthor!.trim(),
      sourceTitle: (sourceTitle?.trim().isEmpty ?? true)
          ? null
          : sourceTitle!.trim(),
      cookbookId: (cookbookId?.trim().isEmpty ?? true)
          ? null
          : cookbookId!.trim(),
      pageNumber: pageNumber,
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
    );

    if (updateExisting) {
      await ref.delete();
      await updateRecipe(recipe);
      return recipe;
    }

    await ref.set(recipe.toFirestore());

    recipes = [...recipes, recipe];
    notifyListeners();

    return recipe;
  }

  Future<void> updateRecipe(Recipe recipeToUpdate) async {
    final recipeIndex = recipes.indexWhere((r) => r.id == recipeToUpdate.id);
    if (recipeIndex == -1) return;
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recipes')
          .doc(recipeToUpdate.id)
          .update(recipeToUpdate.toFirestore());
      recipes.removeAt(recipeIndex);
      recipes.add(recipeToUpdate);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    // optimistic local delete
    final recipeIndex = recipes.indexWhere((r) => r.id == recipeId);
    if (recipeIndex == -1) return;
    final recipe = recipes.removeAt(recipeIndex);
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('recipes')
          .doc(recipeId)
          .delete();
    } catch (e) {
      // rollback on failure
      recipes.insert(recipeIndex, recipe);
      notifyListeners();
      rethrow;
    }
  }

  bool matchRecipes(Recipe r, String q, Set<String> qTags) {
    final qq = q.trim().toLowerCase();

    // ---- TEXT MATCH ----
    bool textMatch = true;
    if (qq.isNotEmpty) {
      final title = r.title.toLowerCase();
      final desc = (r.description ?? '').toLowerCase();
      final ingredients = r.ingredients
          .map((i) => i.raw)
          .join(' ')
          .toLowerCase();

      textMatch =
          title.contains(qq) || desc.contains(qq) || ingredients.contains(qq);
    }

    // ---- TAG MATCH (exact) ----
    bool tagMatch = true;
    if (qTags.isNotEmpty) {
      final recipeTags = r.tags.map((t) => t.toLowerCase()).toSet();

      tagMatch = qTags.every((t) => recipeTags.contains(t.toLowerCase()));
    }

    return textMatch && tagMatch;
  }

  bool matchCookbooks(Cookbook c, String q, Set<String> qTags) {
    final qq = q.trim().toLowerCase();

    // text match against cookbook fields
    final title = c.title.toLowerCase();
    final desc = (c.description ?? '').toLowerCase();

    final bool cookbookTextMatch = qq.isEmpty
        ? true
        : (title.contains(qq) || desc.contains(qq));

    // recipe match: if any recipe matches both q and qTags, include cookbook
    final bool recipeMatch = c.recipes.any((r) => matchRecipes(r, q, qTags));

    // If query/tags are empty, this returns true (shows all)
    // Otherwise: match if cookbook matches directly OR any recipe matches
    return (cookbookTextMatch) || recipeMatch;
  }
}
