import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admob_kit/admob_kit.dart';
import 'presentation/controllers/purchase_controller.dart';
import 'pages/home_page.dart';
import 'pages/mixer_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final purchaseController = Get.put(PurchaseController());

  // Ad types this app doesn't use (no ad units configured).
  AdMobSettings.enableRewarded = false;
  AdMobSettings.enableRewardedInterstitial = false;
  AdMobSettings.enableNative = false;

  // Premium "Remove Ads" turns every ad type off.
  _setAdsEnabled(!purchaseController.adsRemoved.value);
  ever<bool>(purchaseController.adsRemoved, (removed) {
    _setAdsEnabled(!removed);
    if (!AdMobService.isInitialized) return;
    if (removed) {
      InterstitialAdManager.dispose();
    } else {
      AdManager.preloadAll();
      AppOpenAdManager.initialize();
    }
  });

  await AdMobService.initialize();
  AdManager.preloadAll();
  AppOpenAdManager.initialize();

  // Cold-start App Open ad, once it has had time to load.
  Future.delayed(const Duration(seconds: 3), AdManager.showAppOpen);

  runApp(const PolikColorMixerApp());
}

void _setAdsEnabled(bool enabled) {
  AdMobSettings.enableBanner = enabled;
  AdMobSettings.enableAdaptiveBanner = enabled;
  AdMobSettings.enableInterstitial = enabled;
  AdMobSettings.enableAppOpen = enabled;
}

class PolikColorMixerApp extends StatelessWidget {
  const PolikColorMixerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Color Mixer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent1,
          secondary: AppColors.accent2,
          surface: AppColors.surface,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const HomePage(),
    );
  }
}
