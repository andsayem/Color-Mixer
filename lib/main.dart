import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../common/admob_helper.dart';
import 'pages/home_page.dart';
import 'pages/mixer_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  final adHelper = AdmobHelper();
  adHelper.loadAppOpenAd(
    onLoaded: () {
      Future.delayed(const Duration(seconds: 2), () {
        AdmobHelper.showAppOpenAd();
      });
    },
  );
  runApp(const PolikColorMixerApp());
}

class PolikColorMixerApp extends StatelessWidget {
  const PolikColorMixerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
