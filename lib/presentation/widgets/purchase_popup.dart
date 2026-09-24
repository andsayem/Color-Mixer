import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:colormixer/presentation/controllers/purchase_controller.dart';
import 'package:colormixer/ui/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showPurchasePopup({bool showPreferenceButtons = true}) async {
  if (Get.isDialogOpen == true) return;

  final controller = Get.find<PurchaseController>();
  controller.selectedProduct.value = null;

  final result = await Get.dialog<String>(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Obx(() {
          final removed = controller.adsRemoved.value;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(removed),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!removed) ...[
                        _benefit(
                          Icons.block_rounded,
                          'No banner or full-screen ads',
                        ),
                        _benefit(
                          Icons.bolt_rounded,
                          'Faster, distraction-free mixing',
                        ),
                        _benefit(
                          Icons.favorite_rounded,
                          'Support future updates',
                        ),
                        const SizedBox(height: 16),
                      ],
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: removed ? _success() : _plans(controller),
                      ),
                      const SizedBox(height: 16),
                      if (!removed)
                        _footer(controller, showPreferenceButtons)
                      else
                        _primaryButton(
                          label: 'Done',
                          onPressed: () => Get.back(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  if (result == 'later') {
    await prefs.setInt(
      'purchase_reminder_date',
      DateTime.now().millisecondsSinceEpoch,
    );
  } else if (result == 'dontask') {
    await prefs.setBool('hide_purchase_dialog', true);
  }
  // Show App Open Ad if ads are still not removed
  if (!controller.adsRemoved.value) {
    AdManager.showAppOpen();
  }
}

////////////////////////////////////////////////////////////
/// HEADER
////////////////////////////////////////////////////////////
Widget _header(bool removed) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 8, 8, 24),
    decoration: const BoxDecoration(gradient: AppColors.accentGradient),
    child: Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.goldGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withAlpha(110),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.black87,
            size: 38,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          removed ? 'You are Pro' : 'Color Mixer Pro',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          removed
              ? 'Enjoy the app ad-free'
              : 'Mix colors without interruptions',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    ),
  );
}

////////////////////////////////////////////////////////////
/// SUCCESS
////////////////////////////////////////////////////////////
Widget _success() {
  return const Column(
    key: ValueKey('success'),
    children: [
      Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 64),
      SizedBox(height: 10),
      Text(
        'Ads removed!',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

////////////////////////////////////////////////////////////
/// PLANS
////////////////////////////////////////////////////////////
Widget _plans(PurchaseController c) {
  if (c.isLoading.value && c.availableProducts.isEmpty) {
    return const Padding(
      key: ValueKey('loading'),
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(color: AppColors.accent2)),
    );
  }

  if (c.availableProducts.isEmpty) {
    return const Padding(
      key: ValueKey('empty'),
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        'Plans are not available right now.\n'
        'Please check your connection and try again.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      ),
    );
  }

  return Column(
    key: const ValueKey('plans'),
    children: c.availableProducts.map((p) {
      return Obx(() {
        final selected = c.selectedProduct.value?.id == p.id;
        final isYearly = '${p.id}'.contains('year');

        return GestureDetector(
          onTap: () => c.selectProduct(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent1.withAlpha(30)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.accent1 : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? AppColors.accent1 : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    _planTitle('${p.title}'),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isYearly) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'BEST VALUE',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${p.price}',
                  style: TextStyle(
                    color: selected ? AppColors.accent2 : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }).toList(),
  );
}

/// Store titles come as "Yearly (Color Mixer)"; drop the app name suffix.
String _planTitle(String title) =>
    title.replaceFirst(RegExp(r'\s*\(.*\)\s*$'), '');

////////////////////////////////////////////////////////////
/// FOOTER
////////////////////////////////////////////////////////////
Widget _footer(PurchaseController c, bool showPref) {
  final canBuy = c.selectedProduct.value != null && !c.isLoading.value;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _primaryButton(
        label: c.selectedProduct.value == null
            ? 'Select a plan'
            : 'Subscribe now',
        loading: c.isLoading.value && c.availableProducts.isNotEmpty,
        onPressed: canBuy ? c.purchaseProduct : null,
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: c.isLoading.value ? null : c.restorePurchase,
        child: const Text(
          'Restore purchase',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      if (showPref)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => Get.back(result: 'later'),
              child: const Text(
                'Later',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Get.back(result: 'dontask'),
              child: const Text(
                "Don't show again",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
    ],
  );
}

Widget _primaryButton({
  required String label,
  required VoidCallback? onPressed,
  bool loading = false,
}) {
  return AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: onPressed != null || loading ? 1 : 0.5,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

////////////////////////////////////////////////////////////
/// BENEFIT
////////////////////////////////////////////////////////////
Widget _benefit(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.accent2.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent2, size: 18),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
