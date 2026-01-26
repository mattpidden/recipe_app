import 'dart:math';

enum UnitSystem { original, metric, imperial_cups, imperial_ozs }

enum UnitDim { mass, volume, length, count, unknown }

class UnitValue {
  final double? qty;
  final String?
  unit; // canonical unit: g, kg, ml, l, oz, lb, tsp, tbsp, floz, cup, pt, qt, gal
  const UnitValue(this.qty, this.unit);
}

class _DensityInfo {
  final double gPerMl; // grams per millilitre
  final bool isLiquid; // helps decide ozs-mode behaviour for volume inputs
  const _DensityInfo(this.gPerMl, {required this.isLiquid});
}

class UnitConverter {
  // --- Normalisation map
  static final Map<String, String> _aliases = {
    // mass
    'g': 'g',
    'gram': 'g',
    'grams': 'g',
    'gramme': 'g',
    'grammes': 'g',
    'kg': 'kg',
    'kilogram': 'kg',
    'kilograms': 'kg',
    'oz': 'oz',
    'ounce': 'oz',
    'ounces': 'oz',
    'lb': 'lb',
    'lbs': 'lb',
    'pound': 'lb',
    'pounds': 'lb',

    // length
    'cm': 'cm',
    'cm piece': 'cm',
    'centimeter': 'cm',
    'centimeter piece': 'cm',
    'centimeters': 'cm',
    'mm': 'mm',
    'millimeter': 'mm',
    'millimeters': 'mm',
    'm': 'm',
    'meter': 'm',
    'meters': 'm',
    'metre': 'm',
    'metres': 'm',
    'in': 'in',
    'in piece': 'in',
    'inch': 'in',
    'inch piece': 'in',
    'inches': 'in',
    '"': 'in',
    'ft': 'ft',
    'foot': 'ft',
    'feet': 'ft',
    "'": 'ft',
    'yd': 'yd',
    'yard': 'yd',
    'yards': 'yd',

    // volume
    'ml': 'ml',
    'milliliter': 'ml',
    'millilitre': 'ml',
    'milliliters': 'ml',
    'millilitres': 'ml',
    'l': 'l',
    'liter': 'l',
    'litre': 'l',
    'liters': 'l',
    'litres': 'l',

    'tsp': 'tsp',
    'teaspoon': 'tsp',
    'teaspoons': 'tsp',
    'tsps': 'tsp',

    'tbsp': 'tbsp',
    'tablespoon': 'tbsp',
    'tablespoons': 'tbsp',
    'tbsps': 'tbsp',

    'fl oz': 'floz',
    'floz': 'floz',
    'fluidounce': 'floz',
    'fluidounces': 'floz',

    'cup': 'cup',
    'cups': 'cup',

    'pt': 'pt',
    'pint': 'pt',
    'pints': 'pt',

    'qt': 'qt',
    'quart': 'qt',
    'quarts': 'qt',

    'gal': 'gal',
    'gallon': 'gal',
    'gallons': 'gal',
  };

  // units that should remain as-is most of the time (they’re “nice” in both systems)
  static Set<String> neutralUnits = {'tsp', 'tbsp'};

  // ---------- Density map ----------
  // Stored as g/ml. For dry ingredients this is “bulk density” (approx).
  // Rule of thumb: only used when we have a reasonable match.
  static final Map<String, _DensityInfo> _densities = {
    // liquids (approx)
    'water': _DensityInfo(1.00, isLiquid: true),
    'milk': _DensityInfo(1.03, isLiquid: true),
    'buttermilk': _DensityInfo(1.03, isLiquid: true),
    'cream': _DensityInfo(0.99, isLiquid: true),
    'heavy cream': _DensityInfo(0.99, isLiquid: true),
    'double cream': _DensityInfo(0.99, isLiquid: true),
    'olive oil': _DensityInfo(0.91, isLiquid: true),
    'vegetable oil': _DensityInfo(0.92, isLiquid: true),
    'canola oil': _DensityInfo(0.92, isLiquid: true),
    'melted butter': _DensityInfo(0.91, isLiquid: true),
    'honey': _DensityInfo(1.42, isLiquid: true),
    'maple syrup': _DensityInfo(1.33, isLiquid: true),
    'golden syrup': _DensityInfo(1.36, isLiquid: true),
    'corn syrup': _DensityInfo(1.33, isLiquid: true),
    'soy sauce': _DensityInfo(1.16, isLiquid: true),
    'vinegar': _DensityInfo(1.01, isLiquid: true),
    'lemon juice': _DensityInfo(1.03, isLiquid: true),
    'lime juice': _DensityInfo(1.03, isLiquid: true),

    // dry powders / granules (approx bulk densities)
    'flour': _DensityInfo(0.53, isLiquid: false), // AP flour ~125g/cup
    'all purpose flour': _DensityInfo(0.53, isLiquid: false),
    'plain flour': _DensityInfo(0.53, isLiquid: false),
    'bread flour': _DensityInfo(0.57, isLiquid: false),
    'whole wheat flour': _DensityInfo(0.55, isLiquid: false),
    'self raising flour': _DensityInfo(0.50, isLiquid: false),
    'cake flour': _DensityInfo(0.48, isLiquid: false),
    'cornstarch': _DensityInfo(0.54, isLiquid: false),
    'cornflour': _DensityInfo(0.54, isLiquid: false),
    'cocoa powder': _DensityInfo(0.43, isLiquid: false),
    'powdered sugar': _DensityInfo(0.50, isLiquid: false),
    'icing sugar': _DensityInfo(0.50, isLiquid: false),
    'confectioners sugar': _DensityInfo(0.50, isLiquid: false),
    'granulated sugar': _DensityInfo(0.85, isLiquid: false),
    'caster sugar': _DensityInfo(0.85, isLiquid: false),
    'brown sugar': _DensityInfo(0.93, isLiquid: false),
    'light brown sugar': _DensityInfo(0.93, isLiquid: false),
    'dark brown sugar': _DensityInfo(0.93, isLiquid: false),
    'salt': _DensityInfo(1.20, isLiquid: false),
    'table salt': _DensityInfo(1.20, isLiquid: false),
    'kosher salt': _DensityInfo(0.75, isLiquid: false),
    'baking powder': _DensityInfo(0.90, isLiquid: false),
    'baking soda': _DensityInfo(0.92, isLiquid: false),
    'yeast': _DensityInfo(0.65, isLiquid: false),
    'instant yeast': _DensityInfo(0.65, isLiquid: false),
    'active dry yeast': _DensityInfo(0.65, isLiquid: false),

    // grains / oats (approx)
    'rice': _DensityInfo(0.78, isLiquid: false),
    'uncooked rice': _DensityInfo(0.78, isLiquid: false),
    'oats': _DensityInfo(0.38, isLiquid: false),
    'rolled oats': _DensityInfo(0.38, isLiquid: false),

    // fats / spreads (treated as “dry-ish” for ozs mode when volume given)
    'butter': _DensityInfo(0.96, isLiquid: false),
    'peanut butter': _DensityInfo(1.05, isLiquid: false),

    // grated / crumbs (very approximate)
    'breadcrumbs': _DensityInfo(0.45, isLiquid: false),
    'grated cheese': _DensityInfo(0.55, isLiquid: false),
    'parmesan': _DensityInfo(0.50, isLiquid: false),
  };

  // Ingredient aliasing to hit the density map more often
  static final Map<String, String> _ingredientAliases = {
    'ap flour': 'all purpose flour',
    'all-purpose flour': 'all purpose flour',
    'plain white flour': 'plain flour',
    'sr flour': 'self raising flour',
    'self-raising flour': 'self raising flour',
    'confectioner\'s sugar': 'confectioners sugar',
    'powder sugar': 'powdered sugar',
    'icing': 'icing sugar',
    'caster': 'caster sugar',
    'brown': 'brown sugar',
    'veg oil': 'vegetable oil',
    'rapeseed oil': 'canola oil',
    'double cream uk': 'double cream',
  };

  static String? normalizeUnit(String? unit) {
    if (unit == null) return null;
    final u = unit.trim().toLowerCase();
    if (u.isEmpty) return null;

    final compact = u
        .replaceAll(RegExp(r'[.\-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (_aliases.containsKey(compact)) return _aliases[compact];

    final nospace = compact.replaceAll(' ', '');
    if (_aliases.containsKey(nospace)) return _aliases[nospace];

    return null;
  }

  static String? _normalizeIngredient(String? ingredient) {
    if (ingredient == null) return null;
    var s = ingredient.trim().toLowerCase();
    if (s.isEmpty) return null;

    s = s
        .replaceAll(RegExp(r'[\(\)\[\]\{\},;:]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (_ingredientAliases.containsKey(s)) s = _ingredientAliases[s]!;
    return s;
  }

  static _DensityInfo? densityOf(String? ingredient) {
    final key = _normalizeIngredient(ingredient);
    if (key == null) return null;
    if (_densities.containsKey(key)) return _densities[key];

    // light fuzzy: try contains matches
    for (final k in _densities.keys) {
      if (key.contains(k)) return _densities[k];
    }
    return null;
  }

  static UnitDim dimOf(String? canonicalUnit) {
    switch (canonicalUnit) {
      case 'g':
      case 'kg':
      case 'oz':
      case 'lb':
        return UnitDim.mass;
      case 'ml':
      case 'l':
      case 'tsp':
      case 'tbsp':
      case 'floz':
      case 'cup':
      case 'pt':
      case 'qt':
      case 'gal':
        return UnitDim.volume;
      case 'mm':
      case 'cm':
      case 'm':
      case 'in':
      case 'ft':
      case 'yd':
        return UnitDim.length;
      default:
        return UnitDim.unknown;
    }
  }

  // --- Base conversions
  // Mass base = grams
  static double _toGrams(double v, String u) {
    switch (u) {
      case 'g':
        return v;
      case 'kg':
        return v * 1000.0;
      case 'oz':
        return v * 28.349523125;
      case 'lb':
        return v * 453.59237;
      default:
        return v;
    }
  }

  static double _fromGrams(double g, String target) {
    switch (target) {
      case 'g':
        return g;
      case 'kg':
        return g / 1000.0;
      case 'oz':
        return g / 28.349523125;
      case 'lb':
        return g / 453.59237;
      default:
        return g;
    }
  }

  // Volume base = millilitres
  static double _toMl(double v, String u) {
    switch (u) {
      case 'ml':
        return v;
      case 'l':
        return v * 1000.0;
      case 'tsp':
        return v * 4.92892159375;
      case 'tbsp':
        return v * 14.78676478125;
      case 'floz':
        return v * 29.5735295625;
      case 'cup':
        return v * 236.5882365;
      case 'pt':
        return v * 473.176473;
      case 'qt':
        return v * 946.352946;
      case 'gal':
        return v * 3785.411784;
      default:
        return v;
    }
  }

  static double _fromMl(double ml, String target) {
    switch (target) {
      case 'ml':
        return ml;
      case 'l':
        return ml / 1000.0;
      case 'tsp':
        return ml / 4.92892159375;
      case 'tbsp':
        return ml / 14.78676478125;
      case 'floz':
        return ml / 29.5735295625;
      case 'cup':
        return ml / 236.5882365;
      case 'pt':
        return ml / 473.176473;
      case 'qt':
        return ml / 946.352946;
      case 'gal':
        return ml / 3785.411784;
      default:
        return ml;
    }
  }

  static double _toMm(double v, String u) {
    switch (u) {
      case 'mm':
        return v;
      case 'cm':
        return v * 10.0;
      case 'm':
        return v * 1000.0;
      case 'in':
        return v * 25.4;
      case 'ft':
        return v * 304.8;
      case 'yd':
        return v * 914.4;
      default:
        return v;
    }
  }

  static double _fromMm(double mm, String target) {
    switch (target) {
      case 'mm':
        return mm;
      case 'cm':
        return mm / 10.0;
      case 'm':
        return mm / 1000.0;
      case 'in':
        return mm / 25.4;
      case 'ft':
        return mm / 304.8;
      case 'yd':
        return mm / 914.4;
      default:
        return mm;
    }
  }

  static bool _isMetric(UnitSystem sys) => sys == UnitSystem.metric;

  // “Nice” target unit by system + magnitude
  static String _bestMassUnit(UnitSystem sys, double grams) {
    if (_isMetric(sys)) return grams >= 1000 ? 'kg' : 'g';
    final oz = _fromGrams(grams, 'oz');
    return oz >= 16 ? 'lb' : 'oz';
  }

  static String _bestVolumeUnit(UnitSystem sys, double ml) {
    if (sys == UnitSystem.metric) {
      // metric mode: tsp/tbsp for tiny volumes, otherwise ml/l
      if (ml < _toMl(1, 'tsp') * 3) return 'tsp'; // < ~15ml
      if (ml < _toMl(1, 'tbsp') * 2) return 'tbsp'; // < ~30ml
      return ml >= 1000 ? 'l' : 'ml';
    }

    if (sys == UnitSystem.imperial_ozs) {
      final floz = _fromMl(ml, 'floz');
      if (floz < 1.0) return 'tsp';
      if (floz < 2.0) return 'tbsp';
      if (floz < 16.0) return 'floz';
      return 'floz';
      // final pints = _fromMl(ml, 'pt');
      // if (pints < 2.0) return 'pt';
      // final quarts = _fromMl(ml, 'qt');
      // if (quarts < 4.0) return 'qt';
      // return 'gal';
    }

    // imperial_cups
    final floz = _fromMl(ml, 'floz');
    if (floz < 1.0) return 'tsp';
    if (floz < 2.0) return 'tbsp';
    final cups = _fromMl(ml, 'cup');
    if (cups < 2.0) return 'cup';
    return 'cup';
    // final pints = _fromMl(ml, 'pt');
    // if (pints < 2.0) return 'pt';
    // final quarts = _fromMl(ml, 'qt');
    // if (quarts < 4.0) return 'qt';
    // return 'gal';
  }

  static String _bestLengthUnit(UnitSystem sys, double mm) {
    if (_isMetric(sys)) {
      if (mm >= 1000) return 'm';
      if (mm >= 10) return 'cm';
      return 'mm';
    } else {
      final inches = _fromMm(mm, 'in');
      if (inches >= 36) return 'yd';
      if (inches >= 12) return 'ft';
      return 'in';
    }
  }

  static double _roundNice(double v) {
    if (v == 0) return 0;
    if (v >= 10) return double.parse(v.toStringAsFixed(0));
    if (v >= 1) return double.parse(v.toStringAsFixed(1));
    return double.parse(v.toStringAsFixed(2));
  }

  // Public API
  // Pass ingredient when you can to enable cups<->oz via density.
  static UnitValue convert(
    double? qty,
    String? unit,
    UnitSystem target, {
    String? ingredient,
  }) {
    if (qty == null) return UnitValue(null, unit);
    if (target == UnitSystem.original) return UnitValue(qty, unit);

    final canon = normalizeUnit(unit);
    if (canon == null) return UnitValue(qty, unit);

    // tsp/tbsp are allowed in all modes; but still convert if user explicitly wants (we’ll keep as-is)
    if (neutralUnits.contains(canon)) return UnitValue(qty, canon);

    final dim = dimOf(canon);
    final dens = densityOf(ingredient);

    // --- MASS INPUT
    if (dim == UnitDim.mass) {
      final g = _toGrams(qty, canon);

      if (target == UnitSystem.imperial_cups) {
        // prefer cups when possible
        if (dens != null) {
          final ml = g / dens.gPerMl;
          final outUnit = _bestVolumeUnit(target, ml);
          final outQty = _roundNice(_fromMl(ml, outUnit));
          return UnitValue(outQty, outUnit);
        }
        // fallback: still imperial weight
        final outUnit = _bestMassUnit(UnitSystem.imperial_ozs, g);
        final outQty = _roundNice(_fromGrams(g, outUnit));
        return UnitValue(outQty, outUnit);
      }

      // metric or imperial_ozs
      final outUnit = _bestMassUnit(target, g);
      final outQty = _roundNice(_fromGrams(g, outUnit));
      return UnitValue(outQty, outUnit);
    }

    // --- VOLUME INPUT
    if (dim == UnitDim.volume) {
      final ml = _toMl(qty, canon);

      if (target == UnitSystem.imperial_ozs) {
        // liquids stay volume; dry can become oz if density known + not liquid-ish
        if (dens != null && !dens.isLiquid) {
          final g = ml * dens.gPerMl;
          final outUnit = _bestMassUnit(target, g);
          final outQty = _roundNice(_fromGrams(g, outUnit));
          return UnitValue(outQty, outUnit);
        }
        final outUnit = _bestVolumeUnit(target, ml);
        final outQty = _roundNice(_fromMl(ml, outUnit));
        return UnitValue(outQty, outUnit);
      }

      if (target == UnitSystem.imperial_cups) {
        final outUnit = _bestVolumeUnit(target, ml);
        final outQty = _roundNice(_fromMl(ml, outUnit));
        return UnitValue(outQty, outUnit);
      }

      // metric
      final outUnit = _bestVolumeUnit(target, ml);
      final outQty = _roundNice(_fromMl(ml, outUnit));
      return UnitValue(outQty, outUnit);
    }

    // --- LENGTH INPUT
    if (dim == UnitDim.length) {
      final mm = _toMm(qty, canon);
      final outUnit = _bestLengthUnit(
        target == UnitSystem.metric
            ? UnitSystem.metric
            : UnitSystem.imperial_ozs,
        mm,
      );
      final outQty = _roundNice(_fromMm(mm, outUnit));
      return UnitValue(outQty, outUnit);
    }

    return UnitValue(qty, unit);
  }

  static UnitValue convertTo(
    double? qty,
    String? unit,
    UnitSystem target, {
    String? ingredient,
  }) => convert(qty, unit, target, ingredient: ingredient);
}
