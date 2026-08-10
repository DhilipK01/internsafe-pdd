import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internsfe/application/providers/theme_provider.dart';
import 'package:internsfe/core/constants/app_brand.dart';
import 'package:internsfe/core/routing/app_router.dart';
import 'package:internsfe/core/services/deep_link_service.dart';
import 'package:internsfe/core/theme/app_theme.dart';

class InternsafeApp extends ConsumerStatefulWidget {
  const InternsafeApp({super.key});

  @override
  ConsumerState<InternsafeApp> createState() => _InternsafeAppState();
}

class _InternsafeAppState extends ConsumerState<InternsafeApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      ref.read(deepLinkServiceProvider).bind(router);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppBrand.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final scaler = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.25,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
