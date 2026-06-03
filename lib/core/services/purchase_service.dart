import 'dart:async';
import 'dart:developer';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  PurchaseService();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  final Set<String> productIds = {
    'monthly', // Yearly subscription
    'yearly', // Monthly subscription
  };

  List<ProductDetails> availableProducts = [];
  ProductDetails? selectedProduct;

  bool isAvailable = false;
  bool isLoading = false;

  // Track if any purchases were found during restore
  bool _purchasesFound = false;

  // Track processed purchases to avoid duplicates
  final Set<String> _processedPurchaseIds = {};

  final StreamController<String> _logs = StreamController<String>.broadcast();
  Stream<String> get logs => _logs.stream;

  final StreamController<bool> _purchaseUpdates =
      StreamController<bool>.broadcast();
  Stream<bool> get purchaseUpdates => _purchaseUpdates.stream;

  Completer<bool>? _purchaseCompleter;

  Future<void> initialize() async {
    try {
      _logs.add('Initializing IAP');
      // print('IAP Initializing');
      isAvailable = await _iap.isAvailable();
      // print('IAP Initialized: $isAvailable');
      if (!isAvailable) {
        _logs.add('In-app purchases not available on device');
        return;
      }

      // print('IAP Product query');
      try {
        final response = await _iap
            .queryProductDetails(productIds)
            .timeout(const Duration(seconds: 30));
        // print('IAP Product query error: ${response.error}');
        if (response.error != null) {
          _logs.add('Product query error: ${response.error}');
        }
        availableProducts = response.productDetails;
        if (availableProducts.isNotEmpty && selectedProduct == null) {
          selectedProduct = availableProducts.first;
          _logs.add('Auto-selected product: ${selectedProduct!.id}');
        }
        if (response.notFoundIDs.isNotEmpty) {
          // print('IAP Products not found: ${response.notFoundIDs.join(', ')}');
          _logs.add('Products not found: ${response.notFoundIDs.join(', ')}');
        }
      } on TimeoutException {
        _logs.add('Product query timed out');
        availableProducts = [];
      } catch (e, st) {
        _logs.add('Product query failed: $e');
        log('IAP product query', error: e, stackTrace: st);
        availableProducts = [];
      }

      _listenToPurchaseUpdates();
      _logs.add('IAP initialized, ${availableProducts.length} products');

      // Restore previous purchases on initialization
      _logs.add('Restoring previous purchases...');
      try {
        await restorePurchases(isAutoRestore: true);
      } catch (e) {
        _logs.add('Restore purchases error: $e');
      }
    } catch (e, st) {
      _logs.add('IAP initialize failed: $e');
      log('IAP initialize', error: e, stackTrace: st);
    }
  }

  void _listenToPurchaseUpdates() {
    _sub ??= _iap.purchaseStream.listen(
      (purchaseDetailsList) async {
        _logs.add('Purchase stream event: ${purchaseDetailsList.length} items');

        for (final purchaseDetails in purchaseDetailsList) {
          _logs.add(
            'Purchase update: ${purchaseDetails.status} ${purchaseDetails.productID}',
          );
          if (purchaseDetails.status == PurchaseStatus.purchased ||
              purchaseDetails.status == PurchaseStatus.restored) {
            _purchasesFound = true;
            await _processPurchase(purchaseDetails);
          } else if (purchaseDetails.status == PurchaseStatus.error) {
            _handleError(purchaseDetails.error);
            _completePurchase(false);
          } else if (purchaseDetails.status == PurchaseStatus.canceled) {
            _logs.add('Purchase canceled: ${purchaseDetails.productID}');
            _completePurchase(false);
          }
        }

        // If no purchases were processed but completer still exists, complete it
        if (purchaseDetailsList.isEmpty &&
            _purchaseCompleter != null &&
            !_purchaseCompleter!.isCompleted) {
          _logs.add(
            'Empty purchase list - completing restore with no purchases',
          );
          _completePurchase(true); // No error, just no purchases to restore
        }
      },
      onError: (e) {
        _logs.add('Purchase stream error: $e');
        _completePurchase(false);
      },
    );
  }

  Future<void> _processPurchase(PurchaseDetails purchaseDetails) async {
    try {
      // Prevent duplicate processing of the same purchase
      final purchaseKey =
          '${purchaseDetails.productID}_${purchaseDetails.purchaseID}';
      if (_processedPurchaseIds.contains(purchaseKey)) {
        _logs.add('Skipping already processed purchase: $purchaseKey');
        return;
      }
      _processedPurchaseIds.add(purchaseKey);

      if (purchaseDetails.pendingCompletePurchase) {
        await _iap.completePurchase(purchaseDetails);
      }

      if (purchaseDetails.productID == 'yearly' ||
          purchaseDetails.productID == 'monthly') {
        await _saveAdsRemoved();
        _purchaseUpdates.add(true);
        _completePurchase(true);
        _logs.add(
          'Granted ads removed for ${purchaseDetails.productID} (${purchaseDetails.status})',
        );
      } else {
        _logs.add('Unknown product purchased: ${purchaseDetails.productID}');
        _completePurchase(false);
      }
    } catch (e, st) {
      _logs.add('Failed to process purchase: $e');
      log('processPurchase', error: e, stackTrace: st);
      _completePurchase(false);
    }
  }

  void _handleError(IAPError? error) {
    _logs.add('IAP error: ${error?.details ?? error}');
  }

  void _completePurchase(bool success) {
    try {
      _purchaseCompleter?.complete(success);
    } catch (_) {}
    _purchaseCompleter = null;
  }

  Future<(bool, String)> purchaseProduct(ProductDetails product) async {
    isLoading = true;
    try {
      // Clear old processed purchases for fresh purchase attempt
      _processedPurchaseIds.clear();

      final purchaseParam = PurchaseParam(productDetails: product);

      // Use buyConsumable for one-time purchases, buyNonConsumable for subscriptions
      if (product.id == 'n8n_ads_remove') {
        // One-time purchase
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        // Subscriptions (yearly, monthly)
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }

      _purchaseCompleter = Completer<bool>();
      final result = await _purchaseCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _purchaseCompleter?.complete(false);
          return false;
        },
      );

      if (result) return (true, 'Purchase successful');
      return (false, 'Purchase failed or cancelled');
    } on Exception catch (e) {
      _logs.add('Purchase exception: $e');
      return (false, e.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<bool> restorePurchases({bool isAutoRestore = false}) async {
    print('Initiating restore purchases... (auto=$isAutoRestore)');
    try {
      _logs.add('Restore requested (auto=$isAutoRestore)');

      // Reset purchases found flag for this restore attempt
      _purchasesFound = false;

      // Create completer to wait for purchase stream response
      _purchaseCompleter = Completer<bool>();
      final originalCompleter = _purchaseCompleter;

      _logs.add('Calling IAP restorePurchases()...');
      await _iap.restorePurchases();

      // Wait for the purchase stream to emit events
      try {
        final result = await _purchaseCompleter!.future.timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            _logs.add('Restore timed out');
            // Complete with true anyway (success = no error, even if no purchases)
            if (_purchaseCompleter == originalCompleter &&
                !_purchaseCompleter!.isCompleted) {
              _purchaseCompleter!.complete(true);
            }
            return true;
          },
        );
        print(
          'Restore purchases completed: $result, purchases found: $_purchasesFound',
        );
        _logs.add(
          'Restore stream response received: $result, purchases found: $_purchasesFound',
        );

        // Set ads_removed flag based on whether purchases were found
        if (_purchasesFound) {
          print('Purchases found during restore.');
          _logs.add('Purchases found - setting ads_removed to true');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('ads_removed', true);
        } else if (!isAutoRestore) {
          // ✅ ONLY reset to false on explicit user-initiated restore
          // Auto-restore should NEVER clear a previously saved subscription
          print('No purchases found during manual restore.');
          _logs.add(
            'No purchases found (manual) - setting ads_removed to false',
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('ads_removed', false);
        } else {
          print(
            'No purchases found during auto-restore - keeping existing state.',
          );
          _logs.add(
            'No purchases found (auto) - keeping existing ads_removed state',
          );
        }

        return result;
      } catch (e) {
        print('Restore wait error: $e');
        _logs.add('Restore future error: $e');
        // On auto-restore error, don't reset ads_removed
        if (!isAutoRestore) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('ads_removed', false);
        }
        return true; // No error is a success
      }
    } catch (e) {
      _logs.add('Restore exception: $e');
      return false;
    } finally {
      _purchaseCompleter = null;
    }
  }

  Future<void> _saveAdsRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ads_removed', true);
  }

  Future<void> markAdsRemovedLocally() async {
    await _saveAdsRemoved();
    _purchaseUpdates.add(true);
  }

  Future<bool> getAdsRemovedLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ads_removed') ?? false;
  }

  void dispose() {
    _sub?.cancel();
    _logs.close();
    _purchaseUpdates.close();
  }
}
