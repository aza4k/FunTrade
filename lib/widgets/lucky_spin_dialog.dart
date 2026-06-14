import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';
import '../providers/portfolio_provider.dart';
import '../core/utils/formatter.dart';
import '../core/services/ad_service.dart';

class LuckySpinDialog extends StatefulWidget {
  const LuckySpinDialog({super.key});

  @override
  State<LuckySpinDialog> createState() => _LuckySpinDialogState();
}

class _LuckySpinDialogState extends State<LuckySpinDialog> with SingleTickerProviderStateMixin {
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
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Ad Not Ready'),
              content: const Text('The rewarded video is currently buffering. Please try again in a few seconds.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _executeSpin({bool fromAd = false}) {
    setState(() {
      _isSpinning = true;
    });

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
        
        // Claim reward
        Provider.of<PortfolioProvider>(context, listen: false).claimAdReward(reward);

        // Increment count only if it's a free spin
        if (!fromAd) {
          final prefs = await SharedPreferences.getInstance();
          final newCount = _spinsToday + 1;
          await prefs.setInt('lucky_spin_count_today', newCount);
          setState(() {
            _spinsToday = newCount;
          });
        }

        if (!mounted) return;

        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(reward > 0 ? 'Congratulations! 🎉' : 'Oops! 😭'),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(reward > 0 
                  ? 'You won ${AppFormatter.formatCurrency(reward)} virtual USD!' 
                  : 'You got \$0. Try again next time!'),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Claim'),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (mounted) {
                    setState(() {
                      _isSpinning = false;
                    });
                  }
                },
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final remainingFreeSpins = max(0, 3 - _spinsToday);
    final isAdSpin = _spinsToday >= 3;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x99000000), // Dim background
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lucky Spin ✨',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textSecondary),
                    onPressed: () {
                      if (!_isSpinning) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Wheel visual
              Stack(
                alignment: Alignment.center,
                children: [
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
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: _WheelPainter(_rewards),
                      ),
                    ),
                  ),
                  // Pointer indicator at the top
                  Positioned(
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.loss,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  // Center peg
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x33000000), blurRadius: 4, spreadRadius: 1)
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Spacing / Limits Text
              _isLoadingSpins
                  ? const CupertinoActivityIndicator()
                  : Text(
                      isAdSpin
                          ? 'Free spins exhausted. Watch ad to spin!'
                          : 'Free spins remaining: $remainingFreeSpins today',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAdSpin ? AppColors.loss : AppColors.textSecondary,
                        fontWeight: isAdSpin ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
              const SizedBox(height: 16),

              // Spin Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  color: isAdSpin ? const Color(0xFFFF9F0A) : AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  onPressed: _isSpinning || _isLoadingSpins ? null : () => _handleSpinClick(context),
                  child: _isSpinning
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : Text(
                          isAdSpin ? 'WATCH AD TO SPIN 🎡' : 'SPIN NOW',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
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

  final List<Color> colors = [
    const Color(0xFFFF9F0A),
    const Color(0xFF30D158),
    const Color(0xFF0A84FF),
    const Color(0xFFBF5AF2),
    const Color(0xFFFF453A),
    const Color(0xFF64D2FF),
    const Color(0xFFFFD60A),
    const Color(0xFFFF375F),
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
      
      // Draw sector arc
      final double startAngle = i * sweepAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw label text inside segment
      canvas.save();
      final double textAngle = startAngle + (sweepAngle / 2);
      canvas.translate(radius, radius);
      canvas.rotate(textAngle);
      
      final textSpan = TextSpan(
        text: '\$${rewards[i].toInt()}',
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      
      // Paint text along the radius offset
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
