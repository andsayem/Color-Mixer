import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:admob_kit/admob_kit.dart';
import 'presentation/controllers/purchase_controller.dart';
import 'pages/home_page.dart';
import 'ui/app_colors.dart';
import 'widget/adaptive_banner_ad.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final purchaseController = Get.put(PurchaseController());

  // Ad types this app doesn't use (no ad units configured).
  AdMobSettings.enableRewarded = false;
  AdMobSettings.enableRewardedInterstitial = false;
  AdMobSettings.enableNative = false;

  // Space out retries after a failed load (usually no-fill): retrying
  // within seconds rarely fills and only adds unmatched requests.
  AdMobSettings.retryBaseDelaySeconds = 10;

  // Load full-screen ads just before they can be shown, not ahead of time,
  // so loaded ads get shown instead of expiring (requests -> impressions).
  AdMobSettings.reloadInterstitialAfterShow = false;
  AdMobSettings.appOpenLoadOnBackground = true;

  // Premium "Remove Ads" turns every ad type off.
  _setAdsEnabled(!purchaseController.adsRemoved.value);
  ever<bool>(purchaseController.adsRemoved, (removed) {
    _setAdsEnabled(!removed);
    if (!AdMobService.isInitialized) return;
    if (removed) {
      InterstitialAdManager.dispose();
    } else {
      AppOpenAdManager.initialize();
    }
  });

  await AdMobService.initialize();
  // Interstitials load on demand (mixer / new-project dialog), not here.
  AppOpenAdManager.initialize();

  _showColdStartAppOpen();

  runApp(const PolikColorMixerApp());
}

/// Shows the cold-start App Open ad the moment it finishes loading, instead
/// of after a fixed delay (which either missed a slow load or made users
/// wait for a fast one). Gives up after a few seconds so the ad never
/// interrupts someone already using the app; a loaded ad isn't wasted -
/// it stays cached for the next time the app is opened.
Future<void> _showColdStartAppOpen() async {
  const step = Duration(milliseconds: 250);
  for (
    var waited = Duration.zero;
    waited < const Duration(seconds: 4);
    waited += step
  ) {
    if (!AdMobSettings.enableAppOpen) return;
    if (AdManager.isAppOpenReady) {
      await AdManager.showAppOpen();
      return;
    }
    await Future.delayed(step);
  }
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
      // One app-wide bottom banner, kept across screen changes.
      builder: (context, child) => AppBannerShell(child: child!),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent1,
          secondary: AppColors.accent2,
          tertiary: AppColors.accent3,
          surface: AppColors.surface,
          error: AppColors.red,
          onSurface: AppColors.textPrimary,
          outline: AppColors.border,
        ),
        dividerColor: AppColors.divider,
        splashFactory: InkSparkle.splashFactory,
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.cardBright,
          contentTextStyle: const TextStyle(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.accent2),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.accent2,
          selectionHandleColor: AppColors.accent2,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.cardBright,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
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
