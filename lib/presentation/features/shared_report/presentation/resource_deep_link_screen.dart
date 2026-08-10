import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:internsfe/application/providers/repository_providers.dart';

import 'package:internsfe/core/brand/internsafe_logo.dart';

import 'package:internsfe/core/constants/app_spacing.dart';

import 'package:internsfe/core/extensions/context_extensions.dart';

import 'package:internsfe/core/routing/app_routes.dart';

import 'package:internsfe/core/widgets/primary_button.dart';




/// Opens when `internsafe://resume/{id}` (or offer/company) is used — owner content.

class ResourceDeepLinkScreen extends ConsumerStatefulWidget {

  const ResourceDeepLinkScreen({

    super.key,

    required this.resourceType,

    required this.resourceId,

  });



  final String resourceType;

  final String resourceId;



  @override

  ConsumerState<ResourceDeepLinkScreen> createState() =>

      _ResourceDeepLinkScreenState();

}



class _ResourceDeepLinkScreenState extends ConsumerState<ResourceDeepLinkScreen> {

  @override

  void initState() {

    super.initState();

    _maybeOpenReport();

  }



  Future<void> _maybeOpenReport() async {

    final loggedIn = await ref.read(authRepositoryProvider).isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {

      final kind = switch (widget.resourceType) {

        'resume' || 'scan' => 'scan',

        'offer' => 'offer_check',

        'company' => 'company',

        _ => 'analysis',

      };

      context.go('/library/$kind/${widget.resourceId}');

      return;

    }

    setState(() => _showLogin = true);

  }



  bool _showLogin = false;



  @override

  Widget build(BuildContext context) {

    if (!_showLogin) {

      return const Scaffold(

        body: Center(child: CircularProgressIndicator()),

      );

    }



    final label = widget.resourceType.replaceAll('_', ' ');

    return Scaffold(

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.all(AppSpacing.xl),

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              const InternsafeLogo(size: 56),

              const SizedBox(height: AppSpacing.xl),

              Text(

                'Open in INTERNSAFE',

                style: context.textTheme.headlineSmall,

                textAlign: TextAlign.center,

              ),

              const SizedBox(height: AppSpacing.md),

              Text(

                'Sign in to view your $label report and AI analysis.',

                textAlign: TextAlign.center,

                style: context.textTheme.bodyMedium?.copyWith(

                  color: context.mutedColor,

                ),

              ),

              const SizedBox(height: AppSpacing.xxl),

              PrimaryButton(

                label: 'Sign in',

                onPressed: () => context.go(AppRoutes.login),

              ),

            ],

          ),

        ),

      ),

    );

  }

}


