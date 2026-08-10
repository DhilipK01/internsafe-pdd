import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/services/scan_poll_service.dart';
import 'package:internsfe/core/widgets/analysis_pending_card.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/scan_results_panel.dart';
import 'package:internsfe/core/widgets/share_result_button.dart';
import 'package:internsfe/domain/entities/scan_analysis_result.dart';
import 'package:internsfe/domain/entities/scan_job.dart';
import 'package:internsfe/domain/repositories/share_repository.dart';

class ResumeReportScreen extends ConsumerStatefulWidget {
  const ResumeReportScreen({super.key});

  @override
  ConsumerState<ResumeReportScreen> createState() => _ResumeReportScreenState();
}

class _ResumeReportScreenState extends ConsumerState<ResumeReportScreen> {
  ScanJob? _job;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _job = ref.read(resumeScanJobProvider);
      if (_job != null &&
          (_job!.isProcessing || (_job!.isPending && !_job!.hasResults))) {
        _pollScan();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _pollScan() async {
    final initial = ref.read(resumeScanJobProvider);
    if (initial == null) return;
    setState(() => _polling = true);
    try {
      final updated = await pollUntilDone<ScanJob>(
        fetch: () => ref.read(resumeRepositoryProvider).getScan(initial.id),
        isDone: (j) => j.hasResults || j.isFailed,
        interval: const Duration(seconds: 3),
      );
      ref.read(resumeScanJobProvider.notifier).state = updated;
      if (mounted) setState(() => _job = updated);
    } finally {
      if (mounted) setState(() => _polling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job ?? ref.watch(resumeScanJobProvider);
    if (job == null) {
      return AppScaffold(
        showBackToHome: true,
        title: 'Report',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No scan data found.'),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Upload Resume',
                onPressed: () => context.go(AppRoutes.scan),
              ),
            ],
          ),
        ),
      );
    }

    final analysis = ScanAnalysisResult.fromResultJson(job.resultJson);

    return AppScaffold(
      title: 'Resume Analysis',
      showBackToHome: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_polling || job.isProcessing)
              const AnalysisPendingCard(
                message:
                    'AI is analyzing your resume (OCR + PII detection). This uses real models — please wait.',
              ),
            if (job.isFailed)
              AnalysisPendingCard(
                message: job.message.isNotEmpty
                    ? job.message
                    : 'Analysis failed. Try uploading a clearer file.',
              ),
            if (job.hasResults && analysis != null)
              ScanResultsPanel(result: analysis),
            if (job.hasResults && analysis == null)
              const AnalysisPendingCard(
                message: 'Analysis completed but results could not be parsed.',
              ),
            if (job.isPending && !job.isProcessing && analysis == null)
              AnalysisPendingCard(
                message: job.message.isNotEmpty
                    ? job.message
                    : 'Waiting for AI service. Your file was saved.',
              ),
            const SizedBox(height: AppSpacing.xl),
            Text('Scan ID: ${job.id}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            ShareResultButton(
              resourceType: ShareResourceType.scan,
              resourceId: job.id,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Back to Scanner',
              onPressed: () => context.go(AppRoutes.scan),
            ),
          ],
        ),
      ),
    );
  }
}
