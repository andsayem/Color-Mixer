import 'package:colormixer/common/admob_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:colormixer/presentation/controllers/purchase_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showPurchasePopup({bool showPreferenceButtons = true}) async {
  if (Get.isDialogOpen == true) return;

  final controller = Get.find<PurchaseController>();
  controller.selectedProduct.value = null;

  final result = await Get.dialog<String>(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF020617), Color(0xFF0B1120), Color(0xFF111827)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Obx(() {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Remove Ads",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _benefit(
                    Icons.block,
                    "Remove all ads for a smoother experience",
                  ),

                  const SizedBox(height: 20),

                  /// BODY
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: controller.adsRemoved.value
                        ? _success()
                        : _plans(controller),
                  ),

                  const SizedBox(height: 16),

                  /// FOOTER
                  if (!controller.adsRemoved.value)
                    _footer(controller, showPreferenceButtons)
                  else
                    ElevatedButton(
                      onPressed: () => Get.back(),
                      child: const Text("Done"),
                    ),
                ],
              ),
            );
          }),
        ),
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
    AdmobHelper.showAppOpenAd();
  }
}

////////////////////////////////////////////////////////////
/// SUCCESS
////////////////////////////////////////////////////////////
Widget _success() {
  return const Column(
    key: ValueKey('success'),
    children: [
      Icon(Icons.check_circle, color: Colors.green, size: 70),
      SizedBox(height: 10),
      Text("Ads Removed!", style: TextStyle(color: Colors.white, fontSize: 18)),
    ],
  );
}

class N8nColors {
  static const bg = Color(0xFF0B0F17);
  static const card = Color(0xFF111827);

  static const primary = Color(0xFF00E0FF);
  static const accent = Color(0xFF22C55E);

  static const text = Colors.white;
  static const subText = Colors.white70;
}

////////////////////////////////////////////////////////////
/// PLANS (🔥 BEST PART)
////////////////////////////////////////////////////////////
Widget _plans(PurchaseController c) {
  if (c.isLoading.value) {
    return const CircularProgressIndicator(color: N8nColors.primary);
  }

  return Column(
    children: c.availableProducts.map((p) {
      return Obx(() {
        final selected = c.selectedProduct.value?.id == p.id;

        return GestureDetector(
          onTap: () => c.selectProduct(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: N8nColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? N8nColors.primary : Colors.white24,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: N8nColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.circle_outlined,
                  color: selected ? N8nColors.primary : Colors.white54,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  p.price,
                  style: TextStyle(
                    color: selected ? N8nColors.primary : Colors.white,
                    fontWeight: FontWeight.bold,
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

////////////////////////////////////////////////////////////
/// FOOTER
////////////////////////////////////////////////////////////
Widget _footer(PurchaseController c, bool showPref) {
  return Column(
    children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.selectedProduct.value == null
              ? Colors.grey
              : N8nColors.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 48),
        ),
        onPressed: c.selectedProduct.value == null ? null : c.purchaseProduct,
        child: c.isLoading.value
            ? const CircularProgressIndicator()
            : const Text("Subscribe Now"),
      ),
      TextButton(
        onPressed: c.restorePurchase,
        child: const Text(
          "Restore Purchase",
          style: TextStyle(color: Colors.white),
        ),
      ),
      if (showPref)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => Get.back(result: 'later'),
              child: const Text("Later"),
            ),
            TextButton(
              onPressed: () => Get.back(result: 'dontask'),
              child: const Text("Don't show"),
            ),
          ],
        ),
    ],
  );
}

////////////////////////////////////////////////////////////
/// BENEFIT
////////////////////////////////////////////////////////////
Widget _benefit(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, color: N8nColors.primary, size: 18),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
