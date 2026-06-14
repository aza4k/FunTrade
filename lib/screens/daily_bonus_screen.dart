import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';
import '../core/utils/formatter.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_background.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/banner_ad_widget.dart';

class DailyBonusScreen extends StatefulWidget {
  const DailyBonusScreen({super.key});

  @override
  State<DailyBonusScreen> createState() => _DailyBonusScreenState();
}

class _DailyBonusScreenState extends State<DailyBonusScreen> {
  int _streak = 0;
  String _lastClaimDate = '';
  bool _canClaim = false;
  bool _isClaiming = false;

  final List<double> _rewards = const [
    100.0,  // Day 1
    150.0,  // Day 2
    200.0,  // Day 3
    250.0,  // Day 4
    300.0,  // Day 5
    400.0,  // Day 6
    500.0,  // Day 7
    600.0,  // Day 8
    700.0,  // Day 9
    800.0,  // Day 10
    900.0,  // Day 11
    1000.0, // Day 12
    1200.0, // Day 13
    1500.0, // Day 14
  ];

  @override
  void initState() {
    super.initState();
    _loadClaimStatus();
  }

  void _loadClaimStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    setState(() {
      _streak = prefs.getInt('daily_bonus_streak_v2') ?? 0;
      _lastClaimDate = prefs.getString('daily_bonus_last_claim_date_v2') ?? '';
      _canClaim = _lastClaimDate != today;
    });
  }

  void _claimReward() async {
    if (!_canClaim || _isClaiming) return;

    setState(() {
      _isClaiming = true;
    });

    try {
      final portfolio = Provider.of<PortfolioProvider>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // Verify the claim status directly from SharedPreferences to avoid state synchronization lag
      final currentStreak = prefs.getInt('daily_bonus_streak_v2') ?? 0;
      final lastClaim = prefs.getString('daily_bonus_last_claim_date_v2') ?? '';

      if (lastClaim == today) {
        // Already claimed today! Update local state and abort.
        setState(() {
          _streak = currentStreak;
          _lastClaimDate = lastClaim;
          _canClaim = false;
        });
        return;
      }

      final rewardIndex = currentStreak % 14;
      final rewardAmount = _rewards[rewardIndex];

      portfolio.claimAdReward(rewardAmount);

      final newStreak = currentStreak + 1;
      await prefs.setInt('daily_bonus_streak_v2', newStreak);
      await prefs.setString('daily_bonus_last_claim_date_v2', today);

      setState(() {
        _streak = newStreak;
        _lastClaimDate = today;
        _canClaim = false;
      });

      _showRewardSuccessDialog(rewardAmount, rewardIndex + 1);
    } catch (e) {
      // Handle potential errors gracefully
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
        });
      }
    }
  }

  void _showRewardSuccessDialog(double amount, int day) {
    PremiumDialog.show(
      context,
      title: 'Day $day Claimed! 🎉',
      message: 'You successfully claimed Day $day bonus of +${AppFormatter.formatCurrency(amount)} virtual USD!',
      emoji: '🎁',
      confirmText: 'Awesome',
    );
  }

  @override
  Widget build(BuildContext context) {
    // _streak = total days claimed so far
    final rawCycleCount = _streak % 14;
    // If we've completed a cycle (streak is multiple of 14) and already claimed today,
    // show the completed cycle where all 14 days are claimed.
    final claimedCount = (rawCycleCount == 0 && _streak > 0 && !_canClaim) ? 14 : rawCycleCount;
    // nextDayIndex = the index of the next day to claim
    final nextDayIndex = rawCycleCount;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.75),
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.4), width: 0.5)),
        middle: Text(
          'Daily Rewards',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      child: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    // ─── Info Card ───
                    GlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          const Text(
                            '🎁',
                            style: TextStyle(fontSize: 36),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '14-Day Login Calendar',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Claim virtual USD daily to boost your trading rank! Missing a day does not reset your streak.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.flame, color: AppColors.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '$_streak Day Streak',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── 14 Days Grid ───
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        // Days before nextDayIndex are fully claimed in past days
                        final isClaimed = index < claimedCount;
                        // The next day is only "current" (highlighted) if we CAN claim today
                        final isCurrent = index == nextDayIndex && _canClaim;
                        // The day we just claimed today: show as claimed only if it's the last one we claimed
                        final isTodayClaimed = !_canClaim && claimedCount > 0 && index == (claimedCount - 1);
                        // Everything at nextDayIndex or above is locked (unless it's claimable right now)
                        final isLocked = index >= claimedCount && !isCurrent;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: isCurrent
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary.withValues(alpha: 0.15),
                                      AppColors.primary.withValues(alpha: 0.05),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.surface.withValues(alpha: 0.9),
                                      AppColors.surface.withValues(alpha: 0.7),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrent
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : AppColors.border.withValues(alpha: 0.3),
                              width: isCurrent ? 1.5 : 0.8,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      spreadRadius: -2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Opacity(
                            opacity: isLocked && !isTodayClaimed ? 0.45 : 1.0,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Day ${index + 1}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                      color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                  isClaimed || isTodayClaimed
                                      ? Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: AppColors.profit.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.checkmark,
                                            color: AppColors.profit,
                                            size: 15,
                                          ),
                                        )
                                      : const Text(
                                          '💰',
                                          style: TextStyle(fontSize: 22),
                                        ),
                                  Text(
                                    '\$${_rewards[index].toInt()}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isClaimed || isTodayClaimed
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ─── Bottom Claim Button ───
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.75),
                  border: Border(
                    top: BorderSide(color: AppColors.border.withValues(alpha: 0.3), width: 0.5),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: GestureDetector(
                    onTap: (_canClaim && !_isClaiming) ? _claimReward : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: (_canClaim && !_isClaiming)
                            ? const LinearGradient(
                                colors: [Color(0xFF0E76FD), Color(0xFF1D4ED8)],
                              )
                            : null,
                        color: (_canClaim && !_isClaiming) ? null : AppColors.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: (_canClaim && !_isClaiming)
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: -2,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: _isClaiming
                          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                          : Text(
                              _canClaim
                                  ? 'Claim Today\'s Bonus (+${AppFormatter.formatCurrency(_rewards[nextDayIndex])})'
                                  : 'Already Claimed Today ✓',
                              style: GoogleFonts.plusJakartaSans(
                                color: _canClaim ? CupertinoColors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
