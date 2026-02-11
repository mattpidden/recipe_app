import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:recipe_app/main_page.dart';
import 'package:recipe_app/notifiers/notifier.dart';
import 'package:recipe_app/styles/colours.dart';
import 'package:recipe_app/styles/text_styles.dart';

class RecipePackDemoPage extends StatefulWidget {
  final String nextPage;
  const RecipePackDemoPage({super.key, required this.nextPage});

  @override
  State<RecipePackDemoPage> createState() => _RecipePackDemoPageState();
}

class _RecipePackDemoPageState extends State<RecipePackDemoPage> {
  final List<_TapConfetti> _confettiBursts = [];
  late final ConfettiController _initConfettiController;

  @override
  void initState() {
    super.initState();
    _initConfettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.lightImpact();
      _initConfettiController.play();
    });
  }

  @override
  void dispose() {
    _initConfettiController.dispose();
    for (final burst in _confettiBursts) {
      burst.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Notifier>(
      builder: (context, notifier, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            HapticFeedback.mediumImpact();

            final controller = ConfettiController(
              duration: const Duration(milliseconds: 200),
            )..play();

            setState(() {
              _confettiBursts.add(
                _TapConfetti(
                  offset: details.localPosition,
                  controller: controller,
                ),
              );
            });
          },
          child: Scaffold(
            backgroundColor: AppColors.backgroundColour,
            body: Stack(
              children: [
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Congratulations!",
                          style: TextStyles.hugeTitle.copyWith(height: 1),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "You've received celebrity chef Eitan Bernath's exclusive Made recipe pack",
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.35,
                            color: AppColors.primaryTextColour.withAlpha(100),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),

                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  child: Image.asset(
                                    "assets/eitan.png",
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const MainPage(),
                                ),
                              );
                            },
                            child: const Text("Continue"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.topCenter,

                  child: ConfettiWidget(
                    confettiController: _initConfettiController,
                    blastDirection: pi / 2,
                    emissionFrequency: 1,
                    numberOfParticles: 10,
                    gravity: 0.2,
                    blastDirectionality: BlastDirectionality.explosive,
                    colors: const [
                      AppColors.primaryColour,
                      Colors.blue,
                      Colors.green,
                      AppColors.accentColour1,
                    ],
                  ),
                ),
                ..._confettiBursts.map(
                  (burst) => Positioned(
                    left: burst.offset.dx,
                    top: burst.offset.dy,
                    child: ConfettiWidget(
                      confettiController: burst.controller,
                      blastDirection: pi / 2,
                      emissionFrequency: 1,
                      numberOfParticles: 10,
                      gravity: 0.2,
                      blastDirectionality: BlastDirectionality.explosive,
                      colors: const [
                        AppColors.primaryColour,
                        Colors.blue,
                        Colors.green,
                        AppColors.accentColour1,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TapConfetti {
  final Offset offset;
  final ConfettiController controller;

  _TapConfetti({required this.offset, required this.controller});
}
