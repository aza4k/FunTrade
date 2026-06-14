import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/services/ad_service.dart';
import '../core/utils/formatter.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/history_card.dart';
import '../widgets/liquid_background.dart';
import '../widgets/position_card.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  int _activeSegment = 0;

  void _handleClosePosition(
    BuildContext context,
    PortfolioProvider portfolioProvider,
    AdService adService,
    String positionId,
    double currentPrice,
  ) {
    adService.showInterstitialAd(
      onDismissed: () {
        portfolioProvider.closePosition(positionId, currentPrice);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = Provider.of<PortfolioProvider>(context);
    final market = Provider.of<MarketProvider>(context);
    final adService = Provider.of<AdService>(context);

    double openPnL = 0.0;
    for (var pos in portfolio.openPositions) {
      openPnL += pos.unrealizedPnl;
    }
    final pnlColor = openPnL >= 0 ? AppColors.profit : AppColors.loss;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: LiquidBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ─── Header ───
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Orders',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: pnlColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: pnlColor.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            openPnL >= 0
                                ? CupertinoIcons.arrow_up_right
                                : CupertinoIcons.arrow_down_right,
                            color: pnlColor,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            AppFormatter.formatPnL(openPnL),
                            style: GoogleFonts.plusJakartaSans(
                              color: pnlColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ─── Equity Card ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surface.withValues(alpha: 0.95),
                        AppColors.surface.withValues(alpha: 0.80),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'TOTAL EQUITY',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppFormatter.formatCurrency(portfolio.totalEquity),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        height: 0.5,
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildEquityMetric(
                            'Available Cash',
                            AppFormatter.formatCurrency(portfolio.balance),
                            CupertinoIcons.checkmark_shield,
                          ),
                          _buildEquityMetric(
                            'Unrealized PnL',
                            AppFormatter.formatPnL(openPnL),
                            CupertinoIcons.chart_bar_alt_fill,
                            valueColor: pnlColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Segment Control ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      _buildSegmentPill(0, 'Active Positions'),
                      _buildSegmentPill(1, 'Trade History'),
                    ],
                  ),
                ),
              ),

              // ─── Listings Content ───
              Expanded(
                child: _activeSegment == 0
                    ? _buildPositionsTab(portfolio, market, adService)
                    : _buildHistoryTab(portfolio),
              ),

              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquityMetric(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 12),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentPill(int index, String label) {
    final isActive = _activeSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeSegment = index;
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
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionsTab(PortfolioProvider portfolio, MarketProvider market, AdService adService) {
    final positions = portfolio.openPositions;

    if (positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.briefcase, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No Active Positions',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Open a position from the Trading list.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: positions.length,
      itemBuilder: (context, index) {
        final position = positions[index];
        final currentPrice = market.prices[position.symbol]?.currentPrice ?? position.currentPrice;
        
        return PositionCard(
          position: position,
          onClose: () => _handleClosePosition(
            context,
            portfolio,
            adService,
            position.id,
            currentPrice,
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(PortfolioProvider portfolio) {
    final history = portfolio.tradeHistory;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.clock, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No Closed Trades',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your trade history will be archived here.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final trade = history[index];
        return HistoryCard(trade: trade);
      },
    );
  }
}
