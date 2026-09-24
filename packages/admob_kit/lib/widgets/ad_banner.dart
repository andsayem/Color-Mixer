import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../managers/banner_ad_manager.dart';

/// A self-contained, fixed-size banner ad (320x50 by default).
///
/// ```dart
/// const AdBanner()
/// const AdBanner(size: AdSize.mediumRectangle) // 300x250, in-content
/// ```
///
/// Loads itself on mount, disposes itself on unmount, retries on failure
/// up to `AdMobSettings.maxLoadRetry` times, and renders nothing (never
/// throws, never disrupts layout) if disabled, unsupported on this
/// platform, or ultimately unable to load.
///
/// Inside a lazily built list (ListView / SliverList) it is only created -
/// and so only requested - once the user scrolls near it, which keeps
/// requests that never become impressions to a minimum.
///
/// Pass [builder] to decorate the ad only once it has loaded.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, this.size = AdSize.banner, this.builder});

  final AdSize size;
  final Widget Function(BuildContext context, Widget ad)? builder;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _readyAd;
  bool _disposed = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (!AdMobSettings.enableBanner || !AdMobUtils.isSupportedPlatform) {
      return;
    }
    BannerAdManager.loadStandardBanner(
      size: widget.size,
      onLoaded: (ad) {
        if (_disposed) {
          ad.dispose();
          return;
        }
        setState(() => _readyAd = ad);
      },
      onFailed: (error) {
        if (_disposed) return;
        _retry();
      },
    );
  }

  void _retry() {
    if (_retryCount >= AdMobSettings.maxLoadRetry) return;
    _retryCount++;
    final delay = Duration(
      seconds: AdMobSettings.retryBaseDelaySeconds * _retryCount,
    );
    AdMobLogger.log('Banner retry #$_retryCount in ${delay.inSeconds}s');
    Future.delayed(delay, () {
      if (!_disposed) _load();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _readyAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _readyAd;
    Widget child = const SizedBox.shrink();
    if (ad != null) {
      final Widget adView = SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      );
      child = widget.builder?.call(context, adView) ?? adView;
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}
