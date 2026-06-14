import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';
import '../core/utils/formatter.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_background.dart';
import '../core/services/ad_service.dart';
import 'daily_bonus_screen.dart';
import 'lucky_spin_screen.dart';
import 'slot_machine_screen.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isClaimingWelcome = false;
  bool _isClaimingVideo = false;
  bool _hasClaimedWelcome = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadWelcomeStatus();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _loadWelcomeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasClaimedWelcome = prefs.getBool('claimed_welcome_first') ?? false;
    });
  }

  void _watchAdWelcome(BuildContext context) {
    if (_isClaimingWelcome) return;
    
    final adService = Provider.of<AdService>(context, listen: false);
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);

    setState(() {
      _isClaimingWelcome = true;
    });

    adService.showRewardedAd(
      onUserEarnedReward: () async {
        final prefs = await SharedPreferences.getInstance();
        final hasClaimedFirst = prefs.getBool('claimed_welcome_first') ?? false;
        
        double reward = 1000.00;
        if (!hasClaimedFirst) {
          reward = 1000.00;
          await prefs.setBool('claimed_welcome_first', true);
          if (mounted) {
            setState(() {
              _hasClaimedWelcome = true;
            });
          }
        }
        
        portfolio.claimAdReward(reward);
        _showSuccessDialog('Welcome Bonus Claimed!', 'You have successfully earned ${AppFormatter.formatCurrency(reward)} virtual USD.');
      },
      onAdDismissed: () {
        if (mounted) setState(() => _isClaimingWelcome = false);
      },
      onAdFailedToLoad: () {
        if (mounted) setState(() => _isClaimingWelcome = false);
        _showErrorDialog();
      },
    );
  }

  void _watchAdVideo(BuildContext context) {
    if (_isClaimingVideo) return;
    
    final adService = Provider.of<AdService>(context, listen: false);
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);

    setState(() {
      _isClaimingVideo = true;
    });

    adService.showRewardedAd(
      onUserEarnedReward: () {
        portfolio.claimAdReward(200.00);
        _showSuccessDialog('Video Bonus Claimed!', 'You have successfully earned +\$200.00 virtual USD.');
      },
      onAdDismissed: () {
        if (mounted) setState(() => _isClaimingVideo = false);
      },
      onAdFailedToLoad: () {
        if (mounted) setState(() => _isClaimingVideo = false);
        _showErrorDialog();
      },
    );
  }

  // Daily bonus is now handled in the DailyBonusScreen page.

  void _showSuccessDialog(String title, String message) {
    PremiumDialog.show(
      context,
      title: title,
      message: message,
      emoji: '🎉',
      confirmText: 'Great',
    );
  }

  void _showErrorDialog() {
    PremiumDialog.show(
      context,
      title: 'Ad Not Ready',
      message: 'The rewarded video is currently buffering. Please try again in a few seconds.',
      emoji: '⏳',
      confirmText: 'OK',
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = Provider.of<PortfolioProvider>(context);
    final allTimeProfit = portfolio.totalEquity - 1000.00;
    final investedAmount = portfolio.openPositions.fold(0.0, (sum, pos) => sum + pos.margin);
    
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: LiquidBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              // ─── Header Row ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        portfolio.username,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      CupertinoIcons.bell,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Balance Card ───
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0E76FD),
                      Color(0xFF1D4ED8),
                      Color(0xFF1E40AF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0E76FD).withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Virtual Balance',
                          style: GoogleFonts.plusJakartaSans(
                            color: CupertinoColors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                allTimeProfit >= 0 
                                    ? CupertinoIcons.arrow_up_right 
                                    : CupertinoIcons.arrow_down_right,
                                color: CupertinoColors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppFormatter.formatPnL(allTimeProfit),
                                style: GoogleFonts.plusJakartaSans(
                                  color: CupertinoColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppFormatter.formatCurrency(portfolio.totalEquity),
                      style: GoogleFonts.plusJakartaSans(
                        color: CupertinoColors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 0.5,
                      color: CupertinoColors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceMetric(
                            'Available',
                            AppFormatter.formatCurrency(portfolio.balance),
                            CupertinoIcons.checkmark_shield,
                          ),
                        ),
                        Container(
                          width: 0.5,
                          height: 36,
                          color: CupertinoColors.white.withValues(alpha: 0.15),
                        ),
                        Expanded(
                          child: _buildBalanceMetric(
                            'Invested',
                            AppFormatter.formatCurrency(investedAmount),
                            CupertinoIcons.chart_pie,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Welcome Bonus Banner ───
              if (!_hasClaimedWelcome) ...[
                GestureDetector(
                  onTap: () => _watchAdWelcome(context),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFF59E0B),
                              Color.lerp(
                                const Color(0xFFF59E0B),
                                const Color(0xFFEF4444),
                                _pulseController.value * 0.3,
                              )!,
                              const Color(0xFFD97706),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.25 + _pulseController.value * 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: CupertinoColors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: const Text('💰', style: TextStyle(fontSize: 26)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Bonus',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: CupertinoColors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Claim \$1,000 virtual USD now!',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: CupertinoColors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _isClaimingWelcome
                                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Claim',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: CupertinoColors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ─── Quick Actions Section ───
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 14),
                child: Text(
                  'Quick Actions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              // Feature Grid Games
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _buildGridItem(
                    title: '\$200\nfor video',
                    icon: CupertinoIcons.play_circle_fill,
                    iconColor: const Color(0xFF8B5CF6),
                    gradientColors: [const Color(0xFF1E1B4B).withValues(alpha: 0.6), const Color(0xFF312E81).withValues(alpha: 0.4)],
                    onTap: () => _watchAdVideo(context),
                    isLoading: _isClaimingVideo,
                  ),
                  _buildGridItem(
                    title: 'Daily\nBonus',
                    icon: CupertinoIcons.gift_fill,
                    iconColor: const Color(0xFF0ECB81),
                    gradientColors: [const Color(0xFF052E16).withValues(alpha: 0.6), const Color(0xFF14532D).withValues(alpha: 0.4)],
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const DailyBonusScreen()),
                      );
                    },
                    badgeText: '14 DAYS',
                    badgeColor: AppColors.profit,
                  ),
                  _buildGridItem(
                    title: 'Lucky\nSpin',
                    icon: CupertinoIcons.rosette,
                    iconColor: const Color(0xFFF59E0B),
                    gradientColors: [const Color(0xFF451A03).withValues(alpha: 0.6), const Color(0xFF78350F).withValues(alpha: 0.4)],
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const LuckySpinScreen()),
                      );
                    },
                  ),
                  _buildGridItem(
                    title: 'Slot\nMachine',
                    icon: CupertinoIcons.star_circle_fill,
                    iconColor: const Color(0xFFF43F5E),
                    gradientColors: [const Color(0xFF4C0519).withValues(alpha: 0.6), const Color(0xFF881337).withValues(alpha: 0.4)],
                    onTap: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(builder: (context) => const SlotMachineScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceMetric(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: CupertinoColors.white.withValues(alpha: 0.6), size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: CupertinoColors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: CupertinoColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container with gradient background
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? CupertinoActivityIndicator(color: iconColor)
                      : Icon(icon, color: iconColor, size: 22),
                ),
                if (badgeText != null && badgeColor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: badgeColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        color: CupertinoColors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
