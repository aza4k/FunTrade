import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';
import '../providers/portfolio_provider.dart';
import '../core/utils/formatter.dart';
import '../core/services/ad_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_background.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/banner_ad_widget.dart';

class SlotMachineScreen extends StatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  State<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends State<SlotMachineScreen> {
  final List<String> _symbols = ['💎', '🍒', '🍇', '🍋', '🔔', '🚀'];
  
  String _reel1 = '💎';
  String _reel2 = '💎';
  String _reel3 = '💎';
  
  bool _isSpinning = false;
  Timer? _timer1;
  Timer? _timer2;
  Timer? _timer3;

  int _spinsToday = 0;
  bool _isLoadingSpins = true;

  @override
  void initState() {
    super.initState();
    _loadSpinsCount();
  }

  void _loadSpinsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastSpinDate = prefs.getString('slot_machine_last_date') ?? '';
    int spinsToday = prefs.getInt('slot_machine_count_today') ?? 0;
    
    if (lastSpinDate != today) {
      spinsToday = 0;
      await prefs.setString('slot_machine_last_date', today);
      await prefs.setInt('slot_machine_count_today', 0);
    }
    
    setState(() {
      _spinsToday = spinsToday;
      _isLoadingSpins = false;
    });
  }

  @override
  void dispose() {
    _timer1?.cancel();
    _timer2?.cancel();
    _timer3?.cancel();
    super.dispose();
  }

  void _handleSpinClick(BuildContext context) {
    if (_isSpinning) return;
    
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);

    if (portfolio.balance < 15.0) {
      PremiumDialog.show(
        context,
        title: 'Insufficient Balance',
        message: 'You need at least \$15.00 virtual USD to play the Slot Machine.',
        emoji: '📉',
        confirmText: 'OK',
        isError: true,
      );
      return;
    }

    if (_spinsToday < 3) {
      _executeSpin();
    } else {
      // Need to watch ad to get extra spin
      final adService = Provider.of<AdService>(context, listen: false);
      adService.showRewardedAd(
        onUserEarnedReward: () {
          _executeSpin(fromAd: true);
        },
        onAdDismissed: () {},
        onAdFailedToLoad: () {
          PremiumDialog.show(
            context,
            title: 'Ad Not Ready',
            message: 'The rewarded video is currently buffering. Please try again in a few seconds.',
            emoji: '⏳',
            confirmText: 'OK',
            isError: true,
          );
        },
      );
    }
  }

  void _executeSpin({bool fromAd = false}) {
    setState(() {
      _isSpinning = true;
    });

    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);
    portfolio.claimAdReward(-15.0);

    final random = Random();
    int counter1 = 0;
    int counter2 = 0;
    int counter3 = 0;

    // Reel 1 Timer
    _timer1 = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _reel1 = _symbols[random.nextInt(_symbols.length)];
      });
      counter1++;
      if (counter1 > 15) {
        _timer1?.cancel();
      }
    });

    // Reel 2 Timer
    _timer2 = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _reel2 = _symbols[random.nextInt(_symbols.length)];
      });
      counter2++;
      if (counter2 > 22) {
        _timer2?.cancel();
      }
    });

    // Reel 3 Timer
    _timer3 = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _reel3 = _symbols[random.nextInt(_symbols.length)];
      });
      counter3++;
      if (counter3 > 30) {
        _timer3?.cancel();
        _evaluateResults(fromAd);
      }
    });
  }

  void _evaluateResults(bool fromAd) async {
    double reward = 0; // already charged 15 at start
    String message = 'No matches! Better luck next time. 😭';

    if (_reel1 == _reel2 && _reel2 == _reel3) {
      reward = 65.0; // Net profit 50 (65 - 15)
      message = 'JACKPOT! 3 of a kind match! 🎉';
    } else if (_reel1 == _reel2 || _reel2 == _reel3 || _reel1 == _reel3) {
      reward = 40.0; // Net profit 25 (40 - 15)
      message = 'Double match! Nice job! 🍻';
    }

    // Increment count only if it's a standard spin
    if (!fromAd) {
      final prefs = await SharedPreferences.getInstance();
      final newCount = _spinsToday + 1;
      await prefs.setInt('slot_machine_count_today', newCount);
      setState(() {
        _spinsToday = newCount;
      });
    }

    if (!mounted) return;

    // If it's a loss (reward is 0 here because 15 was already deducted)
    if (reward == 0) {
      if (mounted) {
        PremiumDialog.show(
          context,
          title: 'Slot Match Results 😭',
          message: '[$_reel1  $_reel2  $_reel3]\n\n$message',
          emoji: '🎰',
          confirmText: 'Try Again',
          isError: true,
          onConfirm: () {
            if (mounted) {
              setState(() {
                _isSpinning = false;
              });
            }
          },
        );
      }
      return;
    }

    // If it's a win, offer 2x doubling opportunity
    if (mounted) {
      _showRewardChoiceDialog(reward, message);
    }
  }

  void _showRewardChoiceDialog(double reward, String winMessage) {
    final double doubleReward = reward * 2;

    PremiumDialog.show(
      context,
      title: 'Slot Machine Win! 🎉',
      message: '[$_reel1  $_reel2  $_reel3]\n\n$winMessage\nWon: +${AppFormatter.formatCurrency(reward)} virtual USD!\n\nWould you like to double it to ${AppFormatter.formatCurrency(doubleReward)} by watching a quick video ad?',
      emoji: '🎰',
      confirmText: 'Claim 2X 🎥',
      buttonIcon: CupertinoIcons.play_arrow_solid,
      cancelText: 'Claim Normal',
      onConfirm: () {
        _handleDoubleReward(reward);
      },
      onCancel: () {
        Provider.of<PortfolioProvider>(context, listen: false).claimAdReward(reward);
        if (mounted) {
          setState(() {
            _isSpinning = false;
          });
        }
      },
    );
  }

  void _handleDoubleReward(double baseReward) {
    final adService = Provider.of<AdService>(context, listen: false);
    adService.showRewardedAd(
      onUserEarnedReward: () {
        Provider.of<PortfolioProvider>(context, listen: false).claimAdReward(baseReward * 2);
        
        if (mounted) {
          setState(() {
            _isSpinning = false;
          });
          
          PremiumDialog.show(
            context,
            title: 'Double Reward! 🎉',
            message: 'You successfully claimed ${AppFormatter.formatCurrency(baseReward * 2)} virtual USD!',
            emoji: '💰',
            confirmText: 'Awesome',
          );
        }
      },
      onAdDismissed: () {
        if (mounted) {
          Provider.of<PortfolioProvider>(context, listen: false).claimAdReward(baseReward);
          setState(() {
            _isSpinning = false;
          });
          PremiumDialog.show(
            context,
            title: 'Standard Claimed',
            message: 'Ad was not finished. Standard reward of ${AppFormatter.formatCurrency(baseReward)} claimed.',
            emoji: 'ℹ️',
            confirmText: 'OK',
          );
        }
      },
      onAdFailedToLoad: () {
        if (mounted) {
          Provider.of<PortfolioProvider>(context, listen: false).claimAdReward(baseReward);
          setState(() {
            _isSpinning = false;
          });
          PremiumDialog.show(
            context,
            title: 'Claimed Standard',
            message: 'Failed to load rewarded ad. Standard reward of ${AppFormatter.formatCurrency(baseReward)} has been claimed.',
            emoji: 'ℹ️',
            confirmText: 'OK',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingFreeSpins = max(0, 3 - _spinsToday);
    final isAdSpin = _spinsToday >= 3;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.75),
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.4), width: 0.5)),
        middle: Text(
          'Slot Machine',
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Info Panel
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            '🎰',
                            style: TextStyle(fontSize: 36),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pull to Win Huge Jackpots!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Matches pay virtual currency. 3 matching = \$50, 2 matching = \$25. No matches deducts -\$15.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Slot Machine Neon Cabinet
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow Cabinet Base
                          Container(
                            width: 290,
                            height: 180,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isAdSpin ? const Color(0xFFFF9F0A) : AppColors.primary,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isAdSpin ? const Color(0xFFFF9F0A) : AppColors.primary).withValues(alpha: 0.2),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                )
                              ],
                            ),
                          ),
                          
                          // Reels container
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildReelSlot(_reel1),
                                _buildReelSlot(_reel2),
                                _buildReelSlot(_reel3),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),

              // Bottom Interactive Panel
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  border: Border(
                    top: BorderSide(color: AppColors.border.withValues(alpha: 0.3), width: 0.5),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Remaining Counter
                      _isLoadingSpins
                          ? const CupertinoActivityIndicator()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isAdSpin ? CupertinoIcons.play_circle : CupertinoIcons.gift,
                                  size: 14,
                                  color: isAdSpin ? const Color(0xFFFF9F0A) : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isAdSpin
                                      ? 'Daily limit reached. Watch ad for more chances!'
                                      : 'Daily chances remaining: $remainingFreeSpins',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: isAdSpin ? const Color(0xFFFF9F0A) : AppColors.textSecondary,
                                    fontWeight: isAdSpin ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),

                      // Spin Button
                      GestureDetector(
                        onTap: _isSpinning || _isLoadingSpins ? null : () => _handleSpinClick(context),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: _isSpinning
                                ? null
                                : (isAdSpin
                                    ? const LinearGradient(colors: [Color(0xFFFF9F0A), Color(0xFFD97706)])
                                    : const LinearGradient(colors: [Color(0xFF0E76FD), Color(0xFF1D4ED8)])),
                            color: _isSpinning ? AppColors.border.withValues(alpha: 0.4) : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isSpinning
                                ? null
                                : [
                                    BoxShadow(
                                      color: (isAdSpin ? const Color(0xFFFF9F0A) : AppColors.primary).withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: _isSpinning
                              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                              : Text(
                                  isAdSpin ? 'WATCH AD TO PLAY (\$15) 🎰' : 'SPIN FOR \$15',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

  Widget _buildReelSlot(String symbol) {
    return Container(
      width: 72,
      height: 90,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: const TextStyle(fontSize: 36),
      ),
    );
  }
}
