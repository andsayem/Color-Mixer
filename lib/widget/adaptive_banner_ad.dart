import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:colormixer/presentation/controllers/purchase_controller.dart';
import 'package:colormixer/presentation/widgets/purchase_popup.dart';
import 'package:colormixer/ui/app_colors.dart';

/// Hides [child] once the user has bought "Remove Ads".
class _HideForPremium extends StatelessWidget {
  const _HideForPremium({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PurchaseController>()) return child;
    final purchase = Get.find<PurchaseController>();
    return Obx(
      () => purchase.adsRemoved.value ? const SizedBox.shrink() : child,
    );
  }
}

/// Puts one bottom-anchored banner under every screen of the app. Use it
/// as `GetMaterialApp(builder: (context, child) => AppBannerShell(child: child!))`.
///
/// It lives outside the Navigator, so it is loaded once per app session
/// and simply stays while the user moves between screens - no new request
/// per page. AdMob's own refresh (set in the AdMob console) then rotates
/// ads in the same, always-visible slot, so each request becomes an
/// impression. The first request asks for a collapsible banner.
class AppBannerShell extends StatelessWidget {
  const AppBannerShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PurchaseController>()) {
      return _layout(context, showBanner: true);
    }
    final purchase = Get.find<PurchaseController>();
    return Obx(
      () => _layout(context, showBanner: !purchase.adsRemoved.value),
    );
  }

  /// The widget tree has the same shape whether or not the banner shows,
  /// so buying "Remove Ads" never rebuilds the Navigator (which would
  /// reset the user's screens).
  Widget _layout(BuildContext context, {required bool showBanner}) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bannerVisible = showBanner && !keyboardOpen;
    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          Expanded(
            // The banner area below handles the bottom system inset.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: bannerVisible,
              child: child,
            ),
          ),
          // Hidden (not disposed) while typing, so the loaded ad survives.
          Visibility(
            visible: bannerVisible,
            maintainState: showBanner,
            child: showBanner ? const _AppBanner() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _AppBanner extends StatelessWidget {
  const _AppBanner();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: AdaptiveBannerAd(
          collapsible: 'bottom',
          // heightFactor 1: only as tall as the ad itself.
          builder: (context, ad) => Center(heightFactor: 1, child: ad),
        ),
      ),
    );
  }
}

/// A 300x250 medium-rectangle ad in a card, for placing inside scrolling
/// content. Medium rectangles usually earn more per impression than
/// banners. Put it in a lazily built list so it's only requested when the
/// user scrolls close to it.
class InlineAdCard extends StatelessWidget {
  const InlineAdCard({
    super.key,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return _HideForPremium(
      child: Padding(
        padding: margin,
        child: AdBanner(
          size: AdSize.mediumRectangle,
          builder: (context, ad) => _AdCard(ad: ad),
        ),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad});

  final Widget ad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AD',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sponsored',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: showPurchasePopup,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                  label: const Text('Remove ads'),
                ),
              ],
            ),
          ),
          ad,
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
