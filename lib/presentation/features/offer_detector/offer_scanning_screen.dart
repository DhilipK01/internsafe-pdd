import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/data/api/api_exception.dart';
import 'package:mime/mime.dart';

class OfferScanningScreen extends ConsumerStatefulWidget {
  const OfferScanningScreen({super.key});

  @override
  ConsumerState<OfferScanningScreen> createState() =>
      _OfferScanningScreenState();
}

class _OfferScanningScreenState extends ConsumerState<OfferScanningScreen> {
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
  }

  Future<void> _submit() async {
    final text = ref.read(offerTextProvider);
    final selectedFile = ref.read(selectedOfferFileProvider);

    if (text.isEmpty && selectedFile == null) {
      setState(() {
        _error = 'No offer content provided.';
        _loading = false;
      });
      return;
    }

    try {
      String? fileId;
      String? fileBase64;
      if (selectedFile != null) {
        final mime =
            selectedFile.mimeType ??
            lookupMimeType(selectedFile.name, headerBytes: selectedFile.bytes) ??
            'application/pdf';
        final file = await ref.read(offerRepositoryProvider).uploadOfferDocument(
              fileBytes: selectedFile.bytes,
              fileName: selectedFile.name,
              mimeType: mime,
            );
        fileId = file?.id;
        fileBase64 = base64Encode(selectedFile.bytes);
      }
      final job = await ref.read(offerRepositoryProvider).submitOfferCheck(
            text: text.isNotEmpty ? text : null,
            fileId: fileId,
            fileBase64: fileBase64,
          );
      ref.read(offerCheckJobProvider.notifier).state = job;
      if (mounted) context.replace(AppRoutes.offerGenuine);
    } catch (e) {
      final msg = e is DioException && e.error is ApiException
          ? (e.error as ApiException).message
          : e.toString();
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Submitting Offer',
      showBackToHome: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(label: 'Go Back', onPressed: () => context.pop()),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_loading) const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Saving offer to database...'),
                  ],
                ),
        ),
      ),
    );
  }
}
