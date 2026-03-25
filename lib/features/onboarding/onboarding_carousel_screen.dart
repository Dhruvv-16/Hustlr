import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart' as app_colors;

class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() => _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.shield_rounded,
      'title': 'Income protection built for gig workers',
      'subtitle': 'Secure your daily earnings against unexpected disruptions, all directly from your phone.',
    },
    {
      'icon': Icons.bolt_rounded,
      'title': 'Get paid when you can’t work',
      'subtitle': 'Automatic payouts triggered by rain, excessive heat, platform downtime, or internet blackouts.',
    },
    {
      'icon': Icons.check_circle_outline_rounded,
      'title': 'Zero hassle. Zero paperwork.',
      'subtitle': 'Our systems verify disruptions automatically. The money lands directly in your UPI wallet.',
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Keep your ISS high',
      'subtitle': 'The fewer non-verified claims you submit, the higher your ISS stays—giving you access to cheaper plans.',
    },
  ];

  void _onNext() async {
    if (_currentPage == _slides.length - 1) {
      // Last slide → go to registration form, not back to login
      if (mounted) context.go('/onboarding');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: app_colors.lightGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide['icon'], size: 80, color: app_colors.primaryGreen),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          slide['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: app_colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['subtitle'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: app_colors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _slides.length,
                      (idx) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == idx ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx ? app_colors.primaryGreen : app_colors.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: app_colors.primaryGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
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
