import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:internsfe/application/providers/repository_providers.dart';
import 'package:internsfe/application/providers/scan_providers.dart';
import 'package:internsfe/core/constants/app_options.dart';
import 'package:internsfe/core/constants/app_spacing.dart';
import 'package:internsfe/core/extensions/context_extensions.dart';
import 'package:internsfe/core/routing/app_routes.dart';
import 'package:internsfe/core/widgets/app_scaffold.dart';
import 'package:internsfe/core/widgets/primary_button.dart';
import 'package:internsfe/core/widgets/section_title.dart';
import 'package:internsfe/data/api/api_exception.dart';

class DataSafetyAdvisorScreen extends ConsumerStatefulWidget {
  const DataSafetyAdvisorScreen({super.key});

  @override
  ConsumerState<DataSafetyAdvisorScreen> createState() =>
      _DataSafetyAdvisorScreenState();
}

class _DataSafetyAdvisorScreenState
    extends ConsumerState<DataSafetyAdvisorScreen> {
  final _selected = <String>{};
  String _stage = AppOptions.applicationStages.first;
  bool _loading = false;

  static const _dataOptions = [
    'Full Aadhaar Number',
    'PAN Card',
    'Bank Account Details',
    'Passport Copy',
    'College ID',
    'Resume / CV',
    'LinkedIn Profile',
    'Phone Number',
    'Email Address',
    'Home Address',
    'Parent Contact',
    'Processing Fee Payment',
    'Social Media Passwords',
    'Biometric Data',
  ];

  Future<void> _analyze() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one data item')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ref.read(dataSafetyRepositoryProvider).analyze(
            requestedData: _selected.toList(),
            stage: _stage,
          );
      ref.read(dataSafetyResultProvider.notifier).state = result;
      if (mounted) context.push(AppRoutes.dataSafetyResult);
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
      title: 'Data Safety Advisor',
      showBackToHome: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your selections are saved to the database. AI classification is not connected yet.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.mutedColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(title: 'Application stage'),
            DropdownButtonFormField<String>(
              initialValue: _stage,
              items: AppOptions.applicationStages
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _stage = v ?? _stage),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(
              title: 'What are they asking?',
              subtitle: 'Select all that apply',
            ),
            ..._dataOptions.map(
              (item) => CheckboxListTile(
                value: _selected.contains(item),
                title: Text(item),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selected.add(item);
                    } else {
                      _selected.remove(item);
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Save & Submit',
              isLoading: _loading,
              onPressed: _analyze,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
