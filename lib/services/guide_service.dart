import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideService {
  static const String _firstTimeKey = 'first_time_user';
  static final List<GuideStep> _guideSteps = [
    GuideStep(
      title: 'Welcome to MaidMatch!',
      description: 'Let us show you around the app.',
      position: const Offset(0.5, 0.5),
    ),
    GuideStep(
      title: 'View Available Jobs',
      description: 'Browse through available job opportunities.',
      position: const Offset(0.2, 0.3),
    ),
    GuideStep(
      title: 'Your Profile',
      description: 'Keep your profile updated to get better matches.',
      position: const Offset(0.8, 0.3),
    ),
    GuideStep(
      title: 'Messages',
      description: 'Chat with potential employers here.',
      position: const Offset(0.5, 0.7),
    ),
  ];

  static Future<bool> isFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstTimeKey) ?? true;
  }

  static Future<void> markGuideComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstTimeKey, false);
  }

  static List<GuideStep> get guideSteps => _guideSteps;
}

class GuideStep {
  final String title;
  final String description;
  final Offset position;

  const GuideStep({
    required this.title,
    required this.description,
    required this.position,
  });
}

class GuideOverlay extends StatefulWidget {
  final Widget child;
  final VoidCallback onComplete;

  const GuideOverlay({
    super.key,
    required this.child,
    required this.onComplete,
  });

  @override
  State<GuideOverlay> createState() => _GuideOverlayState();
}

class _GuideOverlayState extends State<GuideOverlay> {
  int _currentStep = 0;
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final isFirstTime = await GuideService.isFirstTimeUser();
    if (isFirstTime) {
      setState(() => _showGuide = true);
    }
  }

  void _nextStep() {
    if (_currentStep < GuideService.guideSteps.length - 1) {
      setState(() => _currentStep++);
    } else {
      GuideService.markGuideComplete();
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showGuide) return widget.child;

    final step = GuideService.guideSteps[_currentStep];
    final size = MediaQuery.of(context).size;
    final position = Offset(
      step.position.dx * size.width,
      step.position.dy * size.height,
    );

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (details) => _nextStep(),
            child: Container(
              color: Colors.black54,
              child: Stack(
                children: [
                  Positioned(
                    left: position.dx - 75,
                    top: position.dy - 75,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: position.dx - 100,
                    top: position.dy + 90,
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(step.description),
                          const SizedBox(height: 16),
                          Text(
                            'Tap anywhere to continue (${_currentStep + 1}/${GuideService.guideSteps.length})',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
