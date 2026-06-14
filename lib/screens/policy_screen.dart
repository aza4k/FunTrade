import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

class PolicyScreen extends StatelessWidget {
  final String title;
  final String content;

  const PolicyScreen({super.key, required this.title, required this.content});

  static String getTermsContent() => '''
Terms of Service
Last Updated: June 8, 2026

Welcome to FunTrade! By using our app, you agree to these terms.
1. Use of Service: FunTrade is a simulation tool for educational purposes only.
2. Virtual Funds: All funds are virtual and have no real-world value.
3. Conduct: Users must not engage in fraudulent activities or abuse the service.
4. Disclaimer: We are not responsible for any financial loss incurred by improper use of financial knowledge gained here.
''';

  static String getPrivacyContent() => '''
Privacy Policy
Last Updated: June 8, 2026

At Fundev, we value your privacy.
1. Data Collection: We do not collect personal financial data.
2. Usage Data: We may collect anonymized usage data to improve our services.
3. Third Parties: We use Google AdMob for advertisements, which may collect device identifiers.
''';

  static String getHelpContent() => '''
Help & Support
Need assistance?

We are here to help! If you encounter any issues or have questions, please reach out to us at our official website:

fundev.uz

Our support team typically responds within 24-48 hours.
''';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(title)),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              content,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.textPrimary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
