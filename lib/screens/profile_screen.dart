import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/utils/formatter.dart';
import '../providers/portfolio_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_background.dart';
import '../widgets/premium_dialog.dart';
import '../widgets/banner_ad_widget.dart';
import 'about_screen.dart';
import 'policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _editName(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    PremiumDialog.show(
      context,
      title: 'Edit Username',
      message: '', // not used
      emoji: '👤',
      confirmText: 'Save',
      cancelText: 'Cancel',
      content: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: CupertinoTextField(
          controller: controller,
          placeholder: 'Enter username',
          style: const TextStyle(color: CupertinoColors.black), // Black text on white popup background
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      onConfirm: () async {
        final newName = controller.text.trim();
        if (newName.isNotEmpty) {
          await Provider.of<PortfolioProvider>(context, listen: false).updateUsername(newName);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = Provider.of<PortfolioProvider>(context);
    final allTimeProfit = portfolio.totalEquity - 1000.00;
    final investedAmount = portfolio.openPositions.fold(0.0, (sum, pos) => sum + pos.margin);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: LiquidBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ─── Header ───
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Profile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              // ─── Avatar & User Card ───
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Row(
                  children: [
                    // Avatar with gradient ring
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0E76FD),
                            Color(0xFF7C3AED),
                            Color(0xFFF59E0B),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0E76FD).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          portfolio.username.isNotEmpty 
                              ? portfolio.username[0].toUpperCase() 
                              : 'U',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Name + Edit on the right
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            portfolio.username,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _editName(context, portfolio.username),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(CupertinoIcons.pencil, size: 13, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Edit Name',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Balance Card ───
              GlassCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Virtual Balance',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (allTimeProfit >= 0 ? AppColors.profit : AppColors.loss).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                allTimeProfit >= 0
                                    ? CupertinoIcons.arrow_up_right
                                    : CupertinoIcons.arrow_down_right,
                                color: allTimeProfit >= 0 ? AppColors.profit : AppColors.loss,
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppFormatter.formatPnL(allTimeProfit),
                                style: GoogleFonts.plusJakartaSans(
                                  color: allTimeProfit >= 0 ? AppColors.profit : AppColors.loss,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppFormatter.formatCurrency(portfolio.totalEquity),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textPrimary,
                        fontSize: 32,
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
                      children: [
                        Expanded(
                          child: _buildBalanceStat(
                            'Available',
                            AppFormatter.formatCurrency(portfolio.balance),
                            CupertinoIcons.checkmark_shield,
                          ),
                        ),
                        Container(
                          width: 0.5,
                          height: 36,
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: _buildBalanceStat(
                            'Invested',
                            AppFormatter.formatCurrency(investedAmount),
                            CupertinoIcons.chart_pie,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Stats Section ───
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                child: Text(
                  'Statistics',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Max Deal',
                      AppFormatter.formatCurrency(portfolio.maxDeal),
                      CupertinoIcons.arrow_up_circle,
                      const Color(0xFF0E76FD),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'AVG Deal',
                      AppFormatter.formatCurrency(portfolio.avgDeal),
                      CupertinoIcons.chart_bar,
                      const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Max Profit',
                      AppFormatter.formatCurrency(portfolio.maxProfit),
                      CupertinoIcons.arrow_up_right_circle,
                      AppColors.profit,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Max Loss',
                      AppFormatter.formatCurrency(portfolio.maxLoss),
                      CupertinoIcons.arrow_down_right_circle,
                      AppColors.loss,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Settings Section ───
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                child: Text(
                  'Settings',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildSettingsItem(
                      CupertinoIcons.doc_text,
                      'Terms of Service',
                      showDivider: true,
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => PolicyScreen(title: 'Terms of Service', content: PolicyScreen.getTermsContent()))),
                    ),
                    _buildSettingsItem(
                      CupertinoIcons.shield,
                      'Privacy Policy',
                      showDivider: true,
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => PolicyScreen(title: 'Privacy Policy', content: PolicyScreen.getPrivacyContent()))),
                    ),
                    _buildSettingsItem(
                      CupertinoIcons.question_circle,
                      'Help & Support',
                      showDivider: true,
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => PolicyScreen(title: 'Help & Support', content: PolicyScreen.getHelpContent()))),
                    ),
                    _buildSettingsItem(
                      CupertinoIcons.info_circle,
                      'About FunTrade',
                      showDivider: false,
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const AboutScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Version footer
              Center(
                child: Text(
                  'FunTrade v1.0.0',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceStat(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 14),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String label, {bool showDivider = true, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.border.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: AppColors.textSecondary, size: 16),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 0.5,
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
        ],
      ),
    );
  }
}
