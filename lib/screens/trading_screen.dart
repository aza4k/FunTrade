import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/config.dart';
import '../core/utils/formatter.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_background.dart';
import '../widgets/crypto_logo.dart';
import '../widgets/sparkline_chart.dart';
import '../widgets/position_card.dart';
import '../widgets/history_card.dart';
import 'coin_detail_screen.dart';
import '../widgets/banner_ad_widget.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  int _activeTab = 0; // 0: Market, 1: Trades, 2: Orders
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: LiquidBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Title Header ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'Trading',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // ─── Search Bar ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: CupertinoSearchTextField(
                    placeholder: 'Search tokens...',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    placeholderStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                    backgroundColor: CupertinoColors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
              ),

              // ─── Pill-Style Segmented Tabs ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                    children: [
                      _buildPillTab(0, 'Market'),
                      _buildPillTab(1, 'Trades'),
                      _buildPillTab(2, 'History'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // ─── Dynamic Content ───
              Expanded(
                child: _buildTabContent(),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillTab(int index, String label) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.15) : CupertinoColors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 0:
        return _buildMarketList();
      case 1:
        return _buildTradesList();
      case 2:
        return _buildOrdersList();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMarketList() {
    return Consumer<MarketProvider>(
      builder: (context, market, child) {
        // Filter assets by search query
        final filteredList = market.pricesList.where((asset) {
          final fullName = AppConfig.cryptoNames[asset.symbol] ?? '';
          return asset.symbol.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              fullName.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.search, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'No tokens found',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: filteredList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final asset = filteredList[index];
            final name = AppConfig.cryptoNames[asset.symbol] ?? asset.symbol;
            final isUp = asset.change24h >= 0;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => CoinDetailScreen(symbol: asset.symbol),
                  ),
                );
              },
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    CryptoLogo(symbol: asset.symbol, size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${asset.symbol}/USDT',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: SparklineChart(history: asset.priceHistory),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppFormatter.formatCurrency(asset.currentPrice),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isUp ? AppColors.profit : AppColors.loss).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppFormatter.formatPercentage(asset.change24h),
                              style: GoogleFonts.plusJakartaSans(
                                color: isUp ? AppColors.profit : AppColors.loss,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTradesList() {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        final openPos = portfolio.openPositions;

        if (openPos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.chart_bar, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'No active positions',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: openPos.length,
          itemBuilder: (context, index) {
            final pos = openPos[index];
            return PositionCard(
              position: pos,
              onClose: () {
                portfolio.closePosition(pos.id, pos.currentPrice);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersList() {
    return Consumer<PortfolioProvider>(
      builder: (context, portfolio, child) {
        final history = portfolio.tradeHistory;

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.clock, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'No closed trades',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            return HistoryCard(trade: item);
          },
        );
      },
    );
  }
}
