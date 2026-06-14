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

class LuckySpinScreen extends StatefulWidget {
  const LuckySpinScreen({super.key});

  @override
  State<LuckySpinScreen> createState() => _LuckySpinScreenState();
}

class _LuckySpinScreenState extends State<LuckySpinScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSpinning = false;
  double _rotationAngle = 0;
  final List<double> _rewards = [0, 5, 10, 15, 25, 40, 55, 75];
  int _selectedRewardIndex = 0;

  int _spinsToday = 0;
  bool _isLoadingSpins = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _loadSpinsCount();
  }

  void _loadSpinsCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastSpinDate = prefs.getString('lucky_spin_last_date') ?? '';
    int spinsToday = prefs.getInt('lucky_spin_count_today') ?? 0;
    
    if (lastSpinDate != today) {
      spinsToday = 0;
      await prefs.setString('lucky_spin_last_date', today);
      await prefs.setInt('lucky_spin_count_today', 0);
    }
    
    setState(() {
      _spinsToday = spinsToday;
      _isLoadingSpins = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSpinClick(BuildContext context) {
    if (_isSpinning) return;
    
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);
    
    if (portfolio.balance < 15.0) {
      PremiumDialog.show(
        context,
        title: 'Insufficient Balance',
        message: 'You need at least \$15.00 virtual USD to spin the wheel.',
        emoji: '📉',
        confirmText: 'OK',
        isError: true,
      );
      return;
    }

    _executeSpin();
  }

  void _executeSpin({bool fromAd = false}) {
    setState(() {
      _isSpinning = true;
    });

    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);
    portfolio.claimAdReward(-15.0);

    final random = Random();
    _selectedRewardIndex = random.nextInt(_rewards.length);

    final targetDegree = (360 * 6) + (360 - (_selectedRewardIndex * 45) - 22.5);
    final double targetRadian = targetDegree * (pi / 180);

    _animation = Tween<double>(
      begin: _rotationAngle % (2 * pi),
      end: targetRadian,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward(from: 0).then((_) async {
      if (mounted) {
        _rotationAngle = targetRadian;
        final reward = _rewards[_selectedRewardIndex];

        // Increment count only if it's a free spin
        if (!fromAd) {
          final prefs = await SharedPreferences.getInstance();
          final newCount = _spinsToday + 1;
          await prefs.setInt('lucky_spin_count_today', newCount);
          setState(() {
            _spinsToday = newCount;
          });
        }

        _showRewardChoiceDialog(reward);
      }
    });
  }

  void _showRewardChoiceDialog(double reward) {
    if (reward <= 0) {
      PremiumDialog.show(
        context,
        title: 'Oops! 😭',
        message: 'You got \$0 virtual USD. Try again next time!',
        emoji: '😢',
        confirmText: 'OK',
        onConfirm: () {
          if (mounted) {
            setState(() {
              _isSpinning = false;
            });
          }
        },
      );
      return;
    }

    final double doubleReward = reward * 2;

    PremiumDialog.show(
      context,
      title: 'Congratulations! 🎉',
      message: 'You successfully spun the wheel and won +${AppFormatter.formatCurrency(reward)} virtual USD!\n\nWould you like to double it to ${AppFormatter.formatCurrency(doubleReward)} by watching a quick video ad?',
      emoji: '🎡',
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
          'Lucky Spin Wheel',
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
                            '✨',
                            style: TextStyle(fontSize: 36),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Spin to Win Bonuses!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Get free daily virtual cash to invest. Complete video ads to spin unlimited times!',
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
                    const SizedBox(height: 32),

                    // Spin Wheel Container
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glow Background
                          Container(
                            width: 270,
                            height: 270,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isAdSpin ? const Color(0xFFFF9F0A) : AppColors.primary).withValues(alpha: 0.15),
                                  blurRadius: 36,
                                  spreadRadius: 8,
                                )
                              ],
                            ),
                          ),
                          // Outer boundary border
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isAdSpin ? const Color(0xFFFF9F0A).withValues(alpha: 0.4) : AppColors.border,
                                width: 6,
                              ),
                            ),
                          ),
                          // Animated Wheel
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _animation.value,
                                child: child,
                              );
                            },
                            child: SizedBox(
                              width: 240,
                              height: 240,
                              child: CustomPaint(
                                painter: _WheelPainter(_rewards),
                              ),
                            ),
                          ),
                          // Pointer indicator on the right side
                          Positioned(
                            right: 0,
                            child: Transform.rotate(
                              angle: pi,
                              child: const Icon(
                                CupertinoIcons.play_fill,
                                color: AppColors.loss,
                                size: 30,
                                shadows: [
                                  Shadow(
                                    color: Color(0x40000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                            ),
                          ),
                          // Center peg decoration
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x40000000),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isAdSpin ? const Color(0xFFFF9F0A) : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
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
                      // Cost indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            CupertinoIcons.money_dollar_circle,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Each spin costs \$15.00 virtual USD',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
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
                                : const LinearGradient(colors: [Color(0xFF0E76FD), Color(0xFF1D4ED8)]),
                            color: _isSpinning ? AppColors.border.withValues(alpha: 0.4) : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isSpinning
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: _isSpinning
                              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                              : Text(
                                  'SPIN FOR \$15 🎡',
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
}

class _WheelPainter extends CustomPainter {
  final List<double> rewards;
  _WheelPainter(this.rewards);

  // Modern vibrant fintech color sectors
  final List<Color> colors = [
    const Color(0xFF1E293B), // Dark slate
    const Color(0xFF0E76FD), // Cobalt Blue
    const Color(0xFF0ECB81), // Emerald Green
    const Color(0xFF8B5CF6), // Royal Purple
    const Color(0xFFF59E0B), // Honey Amber
    const Color(0xFFF43F5E), // Rose Crimson
    const Color(0xFF06B6D4), // Cyan Teal
    const Color(0xFFEC4899), // Pink Orchid
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final center = Offset(radius, radius);
    final paint = Paint()..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final double sweepAngle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      paint.color = colors[i % colors.length];
      
      final double startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Label text
      canvas.save();
      final double textAngle = startAngle + (sweepAngle / 2);
      canvas.translate(radius, radius);
      canvas.rotate(textAngle);
      
      final textSpan = TextSpan(
        text: '\$${rewards[i].toInt()}',
        style: GoogleFonts.plusJakartaSans(
          color: CupertinoColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      
      textPainter.paint(
        canvas,
        Offset(radius * 0.45, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
