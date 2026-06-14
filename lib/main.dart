import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'core/constants/colors.dart';
import 'core/services/ad_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notification_service.dart';
import 'providers/market_provider.dart';
import 'providers/portfolio_provider.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';

// Background task identifier
const String marketUpdateTask = "com.funtrade.marketUpdate";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == marketUpdateTask) {
      await NotificationService.initialize();
      await NotificationService.checkMarketAndNotify();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // Initialize Background Notifications
    await NotificationService.initialize();
    await NotificationService.requestPermissions();
    await Workmanager().initialize(
      callbackDispatcher,
    );

    // Register periodic task (every 1 hour)
    await Workmanager().registerPeriodicTask(
      "1",
      marketUpdateTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  // Initialize Core Services
  final storageService = await StorageService.init();
  final adService = await AdService.init();

  // Initialize State Providers
  final marketProvider = MarketProvider();
  final portfolioProvider = PortfolioProvider(storageService);

  // Decoupled connection: when market price ticks, update portfolio metrics/liquidations
  marketProvider.addListener(() {
    portfolioProvider.updatePrices(marketProvider.pricesMap);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<MarketProvider>.value(value: marketProvider),
        ChangeNotifierProvider<PortfolioProvider>.value(value: portfolioProvider),
        Provider<AdService>.value(value: adService),
      ],
      child: const FunTradeApp(),
    ),
  );
}

class FunTradeApp extends StatelessWidget {
  const FunTradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'FunTrade',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        barBackgroundColor: AppColors.surface,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.textPrimary,
          textStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 15.0,
            fontWeight: FontWeight.w500,
          ),
          actionTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
          ),
          navTitleTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 17.0,
            fontWeight: FontWeight.w700,
          ),
          navLargeTitleTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 32.0,
            fontWeight: FontWeight.w800,
          ),
          pickerTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 21.0,
          ),
          dateTimePickerTextStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 21.0,
          ),
        ),
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
