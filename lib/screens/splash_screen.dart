import 'package:flutter/cupertino.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Splash screen uchun 2.5 soniya kutish
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(builder: (context) => const MainShell()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rasm yuklanishida xatolik bo'lsa dastur qotib qolmasligi uchun 
            // xavfsiz yuklash usulidan foydalanamiz
            Image.asset(
              'logos/FunTrade.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(CupertinoIcons.rocket_fill, size: 100, color: CupertinoColors.white);
              },
            ),
            const SizedBox(height: 20),
            const CupertinoActivityIndicator(radius: 15),
          ],
        ),
      ),
    );
  }
}
