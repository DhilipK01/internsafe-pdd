import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/app.dart';
import 'package:internsfe/core/config/env_config.dart';
import 'package:internsfe/core/constants/brand_assets.dart';
import 'package:internsfe/core/theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  await Future.wait([
    AppTypography.preload(),
    rootBundle.load(BrandAssets.logo),
    rootBundle.load('assets/fonts/GrandHotel-Regular.ttf'),
  ]);
  // Lock to portrait on mobile only — web supports any viewport size.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  runApp(const ProviderScope(child: InternsafeApp()));
}

