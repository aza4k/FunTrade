import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/config.dart';
import '../core/utils/formatter.dart';
import '../models/candlestick.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../core/services/crypto_api_service.dart';
import '../widgets/crypto_logo.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/liquid_background.dart';
import '../widgets/banner_ad_widget.dart';
import '../core/services/ad_service.dart';

class CoinDetailScreen extends StatefulWidget {
  final String symbol;

  const CoinDetailScreen({
    super.key,
    required this.symbol,
  });

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  String _activeTimeframe = '5m'; // Binance kline intervals: 1m, 5m, 15m, 1h, 4h, 1d
  List<Candlestick> _candles = [];
  bool _isLoadingCandles = false;

  final Map<String, String> _timeframeLabels = {
    '1m': '1 min.',
    '5m': '5 min.',
    '15m': '15 min.',
    '1h': '1 h.',
    '4h': '4 h.',
    '1d': '1 d.',
  };

  @override
  void initState() {
    super.initState();
    _fetchCandleData();
  }

  Future<void> _fetchCandleData() async {
    setState(() {
      _isLoadingCandles = true;
    });

    try {
      final candles = await CryptoApiService.fetchCandles(widget.symbol, _activeTimeframe);
      if (mounted) {
        setState(() {
          _candles = candles;
          _isLoadingCandles = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingCandles = false;
        });
      }
    }
  }

  void _showOrderSheet(BuildContext context, bool isLong, double spotPrice) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _OrderBottomSheet(
        symbol: widget.symbol,
        isLong: isLong,
        spotPrice: spotPrice,
        parentContext: context,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final market = Provider.of<MarketProvider>(context);
    final asset = market.prices[widget.symbol];
    if (asset == null) return const SizedBox.shrink();

    final name = AppConfig.cryptoNames[widget.symbol] ?? widget.symbol;
    final isUp = asset.change24h >= 0;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.75),
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.4), width: 0.5)),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CryptoLogo(symbol: widget.symbol, size: 24),
            const SizedBox(width: 8),
            Text(
              '$name ${widget.symbol}',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      child: LiquidBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large Spot Price block
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormatter.formatCurrency(asset.currentPrice),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (isUp ? AppColors.profit : AppColors.loss).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${AppFormatter.formatPercentage(asset.change24h)} (1d)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isUp ? AppColors.profit : AppColors.loss,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Candlestick Chart Area
              Expanded(
                child: Center(
                  child: _isLoadingCandles
                      ? const CupertinoActivityIndicator(radius: 14, color: AppColors.primary)
                      : CandlestickChart(
                          candles: _candles,
                          currentPrice: asset.currentPrice,
                        ),
                ),
              ),

              // Timeframe selectors
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _timeframeLabels.entries.map((entry) {
                      final isSelected = _activeTimeframe == entry.key;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_activeTimeframe != entry.key) {
                              setState(() {
                                _activeTimeframe = entry.key;
                              });
                              _fetchCandleData();
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : CupertinoColors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              entry.value,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Buy / Sell bottoms buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    // Sell (Red) button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showOrderSheet(context, false, asset.currentPrice),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.loss.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.arrow_down_right, color: CupertinoColors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Short ${AppFormatter.formatCurrency(asset.currentPrice)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Buy (Green) button
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showOrderSheet(context, true, asset.currentPrice),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0ECB81), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.profit.withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(CupertinoIcons.arrow_up_right, color: CupertinoColors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Long ${AppFormatter.formatCurrency(asset.currentPrice)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  color: CupertinoColors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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

class _OrderBottomSheet extends StatefulWidget {
  final String symbol;
  final bool isLong;
  final double spotPrice;
  final BuildContext parentContext;

  const _OrderBottomSheet({
    required this.symbol,
    required this.isLong,
    required this.spotPrice,
    required this.parentContext,
  });

  @override
  State<_OrderBottomSheet> createState() => _OrderBottomSheetState();
}

class _OrderBottomSheetState extends State<_OrderBottomSheet> {
  int _leverage = 10;
  double _margin = 100.0;
  double? _takeProfit;
  double? _stopLoss;
  bool _isClaimingVideo = false;
  late TextEditingController _marginController;
  late TextEditingController _tpController;
  late TextEditingController _slController;

  @override
  void initState() {
    super.initState();
    _marginController = TextEditingController(text: '100');
    _tpController = TextEditingController();
    _slController = TextEditingController();
  }

  @override
  void dispose() {
    _marginController.dispose();
    _tpController.dispose();
    _slController.dispose();
    super.dispose();
  }

  void _watchAdVideo() {
    if (_isClaimingVideo) return;
    
    final adService = Provider.of<AdService>(context, listen: false);
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);

    setState(() {
      _isClaimingVideo = true;
    });

    adService.showRewardedAd(
      onUserEarnedReward: () {
        portfolio.claimAdReward(200.00);
      },
      onAdDismissed: () {
        if (mounted) setState(() => _isClaimingVideo = false);
      },
      onAdFailedToLoad: () {
        if (mounted) setState(() => _isClaimingVideo = false);
      },
    );
  }

  double get _liquidationPrice {
    if (widget.isLong) {
      return widget.spotPrice * (1.0 - 0.9 / _leverage);
    } else {
      return widget.spotPrice * (1.0 + 0.9 / _leverage);
    }
  }

  void _submitOrder() {
    final portfolio = Provider.of<PortfolioProvider>(context, listen: false);

    if (_margin > portfolio.balance) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Insufficient Funds'),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Your available virtual USD balance is insufficient to cover this margin amount.'),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            )
          ],
        ),
      );
      return;
    }

    final success = portfolio.openPosition(
      symbol: widget.symbol,
      isLong: widget.isLong,
      margin: _margin,
      leverage: _leverage,
      currentPrice: widget.spotPrice,
      takeProfit: _takeProfit,
      stopLoss: _stopLoss,
    );

    if (success) {
      Navigator.pop(context); // Close bottom sheet
      showCupertinoDialog(
        context: widget.parentContext,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Position Opened!'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Successfully opened a ${_leverage}x ${widget.isLong ? "LONG" : "SHORT"} position on ${widget.symbol}.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = Provider.of<PortfolioProvider>(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Header indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Open ${widget.isLong ? "LONG" : "SHORT"} ${widget.symbol}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.isLong ? AppColors.profit : AppColors.loss,
                ),
              ),
              Text(
                'Available: ${AppFormatter.formatCurrency(portfolio.balance)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Leverage Selector
          const Text('Leverage', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: AppConfig.leverageLevels.map((lvl) {
              final isSel = _leverage == lvl;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _leverage = lvl;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${lvl}x',
                      style: TextStyle(
                        color: isSel ? CupertinoColors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Watch Ad Button
          GestureDetector(
            onTap: _watchAdVideo,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.play_circle_fill, color: Color(0xFF8B5CF6), size: 16),
                  const SizedBox(width: 8),
                  _isClaimingVideo 
                    ? const CupertinoActivityIndicator(radius: 8)
                    : Text(
                        'Watch video to get +\$200.00',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF8B5CF6),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Margin Input
          const Text('Margin (USD)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: _marginController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Text('\$', style: TextStyle(color: AppColors.textSecondary)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              setState(() {
                _margin = parsed;
              });
            },
          ),
          const SizedBox(height: 20),

          // TP/SL Inputs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Take Profit', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _tpController,
                      placeholder: 'Target Price',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _takeProfit = double.tryParse(val);
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stop Loss', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _slController,
                      placeholder: 'Exit Price',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textPrimary),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _stopLoss = double.tryParse(val);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Estimated Liquidation price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Est. Liquidation Price', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                AppFormatter.formatCurrency(_liquidationPrice),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.loss,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Open Position button
          CupertinoButton(
            color: widget.isLong ? AppColors.profit : AppColors.loss,
            borderRadius: BorderRadius.circular(14),
            onPressed: _submitOrder,
            child: Text(
              'Confirm ${widget.isLong ? "Buy/Long" : "Sell/Short"}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: CupertinoColors.white),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
