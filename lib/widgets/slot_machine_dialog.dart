import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/colors.dart';
import '../providers/portfolio_provider.dart';
import '../core/utils/formatter.dart';
import '../core/services/ad_service.dart';

class SlotMachineDialog extends StatefulWidget {
  const SlotMachineDialog({super.key});

  @override
  State<SlotMachineDialog> createState() => _SlotMachineDialogState();
}

class _SlotMachineDialogState extends State<SlotMachineDialog> {
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

  void _handleSpinClick(BuildContext context) {
    if (_isSpinning) return;
    
    if (_spinsToday < 5) {
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
    double reward = -15.0; // default loss
    String message = 'No matches! You lost \$15.00 virtual USD. 😭';

    if (_reel1 == _reel2 && _reel2 == _reel3) {
      // 3 matching symbols
      reward = 50.0;
      message = 'JACKPOT! 3 of a kind match! 🎉';
    } else if (_reel1 == _reel2 || _reel2 == _reel3 || _reel1 == _reel3) {
      // 2 matching symbols
      reward = 25.0;
      message = 'Double match! Nice job! 🍻';
    }

    // Apply reward
    Provider.of<PortfolioProvider>(context, listen: false).claimAdReward(reward);

    // Increment count only if it's a free spin
    if (!fromAd) {
      final prefs = await SharedPreferences.getInstance();
      final newCount = _spinsToday + 1;
      await prefs.setInt('slot_machine_count_today', newCount);
      setState(() {
        _spinsToday = newCount;
      });
    }

    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Slot Match Results'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              Text(
                '$_reel1   $_reel2   $_reel3',
                style: const TextStyle(fontSize: 26, letterSpacing: 4),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                reward >= 0 
                    ? 'Awarded: ${AppFormatter.formatCurrency(reward)}'
                    : 'Deducted: ${AppFormatter.formatCurrency(-reward)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: reward >= 0 ? AppColors.profit : AppColors.loss
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) {
                setState(() {
                  _isSpinning = false;
                });
              }
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer1?.cancel();
    _timer2?.cancel();
    _timer3?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingFreeSpins = max(0, 5 - _spinsToday);
    final isAdSpin = _spinsToday >= 5;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0x99000000),
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
                    'Slot Machine 🎰',
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
              const SizedBox(height: 24),

              // Slots display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReelSlot(_reel1),
                    _buildReelSlot(_reel2),
                    _buildReelSlot(_reel3),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Limits Text
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
                          isAdSpin ? 'WATCH AD TO SPIN 🎰' : 'PULL LEVER',
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

  Widget _buildReelSlot(String symbol) {
    return Container(
      width: 68,
      height: 72,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: const TextStyle(fontSize: 34),
      ),
    );
  }
}
