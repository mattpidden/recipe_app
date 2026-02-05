import 'package:firebase_auth/firebase_auth.dart';
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

  Future<User> signInAnonymouslyIfNeeded() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return auth.currentUser!;
    }
    final credential = await auth.signInAnonymously();
    return credential.user!;
  }

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
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainPage()));
    }
  }

  @override
  void initState() {
    super.initState();
    signInAnonymouslyIfNeeded();
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
      backgroundColor: AppColors.backgroundColour,
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
                        "Save recipes from anywhere - books, links, photos and social.",
                    index: 1,
                    // Swap this placeholder for an image later
                  ),
                  _OutcomePage(
                    headline: "Always know what to cook",
                    subhead:
                        "Made tells you what to cook right now — or plans the week for you.",
                    index: 2,
                  ),
                  _OutcomePage(
                    headline: "Just cook. We’ll handle the rest.",
                    subhead:
                        "Step-by-step cooking with smart timers, swaps and instant conversions.",
                    index: 3,
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
                          ? null
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
  final int index;

  const _OutcomePage({
    required this.headline,
    required this.subhead,
    required this.index,
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
                child: Image.asset("assets/$index.png"),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What matters most to you right now?",
            style: TextStyles.hugeTitle.copyWith(height: 1),
          ),
          const SizedBox(height: 10),
          Text(
            "Choose one. We’ll shape your first experiences around it.",
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: AppColors.primaryTextColour.withAlpha(100),
            ),
          ),
          const SizedBox(height: 16),

          _ChoiceCard(
            title: "Never losing a recipe again",
            subtitle:
                "Save recipes from anywhere - books, links, photos and social.",
            icon: Icons.book,
            selected: selected == "save",
            onTap: () => onSelect("save"),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            title: "Always knowing what to cook",
            subtitle:
                "Made tells you what to cook right now — or plans the week for you.",
            icon: Icons.calendar_month,
            selected: selected == "decide",
            onTap: () => onSelect("decide"),
          ),
          const SizedBox(height: 12),
          _ChoiceCard(
            title: "To enjoy cooking more",
            subtitle:
                "Step-by-step cooking with smart timers, swaps and instant conversions.",
            icon: Icons.timer,
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
        ? const Color.fromARGB(255, 223, 235, 226)
        : Colors.white;

    final border = selected
        ? AppColors.primaryColour
        : AppColors.backgroundColour;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? AppColors.primaryColour
                  : AppColors.disabledColor.withAlpha(155),
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
