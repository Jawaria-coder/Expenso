import 'package:flutter/material.dart';
import 'LoginPage.dart';

class OnboardPage {
  final IconData icon;
  final String title;
  final String desc;

  OnboardPage({
    required this.icon,
    required this.title,
    required this.desc,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int _pageIndex = 0;

  final List<OnboardPage> pages = [
    OnboardPage(
        icon: Icons.wallet,
        title: 'Track Expenses',
        desc: 'Manage your money daily'),
    OnboardPage(
        icon: Icons.pie_chart,
        title: 'Set Budgets',
        desc: 'Control your spending smartly'),
    OnboardPage(
        icon: Icons.bar_chart,
        title: 'Visual Reports',
        desc: 'View expenses in graphs'),
    OnboardPage(
        icon: Icons.notifications_active,
        title: 'Get Alerts',
        desc: 'Never overspend again'),
  ];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Color iconPink = const Color(0xFFE2BFD9);    // pink for icons
  final Color customPurple = const Color(0xFF9B59B6); // purple for titles/buttons

  @override
  void initState() {
    super.initState();
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  void _goNext() {
    if (_pageIndex < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _goPrev() {
    if (_pageIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) {
              setState(() => _pageIndex = i);
              _fadeController.reset();
              _fadeController.forward();
            },
            itemCount: pages.length,
            itemBuilder: (_, i) {
              final item = pages[i];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 90, color: iconPink),
                      const SizedBox(height: 40),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: customPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.desc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              );
            },
          ),

          // Left and right arrows at bottom center, spaced left and right
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Opacity(
                    opacity: _pageIndex > 0 ? 1.0 : 0.3,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 28, color: Color(0xFFE2BFD9)),
                      onPressed: _pageIndex > 0 ? _goPrev : null,
                      tooltip: 'Previous',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios,
                        size: 28, color: Color(0xFFE2BFD9)),
                    onPressed: _goNext,
                    tooltip: 'Next',
                  ),
                ],
              ),
            ),
          ),

          // Skip tutorial at bottom center
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _skip,
                child: Text(
                  'Skip tutorial',
                  style: TextStyle(
                    color: customPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
