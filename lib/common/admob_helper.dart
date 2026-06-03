import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; 
import 'package:colormixer/presentation/controllers/purchase_controller.dart';

class AdmobHelper with WidgetsBindingObserver {
  //ca-app-pub-1195883693665145/6786028831
  // ---------------- Ad Unit IDs ----------------
  static const String bannerAdUnitId = "ca-app-pub-1195883693665145/2376508248";
  static const String interstitialAdUnitId = "ca-app-pub-1195883693665145/8138829177";
  static const String rewardedAdUnitId = "ca-app-pub-1195883693665145/4199584161";
  static const String appOpenAdUnitId = "ca-app-pub-1195883693665145/6834628007";

  static bool get _areAdsRemoved {
    try {
      if (Get.isRegistered<PurchaseController>()) {
        return Get.find<PurchaseController>().adsRemoved.value;
      }
    } catch (_) {}
    return false;
  }

  // ================= Interstitial =================
  static InterstitialAd? _interstitialAd;
  static bool suppressAppOpen = false;

  static bool _isInterstitialLoading = false; 

/// LOAD
static void loadInterstitialAd() {
  if (_areAdsRemoved) return;
  if (_isInterstitialLoading || _interstitialAd != null) return;

  _isInterstitialLoading = true;

  InterstitialAd.load(
    adUnitId: interstitialAdUnitId,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitialAd = ad;
        _isInterstitialLoading = false;

        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;

            // reload immediately (important)
            loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialAd = null;

            loadInterstitialAd();
          },
        );
      },

      onAdFailedToLoad: (error) {
        _isInterstitialLoading = false;

        // 🔥 smart retry (exponential delay)
        Future.delayed(const Duration(seconds: 10), () {
          loadInterstitialAd();
        });
      },
    ),
  );
}
static void showInterstitialAd({VoidCallback? onAdDismissed}) {
  if (_areAdsRemoved) {
    if (onAdDismissed != null) {
      onAdDismissed();
    }
    return;
  }
  if (_interstitialAd == null) {
    debugPrint("Ad not ready");

    // 👉 fallback flow continue
    if (onAdDismissed != null) {
      onAdDismissed();
    }

    return;
  }

  _interstitialAd!.fullScreenContentCallback =
      FullScreenContentCallback(
    onAdDismissedFullScreenContent: (ad) {
      ad.dispose();
      _interstitialAd = null;

      if (onAdDismissed != null) {
        onAdDismissed();
      }

      loadInterstitialAd();
    },
    onAdFailedToShowFullScreenContent: (ad, error) {
      ad.dispose();
      _interstitialAd = null;

      if (onAdDismissed != null) {
        onAdDismissed();
      }

      loadInterstitialAd();
    },
  );

  _interstitialAd!.show();
}
  // ================= Rewarded =================
  static RewardedAd? _rewardedAd;

  // static void loadRewardedAd() {
  //   RewardedAd.load(
  //     adUnitId: rewardedAdUnitId,
  //     request: const AdRequest(),
  //     rewardedAdLoadCallback: RewardedAdLoadCallback(
  //       onAdLoaded: (ad) => _rewardedAd = ad,
  //       onAdFailedToLoad: (error) {
  //         debugPrint("Rewarded failed: $error");
  //         _rewardedAd = null;

  //         Future.delayed(const Duration(seconds: 10), () {
  //           loadRewardedAd();
  //         });
  //       },
  //     ),
  //   );
  // }

  /// ✅ FIXED: always navigate even if ad not loaded
  // static void showRewardedAd(Function(RewardItem) onEarnedReward) {
  //   if (_rewardedAd != null) {
  //     _rewardedAd!.fullScreenContentCallback =
  //         FullScreenContentCallback(
  //       onAdDismissedFullScreenContent: (ad) {
  //         ad.dispose();
  //         _rewardedAd = null;
  //         loadRewardedAd();
  //       },
  //       onAdFailedToShowFullScreenContent: (ad, error) {
  //         ad.dispose();
  //         _rewardedAd = null;
  //         loadRewardedAd();
  //       },
  //     );

  //     _rewardedAd!.show(
  //       onUserEarnedReward: (ad, reward) {
  //         onEarnedReward(reward);
  //       },
  //     );

  //     _rewardedAd = null;
  //   } else {
  //     // 🔥 গুরুত্বপূর্ণ fix (না থাকলে click এ কিছুই হবে না)
  //     loadRewardedAd(); 
  //   }
  // }

  // ================= Banner =================
  static BannerAd? _bannerAd;
  static final Map<String, BannerAd> _bannerAdCache = {};

  static String _bannerAdKey({String? adUnitId, required AdSize size}) {
    return '${adUnitId ?? bannerAdUnitId}_${size.width}x${size.height}';
  }

  static Future<BannerAd?> loadAdaptiveBanner(BuildContext context) async {
    if (_areAdsRemoved) return null;
    final width = MediaQuery.of(context).size.width.toInt();

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (size == null) return null;

    BannerAd banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('Adaptive Banner loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed: $error');
        },
      ),
    );

    await banner.load();
    return banner;
  }

  static Future<BannerAd?> loadBannerAd({
    String? adUnitId,
    AdSize size = const AdSize(width: 320, height: 50),
  }) async {
    if (_areAdsRemoved) return null;
    final banner = BannerAd(
      adUnitId: adUnitId ?? bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('Banner loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed: $error');
        },
      ),
    );

    await banner.load();
    return banner;
  }

  static BannerAd getBannerAdInstance({String? adUnitId, AdSize size = const AdSize(width: 320, height: 50)}) {
    return BannerAd(
      adUnitId: adUnitId ?? bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('Banner loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed: $error');
        },
      ),
    );
  }

  static Widget getBannerAdWidget({String? adUnitId, AdSize size = const AdSize(width: 320, height: 50)}) {
    if (_areAdsRemoved) return const SizedBox.shrink();
    final key = _bannerAdKey(adUnitId: adUnitId, size: size);
    final bannerAd = _bannerAdCache.putIfAbsent(
      key,
      () => getBannerAdInstance(adUnitId: adUnitId, size: size)..load(),
    );

    return SizedBox(
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }

  static Widget bannerAdWidget(BannerAd bannerAd, {double? width, double? height}) {
    if (_areAdsRemoved) return const SizedBox.shrink();
    return SizedBox(
      width: width ?? bannerAd.size.width.toDouble(),
      height: height ?? bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }

  // ================= App Open =================
  static AppOpenAd? _appOpenAd;
  static DateTime? _appOpenLoadTime;
  static bool _isShowingAppOpen = false;
  static final Duration maxCacheDuration = const Duration(hours: 4);

  void loadAppOpenAd({Function()? onLoaded}) {
    if (_areAdsRemoved) return;
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          if (onLoaded != null) onLoaded();
        },
        onAdFailedToLoad: (error) =>
            debugPrint("AppOpenAd failed: $error"),
      ),
    );
  }

  static void showAppOpenAd() {
    if (_areAdsRemoved || suppressAppOpen || _appOpenAd == null || _isShowingAppOpen) return;

    if (_appOpenLoadTime != null &&
        DateTime.now()
            .subtract(maxCacheDuration)
            .isAfter(_appOpenLoadTime!)) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      return;
    }

    _appOpenAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingAppOpen = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpen = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAppOpen = false;
        ad.dispose();
        _appOpenAd = null;
      },
    );

    _appOpenAd!.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showAppOpenAd();
    }
  }

  // ================= Adaptive Banner =================
  static AdManagerBannerAd? _adaptiveBannerAd;
  static bool _isAdaptiveLoaded = false;

  static Future<Widget> getAdaptiveBannerWidget(double adWidth,
      {String? adUnitId}) async {
    if (_areAdsRemoved) return const SizedBox.shrink();

    if (_adaptiveBannerAd != null && _isAdaptiveLoaded) {
      return SizedBox(
        width: adWidth,
        height: _adaptiveBannerAd!.sizes.first.height.toDouble(),
        child: AdWidget(ad: _adaptiveBannerAd!),
      );
    }

    final completer = Completer<Widget>();

    final AdSize size =
        AdSize.getCurrentOrientationInlineAdaptiveBannerAdSize(
            adWidth.truncate());

    _adaptiveBannerAd = AdManagerBannerAd(
      adUnitId: adUnitId ?? bannerAdUnitId,
      sizes: [size],
      request: const AdManagerAdRequest(),
      listener: AdManagerBannerAdListener(
        onAdLoaded: (ad) {
          _isAdaptiveLoaded = true;

          completer.complete(
            SizedBox(
              width: adWidth,
              height: size.height.toDouble(),
              child: AdWidget(ad: ad as AdManagerBannerAd),
            ),
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _adaptiveBannerAd = null;
          _isAdaptiveLoaded = false;

          debugPrint('Adaptive Banner Failed: $error');

          completer.complete(const SizedBox());
        },
      ),
    );

    _adaptiveBannerAd!.load();

    return completer.future;
  }

  // ================= Dispose =================
  static void disposeAds() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
  }
}