import 'package:flutter/cupertino.dart';
import '../core/constants/colors.dart';
import '../core/utils/formatter.dart';
import '../models/position.dart';
import '../widgets/glass_card.dart';

class PositionCard extends StatelessWidget {
  final Position position;
  final VoidCallback onClose;

  const PositionCard({
    super.key,
    required this.position,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final pnl = position.unrealizedPnl;
    final isProfit = pnl >= 0;
    final pnlColor = isProfit ? AppColors.profit : AppColors.loss;
    final pnlPercent = (pnl / position.margin) * 100;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      borderCol: pnlColor.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      position.symbol,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: (position.isLong ? AppColors.profit : AppColors.loss).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (position.isLong ? AppColors.profit : AppColors.loss).withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        position.isLong ? 'LONG' : 'SHORT',
                        style: TextStyle(
                          color: position.isLong ? AppColors.profit : AppColors.loss,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${position.leverage}x',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatter.formatPnL(pnl),
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatter.formatPercentage(pnlPercent),
                      style: TextStyle(
                        color: pnlColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(height: 0.8, color: AppColors.border),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem('Entry Price', AppFormatter.formatCurrency(position.entryPrice)),
                    _buildDetailItem('Margin', AppFormatter.formatCurrency(position.margin)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem('Mark Price', AppFormatter.formatCurrency(position.currentPrice)),
                    _buildDetailItem('Liq. Price', AppFormatter.formatCurrency(position.liquidationPrice)),
                  ],
                ),
                if (position.takeProfit != null || position.stopLoss != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (position.takeProfit != null)
                        _buildDetailItem('Take Profit', AppFormatter.formatCurrency(position.takeProfit!))
                      else
                        const Spacer(),
                      if (position.stopLoss != null)
                        _buildDetailItem('Stop Loss', AppFormatter.formatCurrency(position.stopLoss!))
                      else
                        const Spacer(),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: CupertinoButton(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              onPressed: onClose,
              child: const Text(
                'Close Position',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
