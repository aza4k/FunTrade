import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/portfolio_provider.dart';
import '../core/utils/formatter.dart';

class ShuttleGameDialog extends StatefulWidget {
  const ShuttleGameDialog({super.key});

  @override
  State<ShuttleGameDialog> createState() => _ShuttleGameDialogState();
}

class _ShuttleGameDialogState extends State<ShuttleGameDialog> {
  double _multiplier = 1.00;
  bool _isPlaying = false;
  bool _isCrashed = false;
  bool _isCashedOut = false;
  double _crashThreshold = 1.00;
  Timer? _timer;
  
  // Game states: 'idle', 'flying', 'crashed', 'cashed_out'
  String _gameState = 'idle';

  void _startGame() {
    if (_isPlaying) return;

    final random = Random();
    // Weighted crash threshold: mostly between 1.05 and 3.5, rarely up to 10.0
    final double randVal = random.nextDouble();
    if (randVal < 0.1) {
      _crashThreshold = 1.0 + (random.nextDouble() * 0.1); // early crash: 1.0 - 1.1x
    } else if (randVal < 0.8) {
      _crashThreshold = 1.1 + (random.nextDouble() * 2.4); // typical crash: 1.1 - 3.5x
    } else {
      _crashThreshold = 3.5 + (random.nextDouble() * 6.5); // high crash: 3.5 - 10.0x
    }

    setState(() {
      _isPlaying = true;
      _isCrashed = false;
      _isCashedOut = false;
      _multiplier = 1.00;
      _gameState = 'flying';
    });

    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) return;

      setState(() {
        // Increment multiplier faster as it grows
        if (_multiplier < 2.0) {
          _multiplier += 0.02;
        } else if (_multiplier < 5.0) {
          _multiplier += 0.05;
        } else {
          _multiplier += 0.15;
        }

        // Check if crash happened
        if (_multiplier >= _crashThreshold) {
          _timer?.cancel();
          _isPlaying = false;
          _isCrashed = true;
          _gameState = 'crashed';
        }
      });
    });
  }

  void _cashOut() {
    if (!_isPlaying || _isCrashed || _isCashedOut) return;

    _timer?.cancel();
    
    final finalReward = 100.0 * _multiplier; // Base play of $100 * multiplier
    
    // Claim reward
    Provider.of<PortfolioProvider>(context, listen: false).claimAdReward(finalReward);

    setState(() {
      _isPlaying = false;
      _isCashedOut = true;
      _gameState = 'cashed_out';
    });

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Cashed Out! 🚀'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'You successfully exited at ${_multiplier.toStringAsFixed(2)}x and earned ${AppFormatter.formatCurrency(finalReward)} virtual USD!',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Awesome'),
            onPressed: () {
              Navigator.pop(ctx);
            },
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = AppColors.textSecondary;
    String statusText = 'Ready to launch';
    
    if (_gameState == 'flying') {
      statusColor = AppColors.primary;
      statusText = 'Shuttle is climbing...';
    } else if (_gameState == 'crashed') {
      statusColor = AppColors.loss;
      statusText = 'CRASHED at ${_crashThreshold.toStringAsFixed(2)}x!';
    } else if (_gameState == 'cashed_out') {
      statusColor = AppColors.profit;
      statusText = 'Cashed out successfully!';
    }

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
                    'Shuttle Game 🚀',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textSecondary),
                    onPressed: () {
                      if (!_isPlaying) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Flight Canvas display
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid pattern simulation
                    Positioned.fill(
                      child: GridPaper(
                        color: AppColors.border.withValues(alpha: 0.2),
                        interval: 50.0,
                        divisions: 1,
                        subdivisions: 1,
                      ),
                    ),
                    
                    // Multiplier Text
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_multiplier.toStringAsFixed(2)}x',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: _isCrashed ? AppColors.loss : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),

                    // Shuttle Position representation
                    if (_gameState == 'flying')
                      Positioned(
                        bottom: 20 + (_multiplier * 8).clamp(0, 100),
                        left: 20 + (_multiplier * 12).clamp(0, 220),
                        child: const Text(
                          '🚀',
                          style: TextStyle(fontSize: 28),
                        ),
                      )
                    else if (_gameState == 'crashed')
                      Positioned(
                        bottom: 20 + (_crashThreshold * 8).clamp(0, 100),
                        left: 20 + (_crashThreshold * 12).clamp(0, 220),
                        child: const Text(
                          '💥',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Game controls button
              SizedBox(
                width: double.infinity,
                child: _isPlaying
                    ? CupertinoButton(
                        color: AppColors.profit,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: _cashOut,
                        child: Text(
                          'CASH OUT (+${AppFormatter.formatCurrency(100 * _multiplier)})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      )
                    : CupertinoButton(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        onPressed: _startGame,
                        child: const Text(
                          'LAUNCH SHUTTLE',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
