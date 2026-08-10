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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mime/mime.dart';

class ResumeScanningScreen extends ConsumerStatefulWidget {
  const ResumeScanningScreen({super.key});

  @override
  ConsumerState<ResumeScanningScreen> createState() =>
      _ResumeScanningScreenState();
}

class _ResumeScanningScreenState extends ConsumerState<ResumeScanningScreen> {
  bool _uploading = true;
  String? _error;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runUpload());
  }

  Future<void> _runUpload() async {
    final selectedFile = ref.read(selectedResumeFileProvider);
    if (selectedFile == null) {
      setState(() {
        _error = 'No file selected. Please go back and upload a resume.';
        _uploading = false;
      });
      return;
    }

    try {
      setState(() => _progress = 0.2);
      final mime =
          selectedFile.mimeType ??
          lookupMimeType(selectedFile.name, headerBytes: selectedFile.bytes) ??
          'application/octet-stream';
      final uploaded = await ref.read(resumeRepositoryProvider).uploadResumeFile(
            fileBytes: selectedFile.bytes,
            fileName: selectedFile.name,
            mimeType: mime,
          );
      setState(() => _progress = 0.6);
      final fileBase64 = base64Encode(selectedFile.bytes);
      final job = await ref.read(resumeRepositoryProvider).createResumeScan(
            fileId: uploaded.id,
            fileBase64: fileBase64,
          );
      ref.read(resumeScanJobProvider.notifier).state = job;
      setState(() {
        _progress = 1;
        _uploading = false;
      });
      if (mounted) context.replace(AppRoutes.resumeReport);
    } catch (e) {
      final msg = e is DioException && e.error is ApiException
          ? (e.error as ApiException).message
          : e.toString();
      setState(() {
        _error = msg;
        _uploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Uploading Resume',
      showBackToHome: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48),
                    const SizedBox(height: AppSpacing.lg),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Go Back',
                      onPressed: () => context.pop(),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      _uploading
                          ? 'Uploading to secure storage...'
                          : 'Starting AI analysis...',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LinearProgressIndicator(value: _progress),
                  ],
                ),
        ),
      ),
    );
  }
}
