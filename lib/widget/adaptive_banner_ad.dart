import 'package:colormixer/common/admob_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:colormixer/presentation/controllers/purchase_controller.dart';

class AdaptiveBannerAdWidget extends StatefulWidget {
  const AdaptiveBannerAdWidget({super.key});

  @override
  State<AdaptiveBannerAdWidget> createState() => _AdaptiveBannerAdWidgetState();
}

class _AdaptiveBannerAdWidgetState extends State<AdaptiveBannerAdWidget> {
  BannerAd? _bannerAd;

  bool _isLoaded = false;
  bool _isLoading = false;
  bool _hasLoadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    try {
      if (Get.isRegistered<PurchaseController>() && Get.find<PurchaseController>().adsRemoved.value) {
        return;
      }
    } catch (_) {}

    if (_isLoading || _bannerAd != null) return;

    _isLoading = true;

    try {
      final int width = MediaQuery.of(context).size.width.truncate();

      final AdSize? adSize =
          await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

      if (adSize == null) {
        _isLoading = false;
        return;
      }

      final BannerAd bannerAd = BannerAd(
        adUnitId: AdmobHelper.bannerAdUnitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }

            setState(() {
              _bannerAd = ad as BannerAd;
              _isLoaded = true;
              _isLoading = false;
            });
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            ad.dispose();

            debugPrint('Banner failed to load: $error');

            _isLoading = false;

            // Retry after 10 seconds
            Future.delayed(const Duration(seconds: 10), () {
              if (mounted) {
                _loadAd();
              }
            });
          },
        ),
      );

      await bannerAd.load();
    } catch (e) {
      debugPrint('Banner load error: $e');
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PurchaseController>()) {
      return const SizedBox(height: 60);
    }

    final purchaseController = Get.find<PurchaseController>();
    return Obx(() {
      if (purchaseController.adsRemoved.value) {
        return const SizedBox.shrink();
      }
      if (!_isLoaded || _bannerAd == null) {
        return const SizedBox(height: 60);
      }

      return SafeArea(
        child: Container(
          alignment: Alignment.center,
          color: Colors.transparent,
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
    });
  }
}
