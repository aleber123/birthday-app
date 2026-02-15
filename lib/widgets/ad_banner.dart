import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/ad_service.dart';
import '../services/premium_service.dart';

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = AdService().createBannerAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() => _isAdLoaded = true);
        }
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        if (mounted) {
          setState(() => _isAdLoaded = false);
        }
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads on web
    if (kIsWeb) return const SizedBox.shrink();

    // Don't show ads for premium users
    final premium = context.watch<PremiumService>();
    if (premium.isPremium) return const SizedBox.shrink();

    // Don't show if ad hasn't loaded
    if (!_isAdLoaded || _bannerAd == null) return const SizedBox.shrink();

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
