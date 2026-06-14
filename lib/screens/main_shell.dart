import 'package:flutter/cupertino.dart';
import '../core/constants/colors.dart';
import '../widgets/onboarding_dialog.dart';
import 'home_screen.dart';
import 'trading_screen.dart';
import 'portfolio_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final List<Widget> _screens = const [
    HomeScreen(),
    TradingScreen(),
    PortfolioScreen(), // Represents Tycoon Portfolio
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingService.shouldShowOnboarding();
    if (shouldShow && mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => OnboardingDialog(
          onComplete: () {},
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      backgroundColor: AppColors.background,
      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.75),
        activeColor: AppColors.primary,
        inactiveColor: AppColors.textSecondary,
        height: 56,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.house, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.house_fill, size: 22),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.chart_bar_alt_fill, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.chart_bar_alt_fill, size: 22),
            ),
            label: 'Trading',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.briefcase, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.briefcase_fill, size: 22),
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.person, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(CupertinoIcons.person_fill, size: 22),
            ),
            label: 'Profile',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return _screens[index];
          },
        );
      },
    );
  }
}
