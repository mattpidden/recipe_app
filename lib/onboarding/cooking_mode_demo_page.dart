import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/classes/ingredient.dart';
import 'package:recipe_app/classes/unit_value.dart';
import 'package:recipe_app/components/ingredient_pill.dart';
import 'package:recipe_app/main_page.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/pages/cooked_sheet.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CookingModeDemoPage extends StatefulWidget {
  const CookingModeDemoPage({super.key});

  @override
  State<CookingModeDemoPage> createState() => _CookingModeDemoPageState();
}

class _CookingModeDemoPageState extends State<CookingModeDemoPage> {
  String? recipeId;
  int interactions = 0;
  final GlobalKey _ingredientsKey = GlobalKey();
  final GlobalKey _stepsKey = GlobalKey();
  final GlobalKey _conversionKey = GlobalKey();
  late final PageController _controller;
  int _index = 0;
  List<Ingredient> subs = [];
  final Map<String, List<Ingredient>> _subsByKey = {};
  final Map<int, List<bool>> _checksByStep = {};
  final Map<int, bool> _showIngredientsByStep = {};
  final Map<int, Duration> _timerSetByStep = {}; // chosen duration (stable)
  final Map<int, DateTime?> _timerEndsAtByStep = {}; // when it should finish
  final Map<int, Duration> _timerPausedLeftByStep = {}; // left when paused
  final Map<int, bool> _timerRunningByStep = {};
  final Map<int, bool> _timerPausedByStep = {};
  Timer? _uiTick; // just for repainting the countdown text
  late final AudioPlayer _player;

  void addInteraction() {
    interactions++;
    if (interactions >= 4 && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    }
  }

  void _initAudio() {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Duration _remaining(int stepIndex) {
    if ((_timerRunningByStep[stepIndex] ?? false) == true) {
      final end = _timerEndsAtByStep[stepIndex];
      if (end == null) return Duration.zero;
      final d = end.difference(DateTime.now());
      return d.isNegative ? Duration.zero : d;
    }
    if ((_timerPausedByStep[stepIndex] ?? false) == true) {
      return _timerPausedLeftByStep[stepIndex] ?? Duration.zero;
    }
    return _timerSetByStep[stepIndex] ?? const Duration(minutes: 5);
  }

  List<String> _makeChecklist(String step) {
    final s = step.trim();
    if (s.isEmpty) return const [];

    // 1) Split on sentence boundaries + newlines (keep punctuation with previous piece)
    final sentences = s
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // 2) Further split on "then", keeping "Then" on the next chunk
    final items = <String>[];
    final thenRe = RegExp(r'\bthen\b', caseSensitive: false);

    for (final part in sentences) {
      final matches = thenRe.allMatches(part).toList();
      if (matches.isEmpty) {
        items.add(part);
        continue;
      }

      int start = 0;
      for (final m in matches) {
        final before = part.substring(start, m.start).trim();
        if (before.isNotEmpty) items.add(before);
        start = m.start; // keep "then" for next chunk
      }
      final tail = part.substring(start).trim();
      if (tail.isNotEmpty) items.add(tail);
    }

    // 3) Clean formatting: Capital letter + trailing full stop
    String format(String t) {
      var x = t.trim();
      if (x.isEmpty) return x;

      x = x[0].toUpperCase() + x.substring(1);

      final endsWithPunct = RegExp(r'[.!?,;:]$').hasMatch(x);
      if (!endsWithPunct) x = '$x.';

      // If it ends with ! or ?, normalize to full stop as requested
      x = x.replaceAll(RegExp(r'[!?,;:]$'), '.');

      return x;
    }

    final out = items.map(format).where((x) => x.isNotEmpty).toList();

    // If splitting produced basically nothing useful, fall back to single item
    if (out.length <= 1) {
      return [format(s)];
    }

    return out;
  }

  List<Duration> _extractDurations(String step) {
    final s = step.toLowerCase();

    final results = <Duration>[];

    final secMatches = RegExp(
      r'(\d+)\s*(sec|secs|second|seconds)\b',
    ).allMatches(s);
    for (final s in secMatches) {
      final n = int.tryParse(s.group(1) ?? '');
      if (n != null && n > 0) results.add(Duration(seconds: n));
    }

    // e.g. "10 min", "10 mins", "10 minutes"
    final minMatches = RegExp(
      r'(\d+)\s*(min|mins|minute|minutes)\b',
    ).allMatches(s);
    for (final m in minMatches) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null && n > 0) results.add(Duration(minutes: n));
    }

    // e.g. "1 hour", "2 hrs", "1.5 hours"
    final hrMatches = RegExp(
      r'(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours)\b',
    ).allMatches(s);
    for (final m in hrMatches) {
      final n = double.tryParse(m.group(1) ?? '');
      if (n != null && n > 0) {
        final mins = (n * 60).round();
        results.add(Duration(minutes: mins));
      }
    }

    // Dedup
    final seen = <int>{};
    return results.where((d) => seen.add(d.inSeconds)).toList();
  }

  String _fmtShort(Duration d) {
    final total = d.inSeconds;
    final m = total ~/ 60;
    final s = total % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = m % 60;
      return '${h}h ${mm}m';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  void _ensureTimerDefaults(int stepIndex, List<Duration> options) {
    final fallback = options.isNotEmpty
        ? options.first
        : const Duration(minutes: 5);

    _timerSetByStep.putIfAbsent(stepIndex, () => fallback);

    _timerRunningByStep.putIfAbsent(stepIndex, () => false);
    _timerPausedByStep.putIfAbsent(stepIndex, () => false);
  }

  void _startOrResumeTimer(int stepIndex) {
    addInteraction();
    final running = _timerRunningByStep[stepIndex] ?? false;
    if (running) return;

    final paused = _timerPausedByStep[stepIndex] ?? false;

    final Duration base = paused
        ? (_timerPausedLeftByStep[stepIndex] ?? const Duration(minutes: 5))
        : (_timerSetByStep[stepIndex] ?? const Duration(minutes: 5));

    _timerEndsAtByStep[stepIndex] = DateTime.now().add(base);
    _timerRunningByStep[stepIndex] = true;
    _timerPausedByStep[stepIndex] = false;

    setState(() {});
  }

  void _pauseTimer(int stepIndex) {
    final end = _timerEndsAtByStep[stepIndex];
    if (end != null) {
      final left = end.difference(DateTime.now());
      _timerPausedLeftByStep[stepIndex] = left.isNegative
          ? Duration.zero
          : left;
    }

    _timerEndsAtByStep[stepIndex] = null;
    _timerRunningByStep[stepIndex] = false;
    _timerPausedByStep[stepIndex] = true;

    setState(() {});
  }

  void _resetTimer(int stepIndex) {
    _timerEndsAtByStep[stepIndex] = null;
    _timerPausedLeftByStep[stepIndex] = Duration.zero;
    _timerRunningByStep[stepIndex] = false;
    _timerPausedByStep[stepIndex] = false;

    setState(() {});
  }

  void _applyTimerSet(int stepIndex, Duration d) {
    _timerSetByStep[stepIndex] = d;

    final running = _timerRunningByStep[stepIndex] ?? false;
    if (!running) {
      _timerPausedLeftByStep[stepIndex] = Duration.zero;
      _timerPausedByStep[stepIndex] = false;
      _timerEndsAtByStep[stepIndex] = null;
    }

    setState(() {});
  }

  void _showTimerSheet(int stepIndex, List<Duration> options) {
    _ensureTimerDefaults(stepIndex, options);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundColour,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final running = _timerRunningByStep[stepIndex] ?? false;
            final paused = _timerPausedByStep[stepIndex] ?? false;
            final setDur = _timerSetByStep[stepIndex]!;
            final rem = _remaining(stepIndex);

            String primaryLabel;
            VoidCallback? primaryAction;

            if (running) {
              primaryLabel = 'Pause';
              primaryAction = () => _pauseTimer(stepIndex);
            } else if (paused && rem > Duration.zero) {
              primaryLabel = 'Resume';
              primaryAction = () => _startOrResumeTimer(stepIndex);
            } else {
              primaryLabel = 'Start';
              primaryAction = options.isEmpty
                  ? null
                  : () => _startOrResumeTimer(stepIndex);
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${options.length > 1 ? "Select " : ""}Timer',
                      style: TextStyles.subheading,
                    ),
                    const SizedBox(height: 12),

                    if (options.length > 1)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: options.map((d) {
                          final selected = d.inSeconds == setDur.inSeconds;
                          return GestureDetector(
                            onTap: () {
                              _applyTimerSet(stepIndex, d);
                              setModalState(
                                () {},
                              ); // ✅ refresh the sheet UI now
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accentColour1
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _fmtShort(d),
                                style: selected
                                    ? TextStyles.bodyTextBoldAccent.copyWith(
                                        color: AppColors.secondaryTextColour,
                                      )
                                    : TextStyles.bodyTextBoldAccent,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    if (options.length > 1) const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: primaryAction == null
                                ? null
                                : () {
                                    primaryAction!();
                                    setModalState(
                                      () {},
                                    ); // ✅ update label (Start/Pause/Resume)
                                    Navigator.pop(context);
                                  },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: primaryAction == null
                                    ? Colors.grey.withAlpha(60)
                                    : AppColors.primaryColour,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  primaryLabel,
                                  style: TextStyles.smallHeadingSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _resetTimer(stepIndex);
                              setModalState(
                                () {},
                              ); // ✅ refresh countdown + selected chip state
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Reset',
                                  style: TextStyles.smallHeading,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Ingredient _displayIngredient(Ingredient base, UnitSystem unitSystem) {
    final qScaled = (base.quantity == null) ? null : base.quantity!;

    if (unitSystem == UnitSystem.original) {
      return Ingredient(
        raw: base.raw,
        quantity: qScaled,
        unit: base.unit,
        item: base.item,
        notes: base.notes,
      );
    }

    final converted = UnitConverter.convert(
      qScaled,
      base.unit,
      unitSystem,
      ingredient: base.item,
    );

    return Ingredient(
      raw: base.raw, // keep original raw as “source of truth”
      quantity: converted.qty,
      unit: converted.unit,
      item: base.item,
      notes: base.notes,
    );
  }

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

  void _showTutorial() {
    final targets = <TargetFocus>[
      TargetFocus(
        identify: "ingreds",
        keyTarget: _ingredientsKey,
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        radius: 10,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "This is the ingredients list for each step. This shows the quantity, so you don't need to keep referring back to the main ingredient list.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "steps",
        keyTarget: _stepsKey,
        shape: ShapeLightFocus.RRect,
        enableOverlayTab: true,
        radius: 10,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "This are the steps for this recipe. You can tap on a step to check it complete.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),

      TargetFocus(
        identify: "convert",
        keyTarget: _conversionKey,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        enableOverlayTab: true,
        color: AppColors.primaryTextColour,
        paddingFocus: 16,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "Tap here to change the measurement units. You can choose between metric, imperial, or the original units from the recipe.",
              style: TextStyles.smallHeadingSecondary,
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      hideSkip: true,
      pulseEnable: true,
      opacityShadow: 0.9,
      pulseAnimationDuration: Duration(seconds: 1),
    ).show(context: context);
  }

  @override
  void initState() {
    super.initState();

    final recipes = context.read<Notifier>().recipes.isNotEmpty;
    if (!recipes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute(builder: (_) => const MainPage()));
      });
    } else {
      recipeId = context.read<Notifier>().recipes.first.id;
    }

    _controller = PageController();
    WakelockPlus.enable();
    _uiTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _checkCompletions();
      setState(() {});
    });
    _initAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorial();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _controller.dispose();
    _uiTick?.cancel();
    _uiTick = null;
    _player.dispose();
    super.dispose();
  }

  void _go(int i, int max) {
    final next = i.clamp(0, max - 1);
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> handleSubs(String key, String recipe, String ingredient) async {
    try {
      final fn = FirebaseFunctions.instanceFor(
        region: 'europe-west2',
      ).httpsCallable('substituteIngredient');

      final res = await fn.call({'recipe': recipe, 'ingredient': ingredient});
      final rawList = List.from(res.data);
      final listOfSubs = rawList
          .map((e) => Ingredient.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (!mounted) return;
      setState(() => _subsByKey[key] = listOfSubs);
      addInteraction();
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to find substitutes',
            style: TextStyles.smallHeadingSecondary,
          ),
          backgroundColor: AppColors.primaryColour,
        ),
      );
    }
  }

  List<InlineSpan> _stepSpans(
    String text,
    int stepIndex,
    List<Duration> options,
  ) {
    final re = RegExp(
      r'(\d+(?:\.\d+)?)\s*(sec|secs|second|seconds|min|mins|minute|minutes|h|hr|hrs|hour|hours)\b',
      caseSensitive: false,
    );

    Duration? toDuration(RegExpMatch m) {
      final n = double.tryParse(m.group(1) ?? '');
      if (n == null || n <= 0) return null;

      final unit = (m.group(2) ?? '').toLowerCase();

      if (unit.startsWith('sec')) return Duration(seconds: n.round());
      if (unit.startsWith('min')) return Duration(minutes: n.round());

      // hours (allow 1.5 hours etc)
      final mins = (n * 60).round();
      return Duration(minutes: mins);
    }

    final spans = <InlineSpan>[];
    var last = 0;

    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }

      final d = toDuration(m);
      final label = text.substring(m.start, m.end);

      if (d == null) {
        spans.add(TextSpan(text: label));
      } else {
        spans.add(
          TextSpan(
            text: label,
            style: TextStyles.pageTitle.copyWith(
              color: AppColors.primaryColour,
              fontWeight: FontWeight.bold,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // If this exact duration exists in the options, select it before opening
                final match = options.where((o) => o.inSeconds == d.inSeconds);
                if (match.isNotEmpty) _applyTimerSet(stepIndex, match.first);

                _showTimerSheet(stepIndex, options);
              },
          ),
        );
      }

      last = m.end;
    }

    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }

    return spans;
  }

  void _checkCompletions() {
    for (final entry in _timerEndsAtByStep.entries) {
      final i = entry.key;
      final end = entry.value;
      if (end == null) continue;

      if (DateTime.now().isAfter(end)) {
        _timerEndsAtByStep[i] = null;
        _timerRunningByStep[i] = false;
        _timerPausedByStep[i] = false;
        _timerPausedLeftByStep[i] = Duration.zero;
      }
    }
  }

  List<Ingredient> _ingredientsForStep(String step, List<Ingredient> all) {
    final s = step.toLowerCase();

    // words we don’t care about when matching
    const stopWords = {
      // prep / quality / size
      'fresh', 'ripe', 'large', 'small', 'medium', 'little', 'tiny', 'big',
      'extra', 'optional',

      // texture / cut
      'finely', 'roughly', 'coarsely', 'thinly', 'thickly',
      'chopped', 'slice', 'sliced', 'diced', 'minced', 'crushed', 'grated',
      'peeled', 'seeded', 'cored', 'trimmed', 'rinsed', 'washed', 'drained',
      'softened', 'melted',

      // temperature / state
      'warm', 'hot', 'cold', 'cool', 'room', 'temperature',

      // quantities / modifiers
      'to', 'taste', 'or', 'and', 'a', 'an', 'the', 'of', 'in', 'into', 'with',
      'for', 'on', 'at', 'from', 'by', 'per',
      'plus', 'more', 'less', 'few', 'some', 'about', 'around',
      'approx', 'approximately',

      // cooking flow words
      'then', 'until', 'when', 'while', 'after', 'before',
      'once', 'just', 'well',

      // recipe bookkeeping
      'remaining', 'rest', 'reserved', 'divided', 'separated',
      'mixture', 'ingredients',

      // very generic actions (don’t help identify ingredients)
      'add', 'mix', 'stir', 'cook', 'bake', 'fry', 'heat', 'place', 'set',
    };

    List<String> normalise(String text) {
      return text
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z\s]'), '')
          .split(' ')
          .where((w) => w.length > 2 && !stopWords.contains(w))
          .map(
            (w) => w.endsWith('s') ? w.substring(0, w.length - 1) : w,
          ) // plural → singular
          .toList();
    }

    final stepTokens = normalise(s);

    final hits = <Ingredient>[];

    for (final ing in all) {
      final base = ing.item?.isNotEmpty == true ? ing.item! : ing.raw;
      final ingTokens = normalise(base);

      if (ingTokens.isEmpty) continue;

      // match if *any* meaningful token appears in the step
      final match = ingTokens.any((t) => stepTokens.contains(t));

      if (match) hits.add(ing);
    }

    // de-dupe by raw text
    final seen = <String>{};
    return hits.where((i) => seen.add(i.raw.toLowerCase())).toList();
  }

  void handleRemoveSubs(String key) {
    setState(() => _subsByKey.remove(key));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, _) {
        if (recipeId == null) {
          return Scaffold(backgroundColor: AppColors.backgroundColour);
        }
        final recipe = notifier.recipes.firstWhere((r) => r.id == recipeId);

        final steps = recipe.steps.where((s) => s.trim().isNotEmpty).toList();
        final total = steps.isEmpty ? 1 : steps.length;

        return Scaffold(
          backgroundColor: AppColors.backgroundColour,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: TextStyles.pageTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_index + 1}/$total',
                            style: TextStyles.bodyTextBoldAccent,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "Your screen will not turn off whilst on this page",
                        style: TextStyles.captionText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: steps.isEmpty
                          ? Center(
                              child: Text(
                                'No steps yet.',
                                style: TextStyles.subheading,
                              ),
                            )
                          : PageView.builder(
                              controller: _controller,
                              itemCount: steps.length,
                              onPageChanged: (i) => setState(() => _index = i),
                              itemBuilder: (context, i) {
                                final step = steps[i];
                                final stepIngredients = _ingredientsForStep(
                                  step,
                                  recipe.ingredients,
                                );

                                final checklist = _makeChecklist(step);
                                _checksByStep.putIfAbsent(
                                  i,
                                  () => List<bool>.filled(
                                    checklist.length,
                                    false,
                                  ),
                                );

                                final durations = _extractDurations(step);
                                _ensureTimerDefaults(i, durations);

                                final expanded =
                                    _showIngredientsByStep[i] ?? true;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // header row
                                        Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: AppColors.accentColour1,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${i + 1}',
                                                  style: TextStyles
                                                      .smallHeadingSecondary,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Step ${i + 1}',
                                                style: TextStyles.subheading,
                                              ),
                                            ),
                                            if (durations.isNotEmpty) ...[
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .backgroundColour,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: Text(
                                                  _fmtShort(_remaining(i)),
                                                  style: TextStyles
                                                      .bodyTextBoldAccent,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _showTimerSheet(
                                                  i,
                                                  durations,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        AppColors.primaryColour,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.timer,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        (_timerRunningByStep[i] ??
                                                                false)
                                                            ? 'Running'
                                                            : 'Timer',
                                                        style: TextStyles
                                                            .bodyTextBoldSecondary,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),

                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // ✅ "You'll need" bar + inline expandable ingredients list
                                                if (stepIngredients
                                                    .isNotEmpty) ...[
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _showIngredientsByStep[i] =
                                                            !(_showIngredientsByStep[i] ??
                                                                false);
                                                      });
                                                    },
                                                    child: Container(
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .backgroundColour,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              "You’ll need • ${stepIngredients.length} ingredient${stepIngredients.length == 1 ? '' : 's'}",
                                                              style: TextStyles
                                                                  .bodyTextBoldAccent,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Icon(
                                                            expanded
                                                                ? Icons
                                                                      .keyboard_arrow_up
                                                                : Icons
                                                                      .keyboard_arrow_down,
                                                            color: AppColors
                                                                .primaryTextColour,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  const SizedBox(height: 8),
                                                  AnimatedSize(
                                                    duration: const Duration(
                                                      milliseconds: 180,
                                                    ),
                                                    curve: Curves.easeOut,
                                                    child: expanded
                                                        ? Container(
                                                            key:
                                                                _ingredientsKey,
                                                            width:
                                                                double.infinity,
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  10,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: AppColors
                                                                  .backgroundColour,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: Text(
                                                                        "Ingredients",
                                                                        style: TextStyles
                                                                            .subheading,
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 8,
                                                                    ),
                                                                    GestureDetector(
                                                                      key:
                                                                          _conversionKey,
                                                                      onTap: () {
                                                                        addInteraction();
                                                                        showModalBottomSheet(
                                                                          context:
                                                                              context,
                                                                          backgroundColor:
                                                                              AppColors.primaryColour,
                                                                          shape: const RoundedRectangleBorder(
                                                                            borderRadius: BorderRadius.vertical(
                                                                              top: Radius.circular(
                                                                                16,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          builder: (_) {
                                                                            Widget
                                                                            option(
                                                                              String
                                                                              label,
                                                                              UnitSystem
                                                                              mode,
                                                                            ) {
                                                                              final selected =
                                                                                  notifier.unitSystem ==
                                                                                  mode;
                                                                              return ListTile(
                                                                                title: Text(
                                                                                  label,
                                                                                  style: TextStyles.smallHeadingSecondary,
                                                                                ),
                                                                                trailing: selected
                                                                                    ? const Icon(
                                                                                        Icons.check,
                                                                                        color: Colors.white,
                                                                                      )
                                                                                    : null,
                                                                                onTap: () {
                                                                                  Navigator.pop(
                                                                                    context,
                                                                                  );
                                                                                  notifier.updateUnitSystem(
                                                                                    mode,
                                                                                  );
                                                                                },
                                                                              );
                                                                            }

                                                                            return SafeArea(
                                                                              child: Padding(
                                                                                padding: const EdgeInsets.all(
                                                                                  12,
                                                                                ),
                                                                                child: Column(
                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                  children: [
                                                                                    option(
                                                                                      "Original",
                                                                                      UnitSystem.original,
                                                                                    ),
                                                                                    option(
                                                                                      "Metric",
                                                                                      UnitSystem.metric,
                                                                                    ),
                                                                                    option(
                                                                                      "Imperial",
                                                                                      UnitSystem.imperial,
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      child: Container(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          horizontal:
                                                                              8,
                                                                          vertical:
                                                                              2,
                                                                        ),
                                                                        decoration: BoxDecoration(
                                                                          color:
                                                                              AppColors.primaryColour,
                                                                          borderRadius: BorderRadius.circular(
                                                                            10,
                                                                          ),
                                                                        ),
                                                                        child: Row(
                                                                          children: [
                                                                            Icon(
                                                                              Icons.balance,
                                                                              size: 14,
                                                                              color: AppColors.secondaryTextColour,
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 4,
                                                                            ),
                                                                            Text(
                                                                              viewModeLabel(
                                                                                notifier.unitSystem,
                                                                              ),
                                                                              style: TextStyles.bodyTextBoldSecondary,
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),

                                                                ...List.generate(
                                                                  stepIngredients
                                                                      .length,
                                                                  (
                                                                    ingredIndex,
                                                                  ) {
                                                                    final ingred =
                                                                        stepIngredients[ingredIndex];
                                                                    final displayIngred =
                                                                        _displayIngredient(
                                                                          ingred,
                                                                          notifier
                                                                              .unitSystem,
                                                                        );
                                                                    final subKey =
                                                                        '$i|${ingred.raw.toLowerCase()}';

                                                                    return Padding(
                                                                      padding: const EdgeInsets.only(
                                                                        bottom:
                                                                            6,
                                                                      ),
                                                                      child: ParsedIngredientPill(
                                                                        ingredient:
                                                                            displayIngred,
                                                                        showSubOption:
                                                                            true,
                                                                        onSub: () => handleSubs(
                                                                          subKey,
                                                                          recipe
                                                                              .title,
                                                                          "${ingred.quantity ?? ''} ${ingred.unit ?? ''} ${ingred.item ?? ingred.raw}"
                                                                              .trim(),
                                                                        ),
                                                                        removeSubs: () =>
                                                                            handleRemoveSubs(
                                                                              subKey,
                                                                            ),
                                                                        subs:
                                                                            _subsByKey[subKey] ??
                                                                            const [],
                                                                        scale:
                                                                            1.0,
                                                                        unitSystem:
                                                                            notifier.unitSystem,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          )
                                                        : const SizedBox.shrink(),
                                                  ),

                                                  const SizedBox(height: 12),
                                                ],

                                                // checklist / step text
                                                Column(
                                                  key: _stepsKey,
                                                  children: [
                                                    ...List.generate(checklist.length, (
                                                      j,
                                                    ) {
                                                      final checked =
                                                          _checksByStep[i]![j];
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              bottom: 12,
                                                            ),
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            setState(
                                                              () =>
                                                                  _checksByStep[i]![j] =
                                                                      !checked,
                                                            );
                                                            addInteraction();
                                                          },
                                                          child: Row(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Container(
                                                                width: 26,
                                                                height: 26,
                                                                decoration: BoxDecoration(
                                                                  color: checked
                                                                      ? AppColors
                                                                            .accentColour1
                                                                      : AppColors
                                                                            .backgroundColour,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        8,
                                                                      ),
                                                                ),
                                                                child: const Icon(
                                                                  Icons.check,
                                                                  size: 16,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Expanded(
                                                                child: RichText(
                                                                  text: TextSpan(
                                                                    style: TextStyles
                                                                        .pageTitle
                                                                        .copyWith(
                                                                          color:
                                                                              AppColors.primaryTextColour,
                                                                        ),
                                                                    children: _stepSpans(
                                                                      checklist[j],
                                                                      i,
                                                                      durations,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _go(_index - 1, total),
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: _index <= 0
                                      ? AppColors.backgroundColour
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    _index <= 0 ? "" : 'Back',
                                    style: TextStyles.smallHeading,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (_index >= steps.length - 1) {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: AppColors.backgroundColour,
                                    builder: (_) => CookedSheet(
                                      recipe: recipe,
                                      onSave: () {},
                                    ),
                                  );

                                  Navigator.pop(context);
                                } else {
                                  _go(_index + 1, total);
                                }
                              },
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColour,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    _index >= steps.length - 1
                                        ? "Done"
                                        : 'Next',
                                    style: TextStyles.smallHeadingSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: double.infinity),
                    IntrinsicHeight(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: 300),
                        width: double.infinity,

                        margin: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 100,
                        ),
                        padding: const EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                          color: Colors.white.withAlpha(200),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 15,
                              spreadRadius: 0.1,
                              color: Color.fromARGB(255, 203, 207, 202),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Try tapping on ingredients to see substitutions, and checking off steps as you go, and using the built in timers!",
                            style: TextStyles.smallHeading,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
