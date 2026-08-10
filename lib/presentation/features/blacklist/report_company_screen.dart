import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/core/constants/app_brand.dart';
import 'package:internsfe/core/constants/app_options.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/danger_button.dart';
import 'package:internsfe/data/api/api_exception.dart';

class ReportCompanyScreen extends ConsumerStatefulWidget {
  const ReportCompanyScreen({super.key});

  @override
  ConsumerState<ReportCompanyScreen> createState() =>
      _ReportCompanyScreenState();
}

class _ReportCompanyScreenState extends ConsumerState<ReportCompanyScreen> {
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _collegeController = TextEditingController();
  String _fraudType = AppOptions.fraudTypes.first;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    ref.read(currentUserProvider.future).then((user) {
      if (user?.college != null && mounted) {
        _collegeController.text = user!.college!;
      }
    });
  }

  @override
  void dispose() {
    _companyController.dispose();
    _descriptionController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_companyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company name is required')),
      );
      return;
    }
    if (_descriptionController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Description must be at least 10 characters')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(blacklistRepositoryProvider).reportCompany(
            companyName: _companyController.text.trim(),
            fraudType: _fraudType,
            description: _descriptionController.text.trim(),
            college: _collegeController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted — visible to all users')),
        );
        context.pop();
      }
    } catch (e) {
      final msg = e is DioException && e.error is ApiException
          ? (e.error as ApiException).message
          : e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Report Company',
      showBackToHome: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reports are stored globally and appear for all ${AppBrand.name} users.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.mutedColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _companyController,
              decoration: const InputDecoration(labelText: 'Company Name *'),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<String>(
              initialValue: _fraudType,
              decoration: const InputDecoration(labelText: 'Fraud Type *'),
              items: AppOptions.fraudTypes
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _fraudType = v ?? _fraudType),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _collegeController,
              decoration: const InputDecoration(labelText: 'Your College'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'What happened? *',
                hintText: 'Minimum 10 characters',
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            DangerButton(
              label: 'Submit Report',
              isLoading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
