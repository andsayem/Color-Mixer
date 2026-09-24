import 'package:admob_kit/admob_kit.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uses Google's test ad unit IDs by default (AdMobSettings.useTestAds
  // defaults to kDebugMode) - safe to run as-is before you configure
  // AdMobConfig with real IDs.
  await AdMobService.initialize();
  AdManager.preloadAll();
  AppOpenAdManager.initialize();

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'admob_kit example',
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('admob_kit example')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Call once per meaningful user action; shows an
                      // interstitial automatically every Nth call.
                      AdManager.registerAction();
                    },
                    child: const Text('Do something (registers an action)'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await AdManager.showRewarded(
                        onReward: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reward granted!')),
                          );
                        },
                      );
                      debugPrint('Rewarded result: ${result.description}');
                    },
                    child: const Text('Watch rewarded ad'),
                  ),
                  const SizedBox(height: 12),
                  const AdNative(),
                ],
              ),
            ),
          ),
          // Full-width, height resolved by AdMob - do not wrap in a
          // fixed-height box.
          const AdaptiveBannerAd(),
        ],
      ),
    );
  }
}
