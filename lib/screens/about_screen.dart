import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('About Fundev')),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(CupertinoIcons.rocket_fill, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            Text(
              'Fundev Team',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              'Biz Fundev dasturchilar jamoasimiz. Biz zamonaviy va foydali ilovalar yaratishga ixtisoslashganmiz. Saytimiz: fundev.uz',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
