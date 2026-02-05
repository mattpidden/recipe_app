import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/main_page.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _page = 0;

  String? _selectedOutcome; // page 4

  void _next() {
    if (_page < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      // TODO: persist _selectedOutcome, then go to personalised AHA flow / paywall
      // Example:
      // Navigator.of(context).pushReplacementNamed('/paywall');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomPad = media.padding.bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar (skip + progress)
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
              child: Row(
                children: [
                  _Dots(page: _page, count: 4),
                  const Spacer(),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _OutcomePage(
                    headline: "Never lose a recipe again",
                    subhead:
                        "Cookbooks, websites, reels, tiktoks — all saved in one place.",
                    // Swap this placeholder for an image later
                    hero: const _HeroBlob(icon: CupertinoIcons.book),
                  ),
                  _OutcomePage(
                    headline: "Stop deciding what to cook",
                    subhead:
                        "Get a confident suggestion for right now — or a plan for the week.",
                    hero: const _HeroBlob(icon: CupertinoIcons.sparkles),
                  ),
                  _OutcomePage(
                    headline: "Cooking is effortless once you start",
                    subhead:
                        "Step-by-step cooking mode with built-insmart timers, swaps and conversions.",
                    hero: const _HeroBlob(icon: CupertinoIcons.timer),
                  ),
                  _PickOutcomePage(
                    selected: _selectedOutcome,
                    onSelect: (v) => setState(() => _selectedOutcome = v),
                  ),
                ],
              ),
            ),

            // Bottom CTA
            Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 14 + bottomPad),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: (_page == 3 && _selectedOutcome == null)
                          ? () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const MainPage(),
                                ),
                              );
                            }
                          : _next,
                      child: Text(_page < 3 ? "Continue" : "Start"),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomePage extends StatelessWidget {
  final String headline;
  final String subhead;
  final Widget hero;

  const _OutcomePage({
    required this.headline,
    required this.subhead,
    required this.hero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: TextStyles.hugeTitle.copyWith(height: 1)),
          const SizedBox(height: 10),
          Text(
            subhead,
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: AppColors.primaryTextColour.withAlpha(100),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: hero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickOutcomePage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _PickOutcomePage({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = CupertinoTheme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What do you want first?",
            style: t.navLargeTitleTextStyle.copyWith(
              fontSize: 30,
              height: 1.05,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Choose one. We’ll shape your first experiences around it.",
            style: t.textStyle.copyWith(
              fontSize: 16,
              height: 1.35,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 16),

          _ChoiceCard(
            title: "Never lose a recipe again",
            subtitle:
                "Save books, links & screenshots. Find anything instantly.",
            icon: CupertinoIcons.book,
            selected: selected == "save",
            onTap: () => onSelect("save"),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            title: "Stop deciding what to cook",
            subtitle:
                "Get a confident “cook now” and a weekly plan when you want it.",
            icon: CupertinoIcons.sparkles,
            selected: selected == "decide",
            onTap: () => onSelect("decide"),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            title: "Cooking is effortless once you start",
            subtitle:
                "Guided steps, timers, swaps and conversions made simple.",
            icon: CupertinoIcons.timer,
            selected: selected == "cook",
            onTap: () => onSelect("cook"),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = CupertinoTheme.of(context).textTheme;

    final bg = selected
        ? CupertinoTheme.of(context).primaryColor.withOpacity(0.12)
        : CupertinoColors.systemGrey6;

    final border = selected
        ? CupertinoTheme.of(context).primaryColor.withOpacity(0.45)
        : CupertinoColors.systemGrey4.withOpacity(0.35);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: t.textStyle.copyWith(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (selected)
                        const Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          size: 20,
                        ),
                      if (!selected)
                        const Icon(
                          CupertinoIcons.circle,
                          size: 20,
                          color: CupertinoColors.systemGrey2,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: t.textStyle.copyWith(
                      fontSize: 14,
                      height: 1.25,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int page;
  final int count;

  const _Dots({required this.page, required this.count});

  @override
  Widget build(BuildContext context) {
    final active = CupertinoTheme.of(context).primaryColor;
    return Row(
      children: List.generate(count, (i) {
        final isActive = i == page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? active : CupertinoColors.systemGrey4,
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}

class _HeroBlob extends StatelessWidget {
  final IconData icon;
  const _HeroBlob({required this.icon});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.08,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: CupertinoColors.systemGrey4.withOpacity(0.35),
          ),
        ),
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 46),
          ),
        ),
      ),
    );
  }
}
