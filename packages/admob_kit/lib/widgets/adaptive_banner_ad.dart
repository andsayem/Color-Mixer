import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_settings.dart';
import '../core/admob_logger.dart';
import '../core/admob_utils.dart';
import '../managers/banner_ad_manager.dart';

/// A full-width, adaptive-height banner ad sized to the space it's
/// actually placed in.
///
/// ```dart
/// const AdaptiveBannerAd()
/// ```
///
/// Sized via [LayoutBuilder] against the real available width - not the
/// full screen width - so it renders correctly even inside padding or a
/// constrained column, not just when placed edge-to-edge. Generally
/// preferred over [AdBanner]'s fixed 320x50: using more of the available
/// width increases fill rate and eCPM (Google's own recommendation).
///
/// Its height is resolved from AdMob at load time - do not wrap it in a
/// fixed-height container. It renders nothing before loaded (or if
/// disabled/unsupported/ultimately failed).
///
/// Pass [builder] to decorate the ad (a card, an "Ad" label, ...) only once
/// it has actually loaded, so nothing is drawn around an empty slot. The ad
/// is sized to this widget's own width, so the builder must not add
/// horizontal padding or borders around it.
///
/// ```dart
/// AdaptiveBannerAd(
///   builder: (context, ad) => Column(children: [const Text('Ad'), ad]),
/// )
/// ```
///
/// Set [collapsible] (`'bottom'` or `'top'`, matching where the banner is
/// anchored) to request a collapsible banner: it opens larger, then
/// collapses to a normal banner. Only the first request asks for it -
/// Google recommends not collapsing on every load.
class AdaptiveBannerAd extends StatefulWidget {
  const AdaptiveBannerAd({super.key, this.builder, this.collapsible});

  final Widget Function(BuildContext context, Widget ad)? builder;
  final String? collapsible;

  @override
  State<AdaptiveBannerAd> createState() => _AdaptiveBannerAdState();
}

class _AdaptiveBannerAdState extends State<AdaptiveBannerAd> {
  BannerAd? _readyAd;
  bool _disposed = false;
  bool _requested = false;
  int _retryCount = 0;

  void _requestLoad(int width) {
    if (_requested) return;
    _requested = true;
    // Defer past the current build/layout phase - _load eventually calls
    // setState, which must not happen synchronously while this widget's
    // own build is still running.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) _load(width);
    });
  }

  void _load(int width) {
    if (!AdMobSettings.enableAdaptiveBanner ||
        !AdMobUtils.isSupportedPlatform) {
      return;
    }
    final collapsible = widget.collapsible;
    BannerAdManager.loadAdaptiveBanner(
      width: width,
      extras: collapsible != null && _retryCount == 0
          ? {'collapsible': collapsible}
          : null,
      onLoaded: (ad) {
        if (_disposed) {
          ad.dispose();
          return;
        }
        setState(() => _readyAd = ad);
      },
      onFailed: (error) {
        if (_disposed) return;
        _retry(width);
      },
    );
  }

  void _retry(int width) {
    if (_retryCount >= AdMobSettings.maxLoadRetry) return;
    _retryCount++;
    final delay = Duration(
      seconds: AdMobSettings.retryBaseDelaySeconds * _retryCount,
    );
    AdMobLogger.log(
      'Adaptive banner retry #$_retryCount in ${delay.inSeconds}s',
    );
    Future.delayed(delay, () {
      if (!_disposed) _load(width);
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
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
          _requestLoad(constraints.maxWidth.truncate());
        }

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

        // Grow into place instead of pushing the layout in one jump.
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
    );
  }
}
