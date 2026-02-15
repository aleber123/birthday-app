import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Your AdMob IDs
  static const String appId = 'ca-app-pub-4013461464810205~7147820983';
  static const String bannerAdUnitId = 'ca-app-pub-4013461464810205/3208575979';

  // Test IDs (use during development)
  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  /// Get the correct banner ad unit ID
  /// Uses test IDs in debug mode, real IDs in release
  static String getBannerAdUnitId() {
    // In production (release mode), use the real ad unit ID
    // In debug mode, use test IDs to avoid policy violations
    const bool isRelease = bool.fromEnvironment('dart.vm.product');
    if (isRelease) {
      return bannerAdUnitId;
    }
    // Use test ad for development
    return testBannerAndroid; // Will work on both platforms during testing
  }

  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: getBannerAdUnitId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}
