import 'dart:math';

enum UnitSystem { original, metric, imperial }

String viewModeLabel(UnitSystem unitSystem) {
  switch (unitSystem) {
    case UnitSystem.original:
      return "Original";
    case UnitSystem.metric:
      return "Metric";
    case UnitSystem.imperial:
      return "Imperial";
  }
}

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
    // ===== LIQUIDS =====
    'water': _DensityInfo(1.00, isLiquid: true),
    'milk': _DensityInfo(1.03, isLiquid: true),
    'whole milk': _DensityInfo(1.03, isLiquid: true),
    'skim milk': _DensityInfo(1.03, isLiquid: true),
    'lowfat milk': _DensityInfo(1.03, isLiquid: true),
    'buttermilk': _DensityInfo(1.03, isLiquid: true),
    'cream': _DensityInfo(0.99, isLiquid: true),
    'heavy cream': _DensityInfo(0.99, isLiquid: true),
    'whipped cream': _DensityInfo(0.99, isLiquid: true),
    'double cream': _DensityInfo(0.99, isLiquid: true),
    'sour cream': _DensityInfo(1.04, isLiquid: true),
    'soured cream': _DensityInfo(1.04, isLiquid: true),
    'greek yogurt': _DensityInfo(1.05, isLiquid: true),
    'yogurt': _DensityInfo(1.04, isLiquid: true),
    'plain yogurt': _DensityInfo(1.04, isLiquid: true),
    'coconut milk': _DensityInfo(1.02, isLiquid: true),
    'almond milk': _DensityInfo(1.00, isLiquid: true),
    'oat milk': _DensityInfo(1.00, isLiquid: true),
    'soy milk': _DensityInfo(1.01, isLiquid: true),
    'cashew milk': _DensityInfo(1.00, isLiquid: true),

    // ===== OILS & FATS (liquid) =====
    'olive oil': _DensityInfo(0.91, isLiquid: true),
    'extra virgin olive oil': _DensityInfo(0.91, isLiquid: true),
    'vegetable oil': _DensityInfo(0.92, isLiquid: true),
    'veg oil': _DensityInfo(0.92, isLiquid: true),
    'canola oil': _DensityInfo(0.92, isLiquid: true),
    'rapeseed oil': _DensityInfo(0.92, isLiquid: true),
    'coconut oil': _DensityInfo(0.92, isLiquid: true),
    'sesame oil': _DensityInfo(0.92, isLiquid: true),
    'peanut oil': _DensityInfo(0.92, isLiquid: true),
    'sunflower oil': _DensityInfo(0.92, isLiquid: true),
    'grapeseed oil': _DensityInfo(0.92, isLiquid: true),
    'avocado oil': _DensityInfo(0.92, isLiquid: true),
    'walnut oil': _DensityInfo(0.92, isLiquid: true),
    'melted butter': _DensityInfo(0.91, isLiquid: true),

    // ===== SYRUPS & HONEY (liquids) =====
    'honey': _DensityInfo(1.42, isLiquid: true),
    'maple syrup': _DensityInfo(1.33, isLiquid: true),
    'golden syrup': _DensityInfo(1.36, isLiquid: true),
    'light golden syrup': _DensityInfo(1.36, isLiquid: true),
    'corn syrup': _DensityInfo(1.33, isLiquid: true),
    'light corn syrup': _DensityInfo(1.33, isLiquid: true),
    'dark corn syrup': _DensityInfo(1.33, isLiquid: true),
    'agave nectar': _DensityInfo(1.33, isLiquid: true),
    'agave syrup': _DensityInfo(1.33, isLiquid: true),
    'molasses': _DensityInfo(1.38, isLiquid: true),
    'blackstrap molasses': _DensityInfo(1.38, isLiquid: true),

    // ===== CONDIMENTS & SAUCES (liquids) =====
    'soy sauce': _DensityInfo(1.16, isLiquid: true),
    'tamari': _DensityInfo(1.16, isLiquid: true),
    'fish sauce': _DensityInfo(1.02, isLiquid: true),
    'hot sauce': _DensityInfo(1.04, isLiquid: true),
    'sriracha': _DensityInfo(1.04, isLiquid: true),
    'worcestershire sauce': _DensityInfo(1.02, isLiquid: true),
    'ketchup': _DensityInfo(1.08, isLiquid: true),
    'tomato ketchup': _DensityInfo(1.08, isLiquid: true),
    'mustard': _DensityInfo(1.05, isLiquid: true),
    'yellow mustard': _DensityInfo(1.05, isLiquid: true),
    'dijon mustard': _DensityInfo(1.05, isLiquid: true),
    'mayonnaise': _DensityInfo(0.98, isLiquid: true),
    'mayo': _DensityInfo(0.98, isLiquid: true),
    'pesto': _DensityInfo(0.95, isLiquid: true),

    // ===== VINEGARS (liquids) =====
    'vinegar': _DensityInfo(1.01, isLiquid: true),
    'white vinegar': _DensityInfo(1.01, isLiquid: true),
    'distilled vinegar': _DensityInfo(1.01, isLiquid: true),
    'apple cider vinegar': _DensityInfo(1.01, isLiquid: true),
    'cider vinegar': _DensityInfo(1.01, isLiquid: true),
    'balsamic vinegar': _DensityInfo(1.05, isLiquid: true),
    'rice vinegar': _DensityInfo(1.01, isLiquid: true),
    'rice wine vinegar': _DensityInfo(1.01, isLiquid: true),
    'wine vinegar': _DensityInfo(1.01, isLiquid: true),
    'red wine vinegar': _DensityInfo(1.01, isLiquid: true),
    'white wine vinegar': _DensityInfo(1.01, isLiquid: true),
    'champagne vinegar': _DensityInfo(1.01, isLiquid: true),

    // ===== JUICES & BROTHS (liquids) =====
    'lemon juice': _DensityInfo(1.03, isLiquid: true),
    'lime juice': _DensityInfo(1.03, isLiquid: true),
    'orange juice': _DensityInfo(1.04, isLiquid: true),
    'apple juice': _DensityInfo(1.05, isLiquid: true),
    'tomato juice': _DensityInfo(1.04, isLiquid: true),
    'vegetable broth': _DensityInfo(1.00, isLiquid: true),
    'vegetable stock': _DensityInfo(1.00, isLiquid: true),
    'chicken broth': _DensityInfo(1.00, isLiquid: true),
    'chicken stock': _DensityInfo(1.00, isLiquid: true),
    'beef broth': _DensityInfo(1.00, isLiquid: true),
    'beef stock': _DensityInfo(1.00, isLiquid: true),

    // ===== ALCOHOLIC BEVERAGES (liquids) =====
    'beer': _DensityInfo(1.01, isLiquid: true),
    'wine': _DensityInfo(0.99, isLiquid: true),
    'red wine': _DensityInfo(0.99, isLiquid: true),
    'white wine': _DensityInfo(0.99, isLiquid: true),
    'brandy': _DensityInfo(0.87, isLiquid: true),
    'rum': _DensityInfo(0.87, isLiquid: true),
    'vodka': _DensityInfo(0.87, isLiquid: true),
    'whiskey': _DensityInfo(0.87, isLiquid: true),
    'bourbon': _DensityInfo(0.87, isLiquid: true),
    'gin': _DensityInfo(0.87, isLiquid: true),

    // ===== FLOURS (baking - IMPORTANT for imperial volume conversion) =====
    'flour': _DensityInfo(0.53, isLiquid: false), // AP flour ~125g/cup
    'all purpose flour': _DensityInfo(0.53, isLiquid: false),
    'ap flour': _DensityInfo(0.53, isLiquid: false),
    'plain flour': _DensityInfo(0.53, isLiquid: false),
    'bread flour': _DensityInfo(0.57, isLiquid: false), // ~135g/cup
    'whole wheat flour': _DensityInfo(0.55, isLiquid: false),
    'wholemeal flour': _DensityInfo(0.55, isLiquid: false),
    'self raising flour': _DensityInfo(0.50, isLiquid: false),
    'sr flour': _DensityInfo(0.50, isLiquid: false),
    'self-rising flour': _DensityInfo(0.50, isLiquid: false),
    'cake flour': _DensityInfo(0.48, isLiquid: false),
    'pastry flour': _DensityInfo(0.48, isLiquid: false),
    'cornstarch': _DensityInfo(0.54, isLiquid: false),
    'cornflour': _DensityInfo(0.54, isLiquid: false),
    'potato starch': _DensityInfo(0.60, isLiquid: false),
    'arrowroot': _DensityInfo(0.50, isLiquid: false),
    'tapioca starch': _DensityInfo(0.55, isLiquid: false),

    // ===== LEAVENING (baking) =====
    'baking powder': _DensityInfo(0.90, isLiquid: false),
    'baking soda': _DensityInfo(0.92, isLiquid: false),
    'yeast': _DensityInfo(0.65, isLiquid: false),
    'instant yeast': _DensityInfo(0.65, isLiquid: false),
    'active dry yeast': _DensityInfo(0.65, isLiquid: false),
    'dry yeast': _DensityInfo(0.65, isLiquid: false),
    'fresh yeast': _DensityInfo(1.05, isLiquid: false),
    'compressed yeast': _DensityInfo(1.05, isLiquid: false),

    // ===== SUGARS (baking) =====
    'granulated sugar': _DensityInfo(0.85, isLiquid: false), // ~200g/cup
    'white sugar': _DensityInfo(0.85, isLiquid: false),
    'caster sugar': _DensityInfo(0.85, isLiquid: false),
    'superfine sugar': _DensityInfo(0.85, isLiquid: false),
    'brown sugar': _DensityInfo(0.93, isLiquid: false), // ~220g/cup, packed
    'light brown sugar': _DensityInfo(0.93, isLiquid: false),
    'dark brown sugar': _DensityInfo(0.93, isLiquid: false),
    'light brown muscovado sugar': _DensityInfo(0.93, isLiquid: false),
    'dark brown muscovado sugar': _DensityInfo(0.93, isLiquid: false),
    'muscovado': _DensityInfo(0.93, isLiquid: false),
    'demerara sugar': _DensityInfo(0.80, isLiquid: false),
    'turbinado sugar': _DensityInfo(0.80, isLiquid: false),
    'coconut sugar': _DensityInfo(0.83, isLiquid: false),
    'palm sugar': _DensityInfo(0.83, isLiquid: false),
    'powdered sugar': _DensityInfo(0.50, isLiquid: false), // ~120g/cup
    'icing sugar': _DensityInfo(0.50, isLiquid: false),
    'confectioners sugar': _DensityInfo(0.50, isLiquid: false),
    'powdered sugar confectioners': _DensityInfo(0.50, isLiquid: false),

    // ===== COCOA & CHOCOLATE (baking) =====
    'cocoa powder': _DensityInfo(0.43, isLiquid: false), // ~85g/cup
    'dutch cocoa': _DensityInfo(0.43, isLiquid: false),
    'unsweetened cocoa': _DensityInfo(0.43, isLiquid: false),
    'chocolate chips': _DensityInfo(0.72, isLiquid: false),
    'chocolate morsels': _DensityInfo(0.72, isLiquid: false),
    'semi-sweet chocolate chips': _DensityInfo(0.72, isLiquid: false),
    'dark chocolate chips': _DensityInfo(0.72, isLiquid: false),
    'milk chocolate chips': _DensityInfo(0.72, isLiquid: false),
    'white chocolate chips': _DensityInfo(0.72, isLiquid: false),
    'chocolate chunks': _DensityInfo(0.72, isLiquid: false),

    // ===== SALT (baking) =====
    'salt': _DensityInfo(1.20, isLiquid: false), // ~287g/cup
    'table salt': _DensityInfo(1.20, isLiquid: false),
    'sea salt': _DensityInfo(1.04, isLiquid: false),
    'kosher salt': _DensityInfo(0.75, isLiquid: false),
    'pink himalayan salt': _DensityInfo(1.00, isLiquid: false),
    'pickling salt': _DensityInfo(1.20, isLiquid: false),
    'iodized salt': _DensityInfo(1.20, isLiquid: false),

    // ===== GRAINS (cooking/baking) =====
    'rice': _DensityInfo(0.78, isLiquid: false),
    'white rice': _DensityInfo(0.78, isLiquid: false),
    'uncooked rice': _DensityInfo(0.78, isLiquid: false),
    'brown rice': _DensityInfo(0.75, isLiquid: false),
    'jasmine rice': _DensityInfo(0.78, isLiquid: false),
    'basmati rice': _DensityInfo(0.80, isLiquid: false),
    'arborio rice': _DensityInfo(0.85, isLiquid: false),
    'oats': _DensityInfo(0.38, isLiquid: false), // ~90g/cup
    'rolled oats': _DensityInfo(0.38, isLiquid: false),
    'old fashioned oats': _DensityInfo(0.38, isLiquid: false),
    'steel cut oats': _DensityInfo(0.48, isLiquid: false),
    'quinoa': _DensityInfo(0.57, isLiquid: false),
    'polenta': _DensityInfo(0.58, isLiquid: false),
    'cornmeal': _DensityInfo(0.58, isLiquid: false),
    'couscous': _DensityInfo(0.60, isLiquid: false),

    // ===== FATS & SPREADS =====
    'butter': _DensityInfo(0.96, isLiquid: false), // solid/dry mode
    'unsalted butter': _DensityInfo(0.96, isLiquid: false),
    'salted butter': _DensityInfo(0.96, isLiquid: false),
    'shortening': _DensityInfo(0.91, isLiquid: false),
    'vegetable shortening': _DensityInfo(0.91, isLiquid: false),
    'lard': _DensityInfo(0.91, isLiquid: false),
    'coconut shortening': _DensityInfo(0.91, isLiquid: false),

    // ===== NUT & SEED BUTTERS =====
    'peanut butter': _DensityInfo(1.05, isLiquid: false),
    'almond butter': _DensityInfo(1.00, isLiquid: false),
    'tahini': _DensityInfo(1.04, isLiquid: false),
    'sesame butter': _DensityInfo(1.04, isLiquid: false),
    'sunflower butter': _DensityInfo(0.99, isLiquid: false),
    'cashew butter': _DensityInfo(1.00, isLiquid: false),
    'walnut butter': _DensityInfo(0.99, isLiquid: false),

    // ===== SEEDS =====
    'sesame seeds': _DensityInfo(0.93, isLiquid: false),
    'pumpkin seeds': _DensityInfo(0.77, isLiquid: false),
    'sunflower seeds': _DensityInfo(0.70, isLiquid: false),
    'flax seeds': _DensityInfo(0.85, isLiquid: false),
    'chia seeds': _DensityInfo(0.83, isLiquid: false),
    'poppy seeds': _DensityInfo(1.16, isLiquid: false),

    // ===== NUTS =====
    'almonds': _DensityInfo(0.62, isLiquid: false),
    'walnuts': _DensityInfo(0.52, isLiquid: false),
    'pecans': _DensityInfo(0.56, isLiquid: false),
    'peanuts': _DensityInfo(0.69, isLiquid: false),
    'hazelnuts': _DensityInfo(0.65, isLiquid: false),
    'macadamia nuts': _DensityInfo(0.56, isLiquid: false),
    'cashews': _DensityInfo(0.65, isLiquid: false),
    'pine nuts': _DensityInfo(0.62, isLiquid: false),
    'pistachios': _DensityInfo(0.67, isLiquid: false),

    // ===== BREADCRUMBS & CRUMBS =====
    'breadcrumbs': _DensityInfo(0.45, isLiquid: false),
    'panko': _DensityInfo(0.35, isLiquid: false),
    'panko breadcrumbs': _DensityInfo(0.35, isLiquid: false),
    'italian breadcrumbs': _DensityInfo(0.45, isLiquid: false),
    'grated cheese': _DensityInfo(0.55, isLiquid: false),
    'parmesan': _DensityInfo(0.50, isLiquid: false),
    'grated parmesan': _DensityInfo(0.50, isLiquid: false),
    'cheddar cheese': _DensityInfo(0.50, isLiquid: false),
    'mozzarella': _DensityInfo(0.50, isLiquid: false),
    'shredded cheese': _DensityInfo(0.50, isLiquid: false),

    // ===== SPICES & SEASONINGS =====
    'cinnamon': _DensityInfo(1.00, isLiquid: false),
    'paprika': _DensityInfo(0.85, isLiquid: false),
    'chili powder': _DensityInfo(0.85, isLiquid: false),
    'cumin': _DensityInfo(0.92, isLiquid: false),
    'ginger': _DensityInfo(0.92, isLiquid: false),
    'ground ginger': _DensityInfo(0.92, isLiquid: false),
    'nutmeg': _DensityInfo(1.15, isLiquid: false),
    'allspice': _DensityInfo(0.95, isLiquid: false),
    'black pepper': _DensityInfo(0.95, isLiquid: false),
    'cayenne pepper': _DensityInfo(0.90, isLiquid: false),
    'garlic powder': _DensityInfo(0.70, isLiquid: false),
    'onion powder': _DensityInfo(0.70, isLiquid: false),
    'oregano': _DensityInfo(0.62, isLiquid: false),
    'basil': _DensityInfo(0.58, isLiquid: false),
    'thyme': _DensityInfo(0.58, isLiquid: false),
    'rosemary': _DensityInfo(0.58, isLiquid: false),
    'sage': _DensityInfo(0.58, isLiquid: false),
    'dill': _DensityInfo(0.58, isLiquid: false),
    'parsley': _DensityInfo(0.58, isLiquid: false),
    'italian seasoning': _DensityInfo(0.62, isLiquid: false),
    'curry powder': _DensityInfo(0.85, isLiquid: false),
    'turmeric': _DensityInfo(1.00, isLiquid: false),
    'cloves': _DensityInfo(1.10, isLiquid: false),
  };

  // Ingredient aliasing to hit the density map more often
  static final Map<String, String> _ingredientAliases = {
    // ===== FLOURS =====
    'ap flour': 'all purpose flour',
    'all-purpose flour': 'all purpose flour',
    'all purpose': 'all purpose flour',
    'plain white flour': 'plain flour',
    'plain': 'plain flour',
    'wholemeal flour': 'whole wheat flour',
    'wholemeal': 'whole wheat flour',
    'whole meal flour': 'whole wheat flour',
    'whole wheat': 'whole wheat flour',
    'bread flour': 'bread flour',
    'sr flour': 'self raising flour',
    'sr': 'self raising flour',
    'self-raising flour': 'self raising flour',
    'self rising flour': 'self raising flour',
    'cake flour': 'cake flour',
    'pastry flour': 'pastry flour',
    'pastry': 'pastry flour',
    'cornstarch': 'cornstarch',
    'corn starch': 'cornstarch',
    'cornflour': 'cornflour',
    'corn flour': 'cornflour',

    // ===== SUGARS =====
    'confectioner\'s sugar': 'confectioners sugar',
    'confectioners': 'confectioners sugar',
    'powder sugar': 'powdered sugar',
    'powdered': 'powdered sugar',
    'icing': 'icing sugar',
    'icing sugar': 'icing sugar',
    'caster': 'caster sugar',
    'caster sugar': 'caster sugar',
    'superfine': 'superfine sugar',
    'superfine sugar': 'superfine sugar',
    'granulated': 'granulated sugar',
    'white sugar': 'granulated sugar',
    'brown': 'brown sugar',
    'light brown': 'light brown sugar',
    'dark brown': 'dark brown sugar',
    'muscovado': 'muscovado',
    'demerara': 'demerara sugar',
    'turbinado': 'turbinado sugar',
    'coconut sugar': 'coconut sugar',
    'palm sugar': 'palm sugar',
    'palm': 'palm sugar',

    // ===== OILS =====
    'veg oil': 'vegetable oil',
    'vegetable': 'vegetable oil',
    'rapeseed oil': 'canola oil',
    'rapeseed': 'canola oil',
    'canola': 'canola oil',
    'olive': 'olive oil',
    'coconut oil': 'coconut oil',
    'coconut': 'coconut oil',
    'sesame oil': 'sesame oil',
    'sesame': 'sesame oil',
    'peanut oil': 'peanut oil',
    'peanut': 'peanut oil',
    'sunflower oil': 'sunflower oil',
    'sunflower': 'sunflower oil',
    'grapeseed oil': 'grapeseed oil',
    'grapeseed': 'grapeseed oil',
    'avocado oil': 'avocado oil',
    'avocado': 'avocado oil',
    'walnut oil': 'walnut oil',

    // ===== DAIRY =====
    'double cream uk': 'double cream',
    'double': 'double cream',
    'heavy': 'heavy cream',
    'heavy cream': 'heavy cream',
    'whipped cream': 'whipped cream',
    'whipped': 'whipped cream',
    'sour': 'sour cream',
    'sour cream': 'sour cream',
    'soured cream': 'soured cream',
    'greek': 'greek yogurt',
    'greek yogurt': 'greek yogurt',
    'yogurt': 'yogurt',
    'plain yogurt': 'yogurt',
    'milk': 'milk',
    'buttermilk': 'buttermilk',
    'almond milk': 'almond milk',
    'oat milk': 'oat milk',
    'soy milk': 'soy milk',
    'coconut milk': 'coconut milk',

    // ===== CHOCOLATE & COCOA =====
    'plain chocolate chips': 'chocolate chips',
    'milk chocolate chips': 'chocolate chips',
    'white chocolate chips': 'chocolate chips',
    'dark chocolate chips': 'chocolate chips',
    'semi-sweet chocolate chips': 'chocolate chips',
    'semi sweet chocolate chips': 'chocolate chips',
    'semi-sweet': 'chocolate chips',
    'semi sweet': 'chocolate chips',
    'plain chocolate': 'chocolate chips',
    'milk chocolate': 'chocolate chips',
    'white chocolate': 'chocolate chips',
    'dark chocolate': 'chocolate chips',
    'chocolate': 'chocolate chips',
    'chocolate chips': 'chocolate chips',
    'chocolate morsels': 'chocolate chips',
    'chocolate buttons': 'chocolate chips',
    'plain chocolate buttons': 'chocolate chips',
    'milk chocolate buttons': 'chocolate chips',
    'white chocolate buttons': 'chocolate chips',
    'dark chocolate buttons': 'chocolate chips',
    'chocolate chunks': 'chocolate chips',
    'plain chocolate chips or chunks': 'chocolate chips',
    'cocoa': 'cocoa powder',
    'dutch cocoa': 'cocoa powder',
    'unsweetened cocoa': 'cocoa powder',

    // ===== SALT =====
    'table': 'table salt',
    'kosher': 'kosher salt',
    'sea': 'sea salt',
    'sea salt': 'sea salt',
    'pink himalayan': 'pink himalayan salt',
    'himalayan': 'pink himalayan salt',
    'pink': 'pink himalayan salt',
    'iodized': 'iodized salt',
    'pickling': 'pickling salt',

    // ===== VINEGARS =====
    'white': 'white vinegar',
    'distilled': 'white vinegar',
    'apple cider': 'apple cider vinegar',
    'cider': 'apple cider vinegar',
    'rice': 'rice vinegar',
    'balsamic': 'balsamic vinegar',
    'red wine': 'red wine vinegar',
    'white wine': 'white wine vinegar',
    'wine': 'wine vinegar',
    'champagne': 'champagne vinegar',

    // ===== GRAINS =====
    'white rice': 'rice',
    'brown rice': 'brown rice',
    'jasmine': 'jasmine rice',
    'jasmine rice': 'jasmine rice',
    'basmati': 'basmati rice',
    'basmati rice': 'basmati rice',
    'arborio': 'arborio rice',
    'arborio rice': 'arborio rice',
    'oats': 'oats',
    'rolled oats': 'oats',
    'old fashioned oats': 'oats',
    'steel cut oats': 'steel cut oats',
    'steel cut': 'steel cut oats',
    'quinoa': 'quinoa',
    'polenta': 'polenta',
    'cornmeal': 'cornmeal',
    'couscous': 'couscous',

    // ===== NUTS & SEEDS =====
    'peanut butter': 'peanut butter',
    'almond butter': 'almond butter',
    'tahini': 'tahini',
    'sesame butter': 'tahini',
    'sunflower butter': 'sunflower butter',
    'cashew butter': 'cashew butter',
    'walnut butter': 'walnut butter',
    'almonds': 'almonds',
    'walnuts': 'walnuts',
    'pecans': 'pecans',
    'peanuts': 'peanuts',
    'hazelnuts': 'hazelnuts',
    'macadamia': 'macadamia nuts',
    'cashews': 'cashews',
    'pine nuts': 'pine nuts',
    'pistachios': 'pistachios',
    'sesame seeds': 'sesame seeds',
    'pumpkin seeds': 'pumpkin seeds',
    'sunflower seeds': 'sunflower seeds',
    'flax seeds': 'flax seeds',
    'chia seeds': 'chia seeds',
    'poppy seeds': 'poppy seeds',

    // ===== BUTTER & SPREADS =====
    'butter': 'butter',
    'unsalted butter': 'butter',
    'salted butter': 'butter',
    'shortening': 'shortening',
    'vegetable shortening': 'shortening',
    'lard': 'lard',

    // ===== CHEESE & DAIRY PRODUCTS =====
    'grated cheese': 'grated cheese',
    'parmesan': 'parmesan',
    'parm': 'parmesan',
    'grated parmesan': 'parmesan',
    'cheddar': 'cheddar cheese',
    'mozzarella': 'mozzarella',
    'shredded cheese': 'shredded cheese',
    'breadcrumbs': 'breadcrumbs',
    'panko': 'panko',
    'panko breadcrumbs': 'panko',
    'italian breadcrumbs': 'breadcrumbs',

    // ===== SPICES & SEASONINGS =====
    'cinnamon': 'cinnamon',
    'paprika': 'paprika',
    'chili powder': 'chili powder',
    'chili': 'chili powder',
    'cumin': 'cumin',
    'ginger': 'ginger',
    'ground ginger': 'ginger',
    'nutmeg': 'nutmeg',
    'allspice': 'allspice',
    'black pepper': 'black pepper',
    'pepper': 'black pepper',
    'cayenne pepper': 'cayenne pepper',
    'cayenne': 'cayenne pepper',
    'garlic powder': 'garlic powder',
    'garlic': 'garlic powder',
    'onion powder': 'onion powder',
    'onion': 'onion powder',
    'oregano': 'oregano',
    'basil': 'basil',
    'thyme': 'thyme',
    'rosemary': 'rosemary',
    'sage': 'sage',
    'dill': 'dill',
    'parsley': 'parsley',
    'italian seasoning': 'italian seasoning',
    'italian': 'italian seasoning',
    'curry powder': 'curry powder',
    'curry': 'curry powder',
    'turmeric': 'turmeric',
    'cloves': 'cloves',

    // ===== SYRUPS & HONEY =====
    'honey': 'honey',
    'maple syrup': 'maple syrup',
    'maple': 'maple syrup',
    'golden syrup': 'golden syrup',
    'corn syrup': 'corn syrup',
    'agave': 'agave syrup',
    'agave syrup': 'agave syrup',
    'agave nectar': 'agave syrup',
    'molasses': 'molasses',

    // ===== LEAVENING =====
    'baking powder': 'baking powder',
    'baking soda': 'baking soda',
    'yeast': 'yeast',
    'instant yeast': 'yeast',
    'active dry yeast': 'yeast',
    'dry yeast': 'yeast',
    'fresh yeast': 'fresh yeast',
    'compressed yeast': 'fresh yeast',

    // ===== CONDIMENTS & SAUCES =====
    'soy sauce': 'soy sauce',
    'tamari': 'tamari',
    'fish sauce': 'fish sauce',
    'hot sauce': 'hot sauce',
    'sriracha': 'sriracha',
    'worcestershire sauce': 'worcestershire sauce',
    'worcestershire': 'worcestershire sauce',
    'ketchup': 'ketchup',
    'tomato ketchup': 'ketchup',
    'mustard': 'mustard',
    'yellow mustard': 'mustard',
    'dijon mustard': 'dijon mustard',
    'dijon': 'dijon mustard',
    'mayonnaise': 'mayonnaise',
    'mayo': 'mayonnaise',
    'pesto': 'pesto',

    // ===== LIQUIDS (juices, broths, stocks) =====
    'lemon juice': 'lemon juice',
    'lime juice': 'lime juice',
    'orange juice': 'orange juice',
    'apple juice': 'apple juice',
    'tomato juice': 'tomato juice',
    'vegetable broth': 'vegetable broth',
    'vegetable stock': 'vegetable stock',
    'chicken broth': 'chicken broth',
    'chicken stock': 'chicken stock',
    'beef broth': 'beef broth',
    'beef stock': 'beef stock',
    'broth': 'vegetable broth',
    'stock': 'vegetable stock',
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

  static String _bestVolumeUnit(
    UnitSystem sys,
    double ml, {
    bool isLiquid = true,
  }) {
    if (sys == UnitSystem.metric) {
      // metric mode: tsp/tbsp for tiny volumes, otherwise ml/l
      if (ml < _toMl(1, 'tsp') * 3) return 'tsp'; // < ~15ml
      if (ml < _toMl(1, 'tbsp') * 2) return 'tbsp'; // < ~30ml
      return ml >= 1000 ? 'l' : 'ml';
    }

    // imperial mode:
    // - for liquids: use cups (or tsp/tbsp for small amounts)
    // - for dry items: use tsp/tbsp/oz
    if (isLiquid) {
      // Liquid mode: prefer cups for larger volumes
      final floz = _fromMl(ml, 'floz');
      if (floz < 1.0) return 'tsp';
      if (floz < 2.0) return 'tbsp';
      final cups = _fromMl(ml, 'cup');
      if (cups < 2.0) return 'cup';
      return 'cup';
    } else {
      // Dry/baking mode: use tsp/tbsp/oz
      final floz = _fromMl(ml, 'floz');
      if (floz < 1.0) return 'tsp';
      if (floz < 2.0) return 'tbsp';
      if (floz < 16.0) return 'floz';
      return 'floz';
    }
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

      if (target == UnitSystem.imperial) {
        // For mass input in imperial:
        // - If we know it's a liquid, convert to volume (cups/tsp/tbsp)
        // - If we know it's baking, prefer volume when possible, else oz
        // - Otherwise, use oz weight
        if (dens != null && dens.isLiquid) {
          // Liquids: convert to volume in cups/tsp/tbsp
          final ml = g / dens.gPerMl;
          final outUnit = _bestVolumeUnit(target, ml, isLiquid: true);
          final outQty = _roundNice(_fromMl(ml, outUnit));
          return UnitValue(outQty, outUnit);
        }
        if (dens != null && !dens.isLiquid) {
          // Dry ingredients: convert to volume first (tsp/tbsp/oz) if possible
          final ml = g / dens.gPerMl;
          final outUnit = _bestVolumeUnit(target, ml, isLiquid: false);
          final outQty = _roundNice(_fromMl(ml, outUnit));
          return UnitValue(outQty, outUnit);
        }
        // Unknown: use oz weight
        final outUnit = _bestMassUnit(target, g);
        final outQty = _roundNice(_fromGrams(g, outUnit));
        return UnitValue(outQty, outUnit);
      }

      // metric or original
      final outUnit = _bestMassUnit(target, g);
      final outQty = _roundNice(_fromGrams(g, outUnit));
      return UnitValue(outQty, outUnit);
    }

    // --- VOLUME INPUT
    if (dim == UnitDim.volume) {
      final ml = _toMl(qty, canon);

      if (target == UnitSystem.imperial) {
        // For volume input in imperial:
        // - If we know it's a liquid, keep as cups/tsp/tbsp
        // - If we know it's dry, convert to tsp/tbsp/oz
        // - Otherwise, default to cups (since user input was volume)
        if (dens != null && !dens.isLiquid) {
          // Dry ingredients can be converted to weight (oz)
          final g = ml * dens.gPerMl;
          final outUnit = _bestMassUnit(target, g);
          final outQty = _roundNice(_fromGrams(g, outUnit));
          return UnitValue(outQty, outUnit);
        }
        // For liquids or unknown: keep as volume
        final outUnit = _bestVolumeUnit(target, ml, isLiquid: true);
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
        target == UnitSystem.metric ? UnitSystem.metric : UnitSystem.imperial,
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
