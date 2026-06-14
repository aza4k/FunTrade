import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../core/constants/colors.dart';
import '../core/utils/formatter.dart';
import '../models/trade_history.dart';
import '../widgets/glass_card.dart';

class HistoryCard extends StatelessWidget {
  final TradeHistory trade;

  const HistoryCard({
    super.key,
    required this.trade,
  });

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.finalPnl >= 0;
    final pnlColor = trade.isLiquidated
        ? AppColors.loss
        : (isProfit ? AppColors.profit : AppColors.loss);

    final dateStr = DateFormat('MM/dd HH:mm').format(trade.timestamp);
    final pnlPercent = (trade.finalPnl / trade.margin) * 100;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderCol: trade.isLiquidated ? AppColors.loss.withValues(alpha: 0.35) : null,
      child: Column(
        children: [
          // Top Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    trade.symbol,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (trade.isLong ? AppColors.profit : AppColors.loss).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: (trade.isLong ? AppColors.profit : AppColors.loss).withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      trade.isLong ? 'LONG' : 'SHORT',
                      style: TextStyle(
                        color: trade.isLong ? AppColors.profit : AppColors.loss,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (trade.isLiquidated)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.loss.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIQUIDATED',
                        style: TextStyle(
                          color: AppColors.loss,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatter.formatPnL(trade.finalPnl),
                    style: TextStyle(
                      color: pnlColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatter.formatPercentage(pnlPercent),
                    style: TextStyle(
                      color: pnlColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(height: 0.8, color: AppColors.border),
          const SizedBox(height: 12),

          // Bottom Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoCol('Margin (${trade.leverage}x)', AppFormatter.formatCurrency(trade.margin)),
              _buildInfoCol('Entry Price', AppFormatter.formatCurrency(trade.entryPrice)),
              _buildInfoCol(trade.isLiquidated ? 'Liq. Price' : 'Exit Price', AppFormatter.formatCurrency(trade.exitPrice)),
            ],
          ),
          
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
