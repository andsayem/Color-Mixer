import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:colormixer/presentation/controllers/purchase_controller.dart';
import 'package:colormixer/presentation/widgets/purchase_popup.dart';

/// admob_kit's adaptive banner in a card styled to match the app, with a
/// "Remove ads" shortcut. Takes no space until an ad has actually loaded,
/// and disappears once the user has removed ads.
class AdaptiveBannerAdWidget extends StatelessWidget {
  const AdaptiveBannerAdWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PurchaseController>()) return _banner();

    final purchaseController = Get.find<PurchaseController>();
    return Obx(
      () => purchaseController.adsRemoved.value
          ? const SizedBox.shrink()
          : _banner(),
    );
  }

  Widget _banner() {
    // The margin sits outside the banner so the ad is sized to the card's
    // real width (the card itself must not add horizontal padding).
    return Padding(
      padding: margin,
      child: AdaptiveBannerAd(builder: (context, ad) => _AdCard(ad: ad)),
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad});

  final Widget ad;

  static const _radius = BorderRadius.all(Radius.circular(16));
  static const _labelColor = Color(0xFF9E9EB8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: _radius,
      ),
      // Border as a foreground layer so it doesn't take width from the ad.
      foregroundDecoration: BoxDecoration(
        borderRadius: _radius,
        border: Border.all(color: Colors.white.withAlpha(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(40),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AD',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sponsored',
                  style: TextStyle(color: _labelColor, fontSize: 12),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: showPurchasePopup,
                  style: TextButton.styleFrom(
                    foregroundColor: _labelColor,
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
          Center(child: ad),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
