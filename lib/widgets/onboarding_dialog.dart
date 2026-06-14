import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';

class OnboardingService {
  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('has_seen_onboarding') ?? false);
  }

  static Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
  }
}

class OnboardingDialog extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingDialog({super.key, required this.onComplete});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int _currentIndex = 0;
  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to FunTrade! 🎉',
      'message': 'The ultimate crypto trading simulator. Learn, trade, and become a crypto tycoon without risking real money!',
    },
    {
      'title': 'Earn Virtual Cash 💰',
      'message': 'Watch short ads to earn instant virtual USD! Use these funds to boost your trading capital.',
    },
    {
      'title': 'Daily Bonuses & Games 🎡',
      'message': 'Claim your daily login bonus, try your luck on the Lucky Spin, or pull the lever on the Slot Machine!',
    },
    {
      'title': 'Professional Trading 📈',
      'message': 'Analyze charts and open Long/Short positions with leverage. Use Take Profit and Stop Loss to manage your trades like a pro.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentIndex];
    
    return CupertinoAlertDialog(
      title: Text(page['title']!, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Text(page['message']!, style: GoogleFonts.plusJakartaSans()),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) => 
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: _currentIndex == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? CupertinoColors.activeBlue : CupertinoColors.inactiveGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              ),
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            if (_currentIndex < _pages.length - 1) {
              setState(() => _currentIndex++);
            } else {
              OnboardingService.markOnboardingAsSeen();
              Navigator.pop(context);
              widget.onComplete();
            }
          },
          child: Text(_currentIndex == _pages.length - 1 ? 'Start Trading!' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
