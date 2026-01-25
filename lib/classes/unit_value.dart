enum UnitSystem { metric, imperial }

enum UnitDim { mass, volume, count, unknown }

class UnitValue {
  final double? qty;
  final String?
  unit; // canonical unit: g, kg, ml, l, oz, lb, tsp, tbsp, floz, cup, pt, qt, gal
  const UnitValue(this.qty, this.unit);
}

class UnitConverter {
  // --- Normalisation map (add to this over time)
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

  static String? normalizeUnit(String? unit) {
    if (unit == null) return null;
    final u = unit.trim().toLowerCase();
    if (u.isEmpty) return null;

    // squash punctuation/spaces: "fl. oz" / "fl oz" / "fl-oz" -> "floz" path
    final compact = u
        .replaceAll(RegExp(r'[.\-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // direct hit
    if (_aliases.containsKey(compact)) return _aliases[compact];

    // also try no-space version (helps "fl oz" -> "floz")
    final nospace = compact.replaceAll(' ', '');
    if (_aliases.containsKey(nospace)) return _aliases[nospace];

    return null; // unknown -> treat as count/unknown
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

  // Pick “nice” target unit by system + magnitude
  static String _bestMassUnit(UnitSystem sys, double grams) {
    if (sys == UnitSystem.metric) return grams >= 1000 ? 'kg' : 'g';
    final oz = _fromGrams(grams, 'oz');
    return oz >= 16 ? 'lb' : 'oz';
  }

  static String _bestVolumeUnit(UnitSystem sys, double ml) {
    if (sys == UnitSystem.metric) return ml >= 1000 ? 'l' : 'ml';
    final floz = _fromMl(ml, 'floz');
    // tiny amounts look better as tsp/tbsp
    if (floz < 1.0) return 'tsp';
    if (floz < 2.0) return 'tbsp';
    // bigger as cups/pt/qt
    final cups = _fromMl(ml, 'cup');
    if (cups < 2.0) return 'cup';
    final pints = _fromMl(ml, 'pt');
    if (pints < 2.0) return 'pt';
    final quarts = _fromMl(ml, 'qt');
    if (quarts < 4.0) return 'qt';
    return 'gal';
  }

  static double _roundNice(double v) {
    if (v == 0) return 0;
    if (v >= 10) return double.parse(v.toStringAsFixed(0));
    if (v >= 1) return double.parse(v.toStringAsFixed(1));
    return double.parse(v.toStringAsFixed(2));
  }

  // Public API
  static UnitValue convert(double? qty, String? unit, UnitSystem target) {
    if (qty == null) return UnitValue(null, unit);
    final canon = normalizeUnit(unit);
    if (canon == null) return UnitValue(qty, unit); // treat as count/unknown

    final dim = dimOf(canon);

    if (dim == UnitDim.mass) {
      final g = _toGrams(qty, canon);
      final outUnit = _bestMassUnit(target, g);
      final outQty = _roundNice(_fromGrams(g, outUnit));
      return UnitValue(outQty, outUnit);
    }

    if (dim == UnitDim.volume) {
      final ml = _toMl(qty, canon);
      final outUnit = _bestVolumeUnit(target, ml);
      final outQty = _roundNice(_fromMl(ml, outUnit));
      return UnitValue(outQty, outUnit);
    }

    return UnitValue(qty, unit);
  }

  static UnitValue convertToMetric(double? qty, String? unit) =>
      convert(qty, unit, UnitSystem.metric);

  static UnitValue convertToImperial(double? qty, String? unit) =>
      convert(qty, unit, UnitSystem.imperial);
}
