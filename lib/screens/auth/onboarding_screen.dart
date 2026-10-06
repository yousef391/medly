import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Bienvenue sur Medly',
      'description': 'Votre partenaire pour la gestion et l\'envoi de campagnes SMS en masse. Rapide, fluide et efficace.',
    },
    {
      'title': 'Automatisez vos envois',
      'description': 'Connectez-vous à l\'API Yalidine et envoyez des notifications SMS automatiques à vos clients en temps réel.',
    },
    {
      'title': 'Analysez et suivez',
      'description': 'Gardez un œil sur vos statistiques, le taux de réussite de vos campagnes et l\'historique de vos envois.',
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false, // Image goes to the very top edge
        child: Column(
          children: [
            // Fixed Top Image taking 60% of the space
            Expanded(
              flex: 60,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/onboarding1.png'),
                    fit: BoxFit.contain, // contain ensures the full illustration is visible
                  ),
                ),
              ),
            ),
            
            // Sliding Content area taking 40% of the space
            Expanded(
              flex: 40,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  final data = _onboardingData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Page Indicators (Dots)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _onboardingData.length,
                            (dotIndex) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: _currentIndex == dotIndex ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentIndex == dotIndex 
                                    ? AppColors.primary 
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Title
                        Text(
                          data['title']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: const Color(0xFF1A1A1A), // Dark text for white background
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          data['description']!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF666666), // Medium grey text
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Bottom Controls (SKIP / NEXT)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 32.0, right: 32.0, bottom: 24.0, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // SKIP Text Button
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF666666),
                      ),
                      child: const Text(
                        'PASSER',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    
                    // NEXT / START Button
                    ElevatedButton(
                      onPressed: () {
                        if (_currentIndex == _onboardingData.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.background, // Dark button for white theme
                        foregroundColor: Colors.white, // Text color
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: Text(
                        _currentIndex == _onboardingData.length - 1 
                            ? 'DÉMARRER' 
                            : 'SUIVANT',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
