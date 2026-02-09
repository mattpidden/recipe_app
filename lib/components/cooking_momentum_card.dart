import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class CookingMomentumCard extends StatelessWidget {
  const CookingMomentumCard({super.key});

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, _) {
        final events = notifier.cookHistory;
        if (events.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final today = _day(now);

        // --- Group by day ---
        final cookedDays = <DateTime>{};
        for (final e in events) {
          cookedDays.add(_day(e.cookedAt));
        }

        // --- Current streak ---
        int streak = 0;
        for (int i = 1; i < 31; i++) {
          final d = today.subtract(Duration(days: i));
          if (cookedDays.contains(d)) {
            streak++;
          } else {
            break;
          }
        }

        // --- Last 7 days activity ---
        final last7 = List.generate(7, (i) {
          final d = today.subtract(Duration(days: 6 - i));
          return cookedDays.contains(d);
        });

        final cookedLastWeek = last7.where((v) => v).length;

        // --- Motivation text ---
        String headline;
        String subline;

        switch (streak) {
          case 0:
            headline = 'Ready to get back in the kitchen?';
            subline = 'No cooking yesterday — today’s a perfect reset';
            break;

          case 1:
            headline = 'Nice start';
            subline = 'One day down — momentum begins with a single cook ✨';
            break;

          case 2:
            headline = 'Two days in a row';
            subline = 'You’re building a habit — keep it rolling 🔁';
            break;

          case 3:
            headline = 'Three-day cooking streak';
            subline = 'That’s consistency showing up — go for four 🔥';
            break;

          case 4:
            headline = 'Four days strong';
            subline = 'At this point it’s a rhythm, not effort 💪';
            break;

          case 5:
            headline = 'Five days cooked';
            subline = 'This is where habits really stick 👌';
            break;

          case 6:
            headline = 'Six-day streak';
            subline = 'One more and you’ve cooked every day this week 👀';
            break;

          default: // 7+
            headline = '${streak}-day cooking streak';
            subline = 'You cooked every day last week — elite stuff 🏆';
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              //Text('Your Cooking Momentum', style: TextStyles.subheading),

              //const SizedBox(height: 6),
              Text(headline, style: TextStyles.subheading),

              //const SizedBox(height: 2),
              Text(subline, style: TextStyles.bodyTextPrimary),

              const SizedBox(height: 12),

              // Mini graph
              Row(
                children: List.generate(7, (i) {
                  final active = last7[i];
                  return Expanded(
                    child: Container(
                      height: active ? 24 : 10,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.accentColour1
                            : AppColors.backgroundColour,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: active
                          ? Image.asset(
                              'assets/white_logo.png',
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Last 7 days',
                      style: TextStyles.tinyTextPrimary,
                    ),
                  ),
                  Text('Today', style: TextStyles.tinyTextPrimary),
                  const SizedBox(width: 4),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
