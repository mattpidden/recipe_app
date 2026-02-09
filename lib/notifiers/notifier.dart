import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recipe_app/classes/cookbook.dart';
import 'package:recipe_app/classes/cookevent.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/classes/plannedmeal.dart';
import 'package:recipe_app/classes/recipe.dart';
import 'package:recipe_app/classes/shoppingitem.dart';
import 'package:recipe_app/classes/unit_value.dart';
import 'package:recipe_app/notifiers/ingred_catergories.dart';
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
  List<CookEvent> cookHistory = [];
  List<String> partnerCodes = [];
  List<PlannedMeal> plannedMeals = [];
  List<ShoppingItem> shoppingListItems = [];

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
    print("notifier");
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
    print("Refreshing data from Firestore...");
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

      final cookEventsSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('cookhistory')
          .get();

      final planSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('plannedmeals')
          .get();

      final listSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('shoppinglist')
          .get();

      recipes = recipesSnap.docs.map(Recipe.fromFirestore).toList();
      // for each cookbook, add all the recipes with its id to its list
      cookbooks = cookbooksSnap.docs.map(Cookbook.fromFirestore).toList();
      cookHistory = cookEventsSnap.docs.map(CookEvent.fromFirestore).toList();
      plannedMeals = planSnap.docs.map(PlannedMeal.fromFirestore).toList();
      shoppingListItems = listSnap.docs
          .map(ShoppingItem.fromFirestore)
          .toList();
      for (Cookbook c in cookbooks) {
        final cRecipes = recipes
            .where((r) => (r.cookbookId ?? '') == c.id)
            .toList();
        c.recipes = cRecipes;
      }
      await ensureAutoPlanNext7Days();
    } catch (_) {
      // If anything goes wrong, keep it safe and empty for now
      recipes = [];
      cookbooks = [];
      cookHistory = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  DateTime get _today => _dateOnly(DateTime.now());

  PlannedMeal? get plannedMealToday {
    final d = _today;

    PlannedMeal? committed;
    PlannedMeal? suggested;

    for (final pm in plannedMeals) {
      if (_dateOnly(pm.day) != d) continue;

      if (pm.status == PlannedMealStatus.committed) {
        committed = pm;
        break;
      }
      if (pm.status == PlannedMealStatus.suggested) {
        suggested ??= pm;
      }
    }

    return committed ?? suggested;
  }

  Future<void> addToShoppingList(Ingredient ingred) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('shoppinglist')
        .doc();

    final newItem = ShoppingItem(
      id: ref.id,
      createdAt: DateTime.now(),
      ingredient: ingred,
      category: categoryForIngredient(ingred),
      checked: false,
    );

    shoppingListItems = [...shoppingListItems, newItem];
    notifyListeners();

    await ref.set(newItem.toFirestore());
  }

  Future<void> deleteFromShoppingList(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    shoppingListItems = shoppingListItems.where((x) => x.id != id).toList();
    notifyListeners();

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('shoppinglist')
        .doc(id)
        .delete();
  }

  Future<void> clearShoppingList() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _db.batch();
    final col = _db
        .collection('users')
        .doc(user.uid)
        .collection('shoppinglist');

    for (final it in shoppingListItems) {
      batch.delete(col.doc(it.id));
    }

    shoppingListItems = [];
    notifyListeners();

    await batch.commit();
  }

  Future<void> toggleShoppingItem(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final i = shoppingListItems.indexWhere((x) => x.id == id);
    if (i == -1) return;

    final item = shoppingListItems[i];
    final updated = item.copyWith(checked: !item.checked);

    shoppingListItems[i] = updated;
    notifyListeners();

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('shoppinglist')
        .doc(id)
        .update({'checked': updated.checked});
  }

  String stableIdForIngredient(Ingredient ing) {
    final key = (ing.item?.isNotEmpty ?? false) ? ing.item! : ing.raw;
    return key
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  /// Helper: Converts an ingredient quantity to grams using unit conversion + density lookup.
  /// Returns null if conversion is not possible.
  double? _gramsForIngredient(Ingredient ing) {
    if (ing.quantity == null) return null;
    final canon = UnitConverter.normalizeUnit(ing.unit);
    if (canon == null) return null;

    final uv = UnitConverter.convert(
      ing.quantity!,
      ing.unit,
      UnitSystem.metric,
      ingredient: ing.item ?? ing.raw,
    );
    if (uv.qty == null || uv.unit == null) return null;

    switch (uv.unit) {
      case 'g':
        return uv.qty;
      case 'kg':
        return uv.qty! * 1000.0;
      case 'ml':
        final dens = UnitConverter.densityOf(ing.item ?? ing.raw);
        if (dens == null) return null;
        return uv.qty! * dens.gPerMl;
      case 'l':
        final dens = UnitConverter.densityOf(ing.item ?? ing.raw);
        if (dens == null) return null;
        return uv.qty! * 1000.0 * dens.gPerMl;
      default:
        return null;
    }
  }

  /// Helper: Attempts to merge a new ingredient into an existing ShoppingItem.
  /// Returns the merged ShoppingItem if merge succeeds, or null if no merge is possible.
  ShoppingItem? _tryMergeIngredient(ShoppingItem existing, Ingredient ing) {
    // If both have the same canonical unit (e.g., both 'tbsp' or both 'ml'), sum directly and keep that unit
    final enCan = UnitConverter.normalizeUnit(existing.ingredient.unit);
    final inCan = UnitConverter.normalizeUnit(ing.unit);
    if (enCan != null &&
        inCan != null &&
        enCan == inCan &&
        existing.ingredient.quantity != null &&
        ing.quantity != null) {
      final sum = (existing.ingredient.quantity ?? 0) + (ing.quantity ?? 0);
      final mergedIngredient = Ingredient(
        raw: existing.ingredient.raw,
        quantity: sum,
        unit: existing.ingredient.unit,
        item: existing.ingredient.item ?? ing.item,
        notes: existing.ingredient.notes ?? ing.notes,
      );

      return existing.copyWith(
        ingredient: mergedIngredient,
        recipeId: null,
        createdAt: existing.createdAt,
      );
    }

    // Case: Both have no recognized unit (null) — merge by summing quantities
    if (enCan == null && inCan == null) {
      // If both have quantities, sum them. If both lack quantities, just mark as needed (no count)
      final existingHasQty = existing.ingredient.quantity != null;
      final newHasQty = ing.quantity != null;

      double? sum;
      if (existingHasQty && newHasQty) {
        sum = (existing.ingredient.quantity ?? 0) + (ing.quantity ?? 0);
      } else if (existingHasQty || newHasQty) {
        // One has qty, one doesn't — use the one that has it
        sum = existing.ingredient.quantity ?? ing.quantity;
      }
      // else: neither has qty, sum stays null

      final mergedIngredient = Ingredient(
        raw: existing.ingredient.raw,
        quantity: sum,
        unit: existing.ingredient.unit,
        item: existing.ingredient.item ?? ing.item,
        notes: existing.ingredient.notes ?? ing.notes,
      );

      return existing.copyWith(
        ingredient: mergedIngredient,
        recipeId: null,
        createdAt: existing.createdAt,
      );
    }

    // Try to merge quantities where possible by converting to grams (when density/units allow)
    final existingGrams = _gramsForIngredient(existing.ingredient);
    final newGrams = _gramsForIngredient(ing);

    if (existingGrams != null && newGrams != null) {
      final total = existingGrams + newGrams;
      final mergedIngredient = Ingredient(
        raw: existing.ingredient.raw,
        quantity: total,
        unit: 'g',
        item: existing.ingredient.item ?? ing.item,
        notes: existing.ingredient.notes ?? ing.notes,
      );

      return existing.copyWith(
        ingredient: mergedIngredient,
        recipeId: null,
        createdAt: existing.createdAt,
      );
    }

    // Could not merge
    return null;
  }

  /// Adds all ingredients from a recipe to the shopping list, merging with existing items.
  Future<void> addRecipeIngredientsToShoppingList(String recipeId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Find the recipe
    final recipe = recipes.firstWhere(
      (r) => r.id == recipeId,
      orElse: () => Recipe.create(id: 'x', title: ''),
    );
    if (recipe.id == 'x') return;

    final existingById = {for (final i in shoppingListItems) i.id: i};
    final toUpsert = <String, ShoppingItem>{};

    for (final ing in recipe.ingredients) {
      final id = stableIdForIngredient(ing);
      if (id.isEmpty) continue;

      final existing = toUpsert[id] ?? existingById[id];

      if (existing == null) {
        toUpsert[id] = ShoppingItem(
          id: id,
          ingredient: ing,
          recipeId: recipe.id,
          category: categoryForIngredient(ing),
          checked: false,
          createdAt: DateTime.now(),
        );
        continue;
      }

      // Try to merge
      final merged = _tryMergeIngredient(existing, ing);
      if (merged != null) {
        toUpsert[id] = merged;
        continue;
      }

      // Could not merge cleanly — create a separate entry so we don't lose quantities
      var newId = id;
      var suffix = 1;
      while (toUpsert.containsKey(newId) || existingById.containsKey(newId)) {
        newId = '$id#${suffix++}';
      }

      toUpsert[newId] = ShoppingItem(
        id: newId,
        ingredient: ing,
        recipeId: recipe.id,
        category: categoryForIngredient(ing),
        checked: existing?.checked ?? false,
        createdAt: DateTime.now(),
      );
    }

    if (toUpsert.isEmpty) return;

    final merged = {...existingById, ...toUpsert};

    shoppingListItems = merged.values.toList()
      ..sort((a, b) {
        final c = a.category.compareTo(b.category);
        if (c != 0) return c;
        return a.ingredient.raw.toLowerCase().compareTo(
          b.ingredient.raw.toLowerCase(),
        );
      });

    notifyListeners();

    final batch = _db.batch();
    final col = _db
        .collection('users')
        .doc(user.uid)
        .collection('shoppinglist');

    for (final item in toUpsert.values) {
      batch.set(col.doc(item.id), item.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> convertPlanToShoppingList() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = _dateOnly(DateTime.now());

    final committed = plannedMeals.where(
      (pm) =>
          pm.status == PlannedMealStatus.committed &&
          !_dateOnly(pm.day).isBefore(today),
    );

    final existingById = {for (final i in shoppingListItems) i.id: i};
    final toUpsert = <String, ShoppingItem>{};

    for (final pm in committed) {
      final r = recipes.firstWhere(
        (x) => x.id == pm.recipeId,
        orElse: () => Recipe.create(id: 'x', title: ''),
      );
      if (r.id == 'x') continue;

      for (final ing in r.ingredients) {
        final id = stableIdForIngredient(ing);
        if (id.isEmpty) continue;

        final existing = toUpsert[id] ?? existingById[id];

        if (existing == null) {
          toUpsert[id] = ShoppingItem(
            id: id,
            ingredient: ing,
            recipeId: r.id,
            category: categoryForIngredient(ing),
            checked: false,
            createdAt: DateTime.now(),
          );
          continue;
        }

        // Try to merge using helper
        final merged = _tryMergeIngredient(existing, ing);
        if (merged != null) {
          toUpsert[id] = merged;
          continue;
        }

        // Could not merge cleanly — create a separate entry so we don't lose quantities
        var newId = id;
        var suffix = 1;
        while (toUpsert.containsKey(newId) || existingById.containsKey(newId)) {
          newId = '$id#${suffix++}';
        }

        toUpsert[newId] = ShoppingItem(
          id: newId,
          ingredient: ing,
          recipeId: r.id,
          category: categoryForIngredient(ing),
          checked: existing?.checked ?? false,
          createdAt: DateTime.now(),
        );
      }
    }

    if (toUpsert.isEmpty) return;

    final merged = {...existingById, ...toUpsert};

    shoppingListItems = merged.values.toList()
      ..sort((a, b) {
        final c = a.category.compareTo(b.category);
        if (c != 0) return c;
        return a.ingredient.raw.toLowerCase().compareTo(
          b.ingredient.raw.toLowerCase(),
        );
      });

    notifyListeners();

    final batch = _db.batch();
    final col = _db
        .collection('users')
        .doc(user.uid)
        .collection('shoppinglist');

    for (final item in toUpsert.values) {
      batch.set(col.doc(item.id), item.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> ensureAutoPlanNext7Days() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = _dateOnly(DateTime.now());
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    final rng = Random();

    // Only 1 dinner per day. If already has committed OR suggested dinner, skip.
    bool hasMealOnDay(DateTime day) {
      return plannedMeals.any(
        (pm) => _dateOnly(pm.day) == day && pm.meal == 'dinner',
      );
    }

    // Build candidates
    final candidates = [...recipes];
    if (candidates.isEmpty) return;

    // Basic scoring: prefer wouldMakeAgain / high rating / recently cooked / quick weekday
    double score(Recipe r, DateTime day) {
      double s = 0;

      // quick midweek bias
      final isWeekday = day.weekday <= 5;
      final t = r.timeMinutes ?? 999;
      if (isWeekday && t <= 35) s += 3;
      if (!isWeekday && t <= 60) s += 1;

      // cooked stats
      if (r.lastRating != null) s += (r.lastRating! - 3) * 1.2;
      if (r.lastCookedAt != null) {
        final daysAgo = DateTime.now().difference(r.lastCookedAt!).inDays;
        if (daysAgo <= 14) s += 2.0;
        if (daysAgo >= 90) s += 1.0; // nice to resurface older stuff
      }

      // tag nudges (optional)
      if (r.tags.any((t) => t.toLowerCase() == 'quick')) s += 1.0;

      return s;
    }

    // Weighted pick (higher score = more likely), with a bit of jitter so plans vary
    Recipe weightedPick(List<Recipe> options, DateTime day) {
      const temperature =
          5.0; // higher = more random, lower = more deterministic
      final weights = options.map((r) {
        final s = score(r, day);

        // jitter breaks ties + avoids same plan every open
        final jitter = (rng.nextDouble() - 0.5) * 0.6; // [-0.3, +0.3]

        // softmax-ish weight
        return exp((s + jitter) / temperature);
      }).toList();

      final total = weights.fold<double>(0, (a, b) => a + b);
      var roll = rng.nextDouble() * total;

      for (var i = 0; i < options.length; i++) {
        roll -= weights[i];
        if (roll <= 0) return options[i];
      }
      return options.last;
    }

    String reasonFor(Recipe r, DateTime day) {
      final isWeekday = day.weekday <= 5;
      final t = r.timeMinutes;

      if (r.lastRating != null &&
          r.lastRating! >= 5 &&
          r.lastCookedAt != null) {
        final daysAgo = DateTime.now().difference(r.lastCookedAt!).inDays;
        if (daysAgo <= 14) return 'You rated this 5 stars recently';
      }
      if (isWeekday && t != null && t <= 35)
        return 'Quick prep meal for midweek';
      if (!isWeekday && t != null && t <= 60) return 'Good weekend cook';
      if (t != null) return '${t} min dinner idea';
      return 'Suggested for your plan';
    }

    // Don’t repeat same recipe twice in the 7-day suggestions (unless needed)
    final usedRecipeIds = plannedMeals
        .where((pm) => days.contains(_dateOnly(pm.day)))
        .map((pm) => pm.recipeId)
        .toSet();

    final toCreate = <PlannedMeal>[];

    for (final day in days) {
      if (hasMealOnDay(day)) continue;

      // Only choose from recipes not already used in this 7-day window
      final available = candidates
          .where((r) => !usedRecipeIds.contains(r.id))
          .toList();

      // If user has fewer recipes than empty days, we simply stop adding (no duplicates)
      if (available.isEmpty) continue;

      final pick = weightedPick(available, day);
      usedRecipeIds.add(pick.id);

      final ref = _db
          .collection('users')
          .doc(user.uid)
          .collection('plannedmeals')
          .doc();

      toCreate.add(
        PlannedMeal(
          id: ref.id,
          recipeId: pick.id,
          day: day,
          meal: 'dinner',
          status: PlannedMealStatus.suggested,
          reason: reasonFor(pick, day),
          createdAt: DateTime.now(),
        ),
      );
    }

    if (toCreate.isEmpty) return;

    // optimistic local
    plannedMeals = [...plannedMeals, ...toCreate];
    notifyListeners();

    // write
    final batch = _db.batch();
    for (final pm in toCreate) {
      final ref = _db
          .collection('users')
          .doc(user.uid)
          .collection('plannedmeals')
          .doc(pm.id);
      batch.set(ref, pm.toFirestore());
    }
    await batch.commit();
  }

  Future<void> addPlannedDinnerForDay({
    DateTime? day,
    required String recipeId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // If day is null, find the first day without a committed recipe
    DateTime targetDay;
    if (day == null) {
      final today = _dateOnly(DateTime.now());
      targetDay = today;

      // Find first day without a committed dinner
      while (plannedMeals.any(
        (pm) =>
            _dateOnly(pm.day) == targetDay &&
            pm.meal == 'dinner' &&
            pm.status == PlannedMealStatus.committed,
      )) {
        targetDay = targetDay.add(const Duration(days: 1));
      }
    } else {
      targetDay = _dateOnly(day);
    }

    // Find any suggested recipe for this day and remove it
    PlannedMeal? suggestedToRemove;
    for (final pm in plannedMeals) {
      if (_dateOnly(pm.day) == targetDay &&
          pm.meal == 'dinner' &&
          pm.status == PlannedMealStatus.suggested) {
        suggestedToRemove = pm;
        break;
      }
    }

    if (suggestedToRemove != null) {
      plannedMeals = plannedMeals
          .where((pm) => pm.id != suggestedToRemove!.id)
          .toList();
    }

    // Check if there's already a committed dinner
    final alreadyHasCommitted = plannedMeals.any(
      (pm) =>
          _dateOnly(pm.day) == targetDay &&
          pm.meal == 'dinner' &&
          pm.status == PlannedMealStatus.committed,
    );
    if (alreadyHasCommitted) return;

    final ref = _db
        .collection('users')
        .doc(user.uid)
        .collection('plannedmeals')
        .doc();

    final pm = PlannedMeal(
      id: ref.id,
      recipeId: recipeId,
      day: targetDay,
      meal: 'dinner',
      status: PlannedMealStatus.committed,
      reason: 'Added by you',
      createdAt: DateTime.now(),
    );

    plannedMeals = [...plannedMeals, pm];
    notifyListeners();

    // Batch delete suggested and add new committed
    final batch = _db.batch();
    if (suggestedToRemove != null) {
      batch.delete(
        _db
            .collection('users')
            .doc(user.uid)
            .collection('plannedmeals')
            .doc(suggestedToRemove.id),
      );
    }

    batch.set(ref, pm.toFirestore());
    await batch.commit();
  }

  Future<void> acceptPlannedMeal(String plannedMealId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final i = plannedMeals.indexWhere((p) => p.id == plannedMealId);
    if (i == -1) return;

    final updated = plannedMeals[i].copyWith(
      status: PlannedMealStatus.committed,
    );
    plannedMeals[i] = updated;
    notifyListeners();

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('plannedmeals')
        .doc(plannedMealId)
        .update({'status': 'committed'});
  }

  Future<void> removePlannedMeal(String plannedMealId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    plannedMeals.removeWhere((p) => p.id == plannedMealId);
    notifyListeners();

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('plannedmeals')
        .doc(plannedMealId)
        .delete();
  }

  Future<void> movePlannedMeal(String plannedMealId, DateTime newDay) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final d = _dateOnly(newDay);

    // enforce 1 dinner per day
    // final already = plannedMeals.any(
    //   (p) =>
    //       _dateOnly(p.day) == d && p.meal == 'dinner' && p.id != plannedMealId,
    // );
    // if (already) return;

    final i = plannedMeals.indexWhere((p) => p.id == plannedMealId);
    if (i == -1) return;

    final updated = plannedMeals[i].copyWith(day: d);
    plannedMeals[i] = updated;
    notifyListeners();

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('plannedmeals')
        .doc(plannedMealId)
        .update({'day': Timestamp.fromDate(d)});
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
    // loop over recipes, and remove cookbookId from any that have it (don’t delete the recipes, just unassign from deleted cookbook)
    for (Recipe recipe in recipes) {
      if (recipe.cookbookId == cookbookId) {
        updateRecipeFromForm(
          id: recipe.id,
          title: recipe.title,
          cookbookId: null,
        );
      }
    }
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

  Future<Recipe?> updateRecipeFromForm({
    required String id,
    required String title,
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
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final idx = recipes.indexWhere((r) => r.id == id);
    if (idx == -1) return null;

    final old = recipes[idx];

    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;

    // Only update fields that were explicitly provided
    final cleanImages = imageUrls != null
        ? imageUrls.map((u) => u.trim()).where((u) => u.isNotEmpty).toList()
        : null;
    final cleanTags = tags != null
        ? tags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : null;
    final cleanSteps = steps != null
        ? steps.map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : null;
    final cleanIngredients = ingredients != null
        ? ingredients.where((i) => i.raw.trim().isNotEmpty).toList()
        : null;

    final updated = old.copyWith(
      title: cleanTitle,
      description: description != null
          ? (description.trim().isEmpty ? null : description.trim())
          : null,
      imageUrls: cleanImages,
      ingredients: cleanIngredients,
      steps: cleanSteps,
      tags: cleanTags,
      timeMinutes: timeMinutes,
      servings: servings,
      sourceType: sourceType,
      sourceUrl: sourceUrl != null
          ? (sourceUrl.trim().isEmpty ? null : sourceUrl.trim())
          : null,
      sourceAuthor: sourceAuthor != null
          ? (sourceAuthor.trim().isEmpty ? null : sourceAuthor.trim())
          : null,
      sourceTitle: sourceTitle != null
          ? (sourceTitle.trim().isEmpty ? null : sourceTitle.trim())
          : null,
      cookbookId: cookbookId != null
          ? (cookbookId.trim().isEmpty ? null : cookbookId.trim())
          : null,
      pageNumber: pageNumber,
      notes: notes != null
          ? (notes.trim().isEmpty ? null : notes.trim())
          : null,
      updatedAt: DateTime.now(),
    );

    // optimistic local update
    recipes[idx] = updated;
    notifyListeners();

    // IMPORTANT: don't overwrite createdAt / cookCount etc; using update() is safest
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('recipes')
        .doc(id)
        .update(updated.toFirestore());

    return updated;
  }

  Future<void> deleteRecipe(String recipeId) async {
    // optimistic local delete
    final recipeIndex = recipes.indexWhere((r) => r.id == recipeId);
    if (recipeIndex == -1) return;
    final recipe = recipes.removeAt(recipeIndex);
    // remove recipe from any cookbooks.recipes list that might contain it
    for (Cookbook c in cookbooks) {
      c.recipes.removeWhere((r) => r.id == recipeId);
    }
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

  Future<void> addCookedEvent({
    required String recipeId,
    required int rating, // 1..5
    String? comment,
    String? occasion,
    List<String> withWho = const [],
    bool? wouldMakeAgain,
    DateTime? cookedAt,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final rIndex = recipes.indexWhere((r) => r.id == recipeId);
    if (rIndex == -1) return;

    final recipe = recipes[rIndex];
    final now = cookedAt ?? DateTime.now();

    final cleanComment = (comment?.trim().isEmpty ?? true)
        ? null
        : comment!.trim();
    final cleanOccasion = (occasion?.trim().isEmpty ?? true)
        ? null
        : occasion!.trim();
    final cleanWithWho = withWho
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final historyRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('cookhistory')
        .doc();

    final event = CookEvent(
      id: historyRef.id,
      recipeId: recipeId,
      cookbookId: recipe.cookbookId,
      cookedAt: now,
      rating: rating.clamp(1, 5),
      comment: cleanComment,
      occasion: cleanOccasion,
      withWho: cleanWithWho,
      wouldMakeAgain: wouldMakeAgain,
    );

    // build updated recipe
    final updatedRecipe = recipe.copyWith(
      cookCount: recipe.cookCount + 1,
      lastRating: event.rating,
      lastCookedAt: now,
      updatedAt: DateTime.now(),
    );

    // maybe update cookbook stats too
    Cookbook? updatedCookbook;
    int cIndex = -1;
    if (recipe.cookbookId != null) {
      cIndex = cookbooks.indexWhere((c) => c.id == recipe.cookbookId);
      if (cIndex != -1) {
        final c = cookbooks[cIndex];
        updatedCookbook = c.copyWith(
          cookCount: (c.cookCount ?? 0) + 1,
          lastCookedAt: now,
          updatedAt: DateTime.now(),
        );
      }
    }

    // optimistic local update
    recipes[rIndex] = updatedRecipe;
    cookHistory = [event, ...cookHistory];
    if (updatedCookbook != null && cIndex != -1) {
      cookbooks[cIndex] = updatedCookbook;
      // keep the cookbook.recipes list in sync (if you rely on it)
      cookbooks[cIndex].recipes = recipes
          .where((r) => r.cookbookId == cookbooks[cIndex].id)
          .toList();
    }
    notifyListeners();

    // Firestore transaction so counts can't desync
    try {
      await _db.runTransaction((tx) async {
        tx.set(historyRef, event.toFirestore());

        final recipeRef = _db
            .collection('users')
            .doc(user.uid)
            .collection('recipes')
            .doc(recipeId);

        tx.update(recipeRef, updatedRecipe.toFirestore());

        if (updatedCookbook != null) {
          final cookbookRef = _db
              .collection('users')
              .doc(user.uid)
              .collection('cookbooks')
              .doc(updatedCookbook.id);

          tx.update(cookbookRef, updatedCookbook.toFirestore());
        }
      });
    } catch (e) {
      // rollback by refreshing (simple + safe)
      await refresh();
      rethrow;
    }
  }

  bool matchRecipes(Recipe r, String q, Set<String> qTags) {
    final qq = q.trim().toLowerCase();
    final hasText = qq.isNotEmpty;
    final hasTags = qTags.isNotEmpty;

    // nothing selected → show all
    if (!hasText && !hasTags) return true;

    // ---- TEXT MATCH ----
    bool textOk = true;
    if (hasText) {
      final title = r.title.toLowerCase();
      final desc = (r.description ?? '').toLowerCase();
      final author = (r.sourceAuthor ?? '').toLowerCase();
      final ingredients = r.ingredients
          .map((i) => i.raw)
          .join(' ')
          .toLowerCase();
      final tags = r.tags.map((t) => t).join(' ').toLowerCase();

      textOk =
          title.contains(qq) ||
          desc.contains(qq) ||
          author.contains(qq) ||
          ingredients.contains(qq) ||
          tags.contains(qq);
    }

    // ---- TAG MATCH (exact) ----
    bool tagsOk = true;
    if (hasTags) {
      final recipeTags = r.tags.map((t) => t.toLowerCase()).toSet();
      tagsOk = qTags.every((t) => recipeTags.contains(t.toLowerCase()));
    }

    // if both provided → both must hold
    return textOk && tagsOk;
  }

  bool matchCookbooks(Cookbook c, String q, Set<String> qTags) {
    final qq = q.trim().toLowerCase();
    final hasText = qq.isNotEmpty;
    final hasTags = qTags.isNotEmpty;

    if (!hasText && !hasTags) return true;

    // TEXT: match cookbook title/desc OR any recipe text
    bool textOk = true;
    if (hasText) {
      final title = c.title.toLowerCase();
      final desc = (c.description ?? '').toLowerCase();
      final author = (c.author ?? '').toLowerCase();
      final cookbookTextMatch =
          title.contains(qq) || desc.contains(qq) || author.contains(qq);

      // recipe text-only match (ignore tags here)
      final recipeTextMatch = c.recipes.any(
        (r) => matchRecipes(r, q, const {}),
      );

      textOk = cookbookTextMatch || recipeTextMatch;
    }

    // TAGS: must be satisfied by at least one recipe (ignore text here)
    bool tagsOk = true;
    if (hasTags) {
      tagsOk = c.recipes.any((r) => matchRecipes(r, '', qTags));
    }

    // BOTH must hold if both are provided
    return textOk && tagsOk;
  }
}
