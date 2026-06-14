import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/config.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  bool get isRewardedAdReady => _rewardedAd != null;
  bool get isRewardedAdLoading => _isRewardedLoading;

  bool get isInterstitialAdReady => _interstitialAd != null;
  bool get isInterstitialAdLoading => _isInterstitialLoading;

  static Future<AdService> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
    }
    final service = AdService();
    if (!kIsWeb) {
      service.loadInterstitialAd();
      service.loadRewardedAd();
    }
    return service;
  }

  // Interstitial Ad Management
  void loadInterstitialAd() {
    if (kIsWeb) return;
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd({required VoidCallback onDismissed}) {
    if (kIsWeb) {
      onDismissed();
      return;
    }
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          loadInterstitialAd();
          onDismissed();
        },
      );
      _interstitialAd!.show();
    } else {
      // If the ad is not ready, load it and proceed immediately to not block user flow
      loadInterstitialAd();
      onDismissed();
    }
  }

  // Rewarded Ad Management
  void loadRewardedAd() {
    if (kIsWeb) return;
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: AppConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          _rewardedAd = null;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    required VoidCallback onAdDismissed,
    required VoidCallback onAdFailedToLoad,
  }) {
    if (kIsWeb) {
      onUserEarnedReward();
      onAdDismissed();
      return;
    }
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          onAdDismissed();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onUserEarnedReward();
        },
      );
    } else {
      loadRewardedAd();
      onAdFailedToLoad();
    }
  }
}
