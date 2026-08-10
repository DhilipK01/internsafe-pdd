import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';

/// Legacy route — redirects to unified real result screen.
class OfferFakeResultScreen extends StatelessWidget {
  const OfferFakeResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.replace(AppRoutes.offerGenuine);
    });
    return const AppScaffold(
      title: 'Redirecting',
      showBackToHome: true,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
