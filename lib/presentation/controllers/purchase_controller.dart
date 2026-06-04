import 'package:get/get.dart';
import 'package:colormixer/core/services/purchase_service.dart';

class PurchaseController extends GetxController {
  var adsRemoved = false.obs;
  var isLoading = false.obs;
  var availableProducts = [].obs;
  var isBannerLoaded = false.obs;

  /// ✅ FIXED (reactive)
  var selectedProduct = Rxn<dynamic>();

  final PurchaseService svc = Get.put(PurchaseService());

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    checkAdsRemoved();
  }

  void loadProducts() async {
    isLoading.value = true;
    await svc.initialize();
    availableProducts.assignAll(svc.availableProducts);
    isLoading.value = false;
  }

  void selectProduct(dynamic p) {
    selectedProduct.value = p;
  }

  Future<void> checkAdsRemoved() async {
    adsRemoved.value = await svc.getAdsRemovedLocal();
  }

  Future<void> purchaseProduct() async {
    if (selectedProduct.value == null) return;

    isLoading.value = true;
    final res = await svc.purchaseProduct(selectedProduct.value);
    isLoading.value = false;

    if (res.$1) {
      adsRemoved.value = true;
      Get.snackbar("Success", "Ads removed successfully");
    } else {
      Get.snackbar("Error", res.$2);
    }
  }

  Future<void> restorePurchase() async {
    isLoading.value = true;
    await svc.restorePurchases();
    final removed = await svc.getAdsRemovedLocal();
    adsRemoved.value = removed;
    isLoading.value = false;

    Get.snackbar("Restore", removed ? "Ads removed" : "No purchase found");
  }
}
