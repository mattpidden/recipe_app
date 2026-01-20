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
      id: ref.id,
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

    await ref.set(recipe.toFirestore());

    recipes = [...recipes, recipe];
    notifyListeners();

    return recipe;
  }
}
